# Lab 185: Working with Amazon S3

## About This Lab

This lab covers a practical file-sharing workflow built on Amazon S3, AWS IAM, and Amazon SNS. The scenario is straightforward: a cafe business needs to give an external media company controlled access to upload and manage product images in an S3 bucket, while an administrator receives an email notification every time the bucket content changes. I set the whole thing up from scratch using the AWS CLI on an EC2 instance.

The AWS services involved are Amazon S3 for object storage, IAM for access control, and SNS for event-driven email notifications. S3 is the backbone of object storage in AWS — it is durable, scalable, and integrates with almost every other AWS service. Understanding how to lock it down properly, scope permissions to specific key prefixes, and connect it to a notification system are skills that come up constantly in real cloud infrastructure work.

IAM is where most real-world cloud security mistakes happen, so this lab was valuable for seeing exactly how a restrictive policy is structured — scoping access to a specific path pattern (`cafe-*/images/*`) rather than the whole bucket, and understanding what the practical difference between `GetObject`, `PutObject`, and `DeleteObject` looks like when tested against a live user. I also saw how group-based permission inheritance works: `mediacouser` inherits everything from the `mediaco` group without needing policies attached directly to the user account.

The SNS notification piece demonstrates event-driven architecture at a simple but concrete level. Rather than polling for changes, the bucket publishes a message to a topic the moment an object is created or deleted — and a subscribed email address receives the notification within seconds. The prefix filter on `images/` means the notification only fires for relevant events, not every operation on the bucket.

---

## What I Did

The lab environment came with a pre-configured EC2 instance called CLI Host (`i-0ed64b44ce45bc8bf`), already running in `us-west-2`. I connected to it using EC2 Instance Connect directly from the browser — no SSH key management required. The instance had sample images pre-loaded at `~/initial-images/` and a second set at `~/new-images/` for the notification tests. The IAM user `mediacouser` and the `mediaco` group were pre-created with a policy already attached. I reviewed the policy, generated CLI credentials for `mediacouser`, and ran through the full workflow. All CLI work happened inside that EC2 session.

---

## Task 1: Connecting to the CLI Host EC2 Instance and Configuring the AWS CLI

### Task 1.1: Connecting to the CLI Host EC2 Instance

I opened the EC2 console, selected the CLI Host instance, and connected using EC2 Instance Connect. The terminal opened directly in the browser — no key pair or local SSH client needed. The instance is running Amazon Linux 2 (`i-0ed64b44ce45bc8bf`).

![CLI Host connected via EC2 Instance Connect showing Amazon Linux 2 prompt](screenshots/01_cli_host_connect.png)

### Task 1.2: Configuring the AWS CLI on the CLI Host Instance

I configured the CLI profile using the temporary credentials from the lab Credentials panel:

```bash
aws configure
```

Inputs:
- AWS Access Key ID: `[AccessKey from Credentials panel]`
- AWS Secret Access Key: `[SecretKey from Credentials panel]`
- Default region name: `us-west-2`
- Default output format: `json`

---

## Task 2: Creating and Initializing the S3 Share Bucket

I created the S3 bucket:

```bash
aws s3 mb s3://cafe-aws777 --region 'us-west-2'
```

The terminal confirmed: `make_bucket: cafe-aws777`

![Terminal showing make_bucket: cafe-aws777 confirmation](screenshots/02_bucket_created.png)

Then I synced the initial product images into the `images/` prefix. Three files were uploaded: `Cup-of-Hot-Chocolate.jpg`, `Strawberry-Tarts.jpg`, and `Donuts.jpg`.

```bash
aws s3 sync ~/initial-images/ s3://cafe-aws777/images
```

![Terminal output listing all three files uploaded by sync](screenshots/03_images_synced.png)

Verified the upload:

```bash
aws s3 ls s3://cafe-aws777/images/ --human-readable --summarize
```

Output showed 3 objects totalling 1.1 MiB: `Cup-of-Hot-Chocolate.jpg` (308.7 KiB), `Donuts.jpg` (371.8 KiB), and `Strawberry-Tarts.jpg` (468.0 KiB).

![S3 ls output showing 3 objects with sizes and 1.1 MiB total](screenshots/04_bucket_ls.png)

---

## Task 3: Reviewing the IAM Group and User Permissions

### Task 3.1: Reviewing the mediaco IAM Group

I opened the IAM console and reviewed the `mediaCoPolicy` attached to the `mediaco` group. The policy has three statements:

- `AllowGroupToSeeBucketListInTheConsole` — grants `s3:ListAllMyBuckets` and `s3:GetBucketLocation` on all S3 resources, so the user can see the bucket list in the console.
- `AllowRootLevelListingOfTheBucket` — grants `s3:ListBucket` scoped to `arn:aws:s3:::cafe-*`, allowing the user to list objects inside any cafe bucket.
- `AllowUserSpecificActionsOnlyInTheSpecificPrefix` — grants `s3:PutObject`, `s3:GetObject`, `s3:GetObjectVersion`, `s3:DeleteObject`, and `s3:DeleteObjectVersion` scoped to `arn:aws:s3:::cafe-*/images/*`. This is the core permission — read, write, and delete, but only inside the `images/` prefix.

![mediaCoPolicy part 1 showing AllowGroupToSeeBucketListInTheConsole and AllowRootLevelListingOfTheBucket](screenshots/05_1_mediaco_policy.png)

![mediaCoPolicy part 2 showing AllowUserSpecificActionsOnlyInTheSpecificPrefix with actions and resource](screenshots/05_2_mediaco_policy.png)

### Task 3.2: Reviewing the mediacouser IAM User

I confirmed that `mediacouser` inherits both policies through its `mediaco` group membership. I then generated a new access key (`AKIA6OYXK6G5CMN6T3KU`) for CLI use in Task 5 and downloaded the `.csv` file.

![IAM Security credentials tab for mediacouser showing active access key AKIA6OYXK6G5CMN6T3KU](screenshots/06_access_key_created.png)

### Task 3.3: Testing the mediacouser Permissions

I opened a private browser window, signed in using the mediacouser console sign-in link (`https://993797009850.signin.aws.amazon.com/console`), and ran through four tests:

**View:** Opened `Donuts.jpg` from the `images/` folder — loaded correctly from `cafe-aws777.s3.us-west-2.amazonaws.com`.

![Donuts.jpg open in browser tab served from cafe-aws777 S3 bucket](screenshots/07_view_donut.png)

**Upload:** Uploaded a local image file to `s3://cafe-aws777/images/` — succeeded with a green "Upload succeeded" banner, 1 file at 373.4 KB.

![S3 Upload succeeded page showing 1 file 373.4 KB uploaded to cafe-aws777/images/](screenshots/08_upload_success.png)

**Delete:** Deleted `Cup-of-Hot-Chocolate.jpg` (308.7 KB) from `s3://cafe-aws777/images/` — succeeded with "Successfully deleted objects" and 0 failed.

![S3 Delete objects status showing 1 object 308.7 KB successfully deleted from cafe-aws777/images/](screenshots/09_delete_success.png)

**Unauthorized — change bucket permissions:** Navigated to the Permissions tab on the bucket. Got the expected "Access denied" error: `User: arn:aws:iam::993797009850:user/mediacouser is not authorized to perform: s3:GetBucketPublicAccessBlock`. `mediacouser` cannot view or modify bucket-level settings — only objects inside `images/`.

![S3 Permissions tab showing Access denied for mediacouser with full API error message](screenshots/10_permissions_denied.png)

---

## Task 4: Configuring Event Notifications on the S3 Share Bucket

### Task 4.1: Creating and Configuring the s3NotificationTopic SNS Topic

I created a Standard SNS topic named `s3NotificationTopic`. The ARN `arn:aws:sns:us-west-2:993797009850:s3NotificationTopic` was displayed in the Details section and I copied it immediately using the copy icon.

![SNS console showing s3NotificationTopic created successfully with ARN copied](screenshots/11_sns_topic_created.png)

I then edited the topic's access policy to grant S3 permission to publish to it. The `Resource` field uses the topic ARN and the `ArnLike` condition locks it to `cafe-aws777` specifically:

```json
{
  "Version": "2008-10-17",
  "Id": "S3PublishPolicy",
  "Statement": [
    {
      "Sid": "AllowPublishFromS3",
      "Effect": "Allow",
      "Principal": { "Service": "s3.amazonaws.com" },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:us-west-2:993797009850:s3NotificationTopic",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:*:*:cafe-aws777"
        }
      }
    }
  ]
}
```

![SNS access policy editor showing S3PublishPolicy with correct Resource ARN and cafe-aws777 condition](screenshots/12_sns_policy_saved.png)

I subscribed `svitlasvitla@gmail.com` to the topic using the Email protocol. The subscription was created with status "Pending confirmation".

![SNS subscription created for svitlasvitla@gmail.com showing Pending confirmation status](screenshots/13_1_subscription_created.png)

After clicking the confirmation link in the email, the SNS page confirmed the subscription was active.

![Browser showing Subscription confirmed page on sns.us-west-2.amazonaws.com](screenshots/13_2_subscription_confirmed.png)

The SNS Subscriptions tab showed the endpoint as Confirmed with EMAIL protocol.

![SNS Subscriptions list showing svitlasvitla@gmail.com as Confirmed for s3NotificationTopic](screenshots/13_3_subscription_aws_confirmed.png)

### Task 4.2: Adding an Event Notification Configuration to the S3 Bucket

In the CLI Host terminal I created the notification config file:

```bash
vi s3EventNotification.json
```

Contents:

```json
{
  "TopicConfigurations": [
    {
      "TopicArn": "arn:aws:sns:us-west-2:993797009850:s3NotificationTopic",
      "Events": ["s3:ObjectCreated:*","s3:ObjectRemoved:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "images/"
            }
          ]
        }
      }
    }
  ]
}
```

Applied the config to the bucket:

```bash
aws s3api put-bucket-notification-configuration --bucket cafe-aws777 --notification-configuration file://s3EventNotification.json
```

No output on success. Within a minute I received a test email from S3 with `"Event":"s3:TestEvent","Bucket":"cafe-aws777"` confirming the full pipeline was working.

![Email showing Amazon S3 Notification with s3:TestEvent and Bucket cafe-aws777 in the body](screenshots/14_test_event_email.png)

---

## Task 5: Testing the S3 Share Bucket Event Notifications

I reconfigured the CLI to use `mediacouser` credentials (`AKIA6OYXK6G5CMN6T3KU`):

```bash
aws configure
```

**Put object:**

```bash
aws s3api put-object --bucket cafe-aws777 --key images/Caramel-Delight.jpg --body ~/new-images/Caramel-Delight.jpg
```

The command returned an ETag (`31ac30da619244b0ce786f106e4f3df7`) and confirmed `ServerSideEncryption: AES256` — the bucket encrypts objects at rest by default.

![Terminal showing ETag and ServerSideEncryption AES256 returned after put-object for Caramel-Delight.jpg](screenshots/15_put_object_etag.png)

An email arrived at `svitlasvitla@gmail.com` with `"eventName":"ObjectCreated:Put"` and `"object":{"key":"images/Caramel-Delight.jpg"}`.

![Email showing ObjectCreated:Put notification with Caramel-Delight.jpg key and cafe-aws777 bucket](screenshots/16_put_notification_email.png)

**Get object** (no notification expected):

```bash
aws s3api get-object --bucket cafe-aws777 --key images/Donuts.jpg Donuts.jpg
```

The command returned object metadata: `ContentType: image/jpeg`, `ContentLength: 380753`, `LastModified: Wed, 25 Mar 2026 16:00:50 GMT`, `ServerSideEncryption: AES256`. No email was sent — read operations are not in the notification event filter.

![Terminal output of get-object for Donuts.jpg showing metadata including ContentLength 380753](screenshots/17_get_object_output.png)

**Delete object:**

```bash
aws s3api delete-object --bucket cafe-aws777 --key images/Strawberry-Tarts.jpg
```

An email arrived with `"eventName":"ObjectRemoved:Delete"` and `"object":{"key":"images/Strawberry-Tarts.jpg"}`.

![Email showing ObjectRemoved:Delete notification with Strawberry-Tarts.jpg key and cafe-aws777 bucket](screenshots/18_delete_notification_email.png)

**Unauthorized — change object ACL:**

```bash
aws s3api put-object-acl --bucket cafe-aws777 --key images/Donuts.jpg --acl public-read
```

Got `AccessDenied` with the full reason: `User: arn:aws:iam::993797009850:user/mediacouser is not authorized to perform: s3:PutObjectAcl on resource: "arn:aws:s3:::cafe-aws777/images/Donuts.jpg" because public ACLs are prevented by the BlockPublicAcls setting in S3 Block Public Access.` The operation is blocked by two independent controls — the IAM policy does not include `PutObjectAcl`, and even if it did, S3 Block Public Access would reject the public-read ACL at the bucket level.

![Terminal showing full AccessDenied error message citing both IAM policy and BlockPublicAcls setting](screenshots/19_acl_access_denied.png)

---

## Challenges I Had

**SNS topic ARN confusion — subscription ARN vs topic ARN.** After subscribing my email, the console showed the subscription ARN (`arn:aws:sns:us-west-2:993797009850:s3NotificationTopic:ac443685-fd44-4d6e-bd96-a42d2a2022f0`). I initially copied this instead of the topic ARN. The subscription ARN has a UUID appended after the topic name. Pasting it into `s3EventNotification.json` caused repeated `InvalidArgument: Unable to validate the following destination configurations` errors from `put-bucket-notification-configuration`. The correct topic ARN to use is `arn:aws:sns:us-west-2:993797009850:s3NotificationTopic` — no UUID suffix.

**SNS access policy Resource field not updated.** Even after fixing the JSON file, the command kept failing with the same error. The SNS topic access policy still had a placeholder in the `Resource` field, so S3 had no valid permission to publish to the topic. Once I replaced the `Resource` field with the correct topic ARN and saved, the command succeeded immediately.

**Extra closing braces in s3EventNotification.json.** When I edited the file in vi, the pasted JSON ended up with two extra `}` characters at the bottom, making the structure invalid. I fixed this by reopening the file and deleting the extra lines with `dd` before rerunning the command.

**Command truncated on paste.** One attempt to run `put-bucket-notification-configuration` failed with `aws: error: argument --notification-configuration is required` because the long command was cut off when pasted. Fixed by typing the full command manually as a single line.

---

## What I Learned

**S3 event notifications require permissions on both sides.** It is not enough to configure the notification in S3 — the SNS topic also needs an explicit resource-based policy granting `sns:Publish` to the `s3.amazonaws.com` service principal. Without that policy, S3 cannot deliver notifications and `put-bucket-notification-configuration` fails with `InvalidArgument`. The `ArnLike` condition in the policy scopes the permission to the specific source bucket, which prevents other buckets from publishing to the same topic.

**IAM policy restrictions and S3 Block Public Access are independent layers of defence.** When `mediacouser` tried to run `put-object-acl --acl public-read`, the error cited two separate reasons: the IAM policy does not include `s3:PutObjectAcl`, and even if it did, the bucket's Block Public Access setting (`BlockPublicAcls`) would reject the request anyway. This is defence-in-depth — removing one control would not be enough to make the operation succeed.

**The subscription ARN and topic ARN are different things.** The topic ARN identifies the SNS topic itself. The subscription ARN identifies one specific subscriber to that topic and has a UUID appended. Policies and notification configs must reference the topic ARN, not the subscription ARN — using the wrong one causes silent validation failures.

**S3 event notifications filter by event type and key prefix independently.** The `Events` array and the `Filter` key rules are separate concerns. A `get-object` call generates no notification not because of the prefix filter, but because `GetObject` is not an `ObjectCreated` or `ObjectRemoved` event — it is simply not in the events list. The notification correctly fired for the put and delete operations but stayed silent for the get.

**The `aws s3api` and `aws s3` subcommands operate at different levels of abstraction.** The `s3` subcommand handles multipart uploads, recursive operations, and progress reporting automatically. The `s3api` subcommand maps directly to individual S3 API calls. In this lab I used both: `s3` for bulk operations during setup and `s3api` for the precise per-object tests in Task 5 where I needed specific keys and wanted to see raw API responses including ETags and server-side encryption metadata.

---

## Resource Names Reference

| Resource | Value | Notes |
|---|---|---|
| S3 Share Bucket | `cafe-aws777` | Created in Task 2 |
| AWS Region | `us-west-2` | Oregon |
| CLI Host Instance ID | `i-0ed64b44ce45bc8bf` | Connected via EC2 Instance Connect |
| IAM User (external) | `mediacouser` | Represents media company |
| IAM Group | `mediaco` | Group with scoped S3 permissions |
| IAM Policy | `mediaCoPolicy` | Grants access to `cafe-*/images/*` only |
| mediacouser Password | `Training1!` | Console sign-in |
| mediacouser Access Key ID | `AKIA6OYXK6G5CMN6T3KU` | Generated in Task 3.2 |
| SNS Topic Name | `s3NotificationTopic` | Created in Task 4.1 |
| SNS Topic ARN | `arn:aws:sns:us-west-2:993797009850:s3NotificationTopic` | Used in policy and notification config |
| SNS Subscription Email | `svitlasvitla@gmail.com` | Confirmed subscriber |
| AWS Account ID | `993797009850` | Visible in ARNs throughout |
| Event Config File | `s3EventNotification.json` | Created on CLI Host in Task 4.2 |
| Initial Images | `Cup-of-Hot-Chocolate.jpg`, `Donuts.jpg`, `Strawberry-Tarts.jpg` | Pre-loaded at `~/initial-images/` |
| New Images Path | `~/new-images/` | Contains `Caramel-Delight.jpg` for Task 5 |

---

## Commands Reference

See [commands.sh](commands.sh) for all commands used in this lab in order.
