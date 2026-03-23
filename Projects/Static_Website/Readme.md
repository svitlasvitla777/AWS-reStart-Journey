# The Train Café — Static Website on AWS

A restaurant website for The Train Café, Zurich. Built as part of the AWS re/Start program.  
The café concept is inspired by vintage railway stations — every dish is named after a destination city.

Live at: `http://the-train-cafe-website.s3-website-us-east-1.amazonaws.com`

---

## About the Project

This is a group project. We built a static website for a fictional café and deployed it to AWS using S3 static website hosting. The site has a menu, a table reservation form, an online order page, and a custom 404 error page.

The plan was to also set up CloudFront for HTTPS, Cognito for user login, and Lambda + DynamoDB to store bookings and orders. Parts of this were blocked by sandbox permission restrictions — I have documented everything below.

---

## What I Built

Claire designed the initial concept and created the base styles. I took that and built out the full website.

Pages I built:
- `booking.html` — table reservation form with validation and API connection
- `order.html` — online order page with a live cart that updates as you add items
- `error.html` — custom 404 page with animated sliding railway tracks

I also extended the homepage with the customer reviews section, the map section, and the footer with contact details.

All the JavaScript is mine — the booking form, the order cart, the Sign In modal with Sign In and Create Account tabs.

I used Claude AI (by Anthropic) to help write and debug the code faster. The design decisions, content, and concept were all from the team.

---

## File Structure

```
Static_Website/
├── index.html          # Homepage — hero banner, menu, about us, reviews, map, footer
├── booking.html        # Table reservation form
├── order.html          # Online order form with live cart
├── error.html          # Custom 404 page
├── index.css           # Shared stylesheet for all pages
├── README.md           # This file
├── screenshots/        # AWS deployment screenshots (14 total)
└── images/
    ├── Banner.jpg
    ├── Logo.jpg
    ├── hero-train.jpg
    ├── Map.png
    ├── Croissant.jpg
    ├── Ramen.jpg
    ├── Meze.jpg
    ├── Flan.jpg
    ├── Vienna Cake.jpg
    ├── Espresso.jpg
    ├── Matcha.jpg
    ├── socials.png
    └── tripadvisor.png
```

---

## AWS Setup

| Service | Name | Region | Status |
|---|---|---|---|
| S3 Bucket | the-train-cafe-website | us-east-1 | Live |
| CloudFront | the-train-cafe-cdn | Global | Blocked |
| Cognito User Pool | the-train-cafe-users | us-east-1 | Blocked |
| Cognito App Client | the-train-cafe-app | us-east-1 | Blocked |
| DynamoDB | TrainCafe-Bookings | us-east-1 | Active |
| DynamoDB | TrainCafe-Orders | us-east-1 | Active |
| Lambda | TrainCafe-SaveBooking | us-east-1 | Blocked |
| Lambda | TrainCafe-SaveOrder | us-east-1 | Blocked |
| API Gateway | the-train-cafe-api | us-east-1 | Blocked |
| IAM Role | the-train-cafe-lambda-role | Global | Blocked |

---

## Phase 1 — S3 Static Hosting (done)

I created the S3 bucket, turned off Block Public Access, enabled static website hosting, and added a bucket policy to allow public reads. Then uploaded all the website files.

- Bucket name: `the-train-cafe-website`
- Region: us-east-1
- Index document: index.html
- Error document: error.html
- Bucket policy: PublicReadGetObject on all files
- Upload: 19 files, 7.4 MB, 100% succeeded — March 21, 2026

| Screenshot | What it shows |
|---|---|
| [01_s3_create_bucket.png](screenshots/01_s3_create_bucket.png) | Create bucket form with name and region |
| [02_s3_public_access_off_warning.png](screenshots/02_s3_public_access_off_warning.png) | Block Public Access turned off |
| [03_s3_bucket_created.png](screenshots/03_s3_bucket_created.png) | Bucket created successfully |
| [04_s3_static_hosting_maintenance.png](screenshots/04_s3_static_hosting_maintenance.png) | Static hosting settings — index and error documents |
| [05_s3_static_hosting_enabled.png](screenshots/05_s3_static_hosting_enabled.png) | Hosting enabled with endpoint URL |
| [06_s3_bucket_policy.png](screenshots/06_s3_bucket_policy.png) | Bucket policy saved |
| [07_s3_files_uploaded.png](screenshots/07_s3_files_uploaded.png) | All 19 files uploaded successfully |
| [08_s3_website_live.png](screenshots/08_s3_website_live.png) | Website open in browser at S3 URL |

---

## Phase 2 — CloudFront + Cognito (blocked)

Cognito needs an HTTPS callback URL. S3 only gives you HTTP, so you need CloudFront first to get HTTPS. I tried three things and all of them were blocked by the Canvas Sandbox.

**CloudFront:** When I tried to create a distribution, it failed with `wafv2:CreateWebACL not authorized`. The new CloudFront wizard automatically attaches a WAF rule and there is no way to skip it.

**Cognito with S3 URL:** I tried using the S3 HTTP URL directly as the Cognito callback. Cognito rejected it — it requires HTTPS.

**AWS Amplify:** I tried Amplify as an alternative way to get HTTPS hosting. Also blocked — `amplify:CreateApp not authorized`.

| Screenshot | What it shows |
|---|---|
| [09_error_cloudfront_waf_blocked.png](screenshots/09_error_cloudfront_waf_blocked.png) | CloudFront blocked by wafv2 permission |
| [10_error_cognito_https_required.png](screenshots/10_error_cognito_https_required.png) | Cognito rejecting the S3 HTTP URL |
| [11_error_amplify_CreateApp_blocked.png](screenshots/11_error_amplify_CreateApp_blocked.png) | Amplify blocked by permission |

---

## Phase 3 — DynamoDB + Lambda + API Gateway (partial)

I created both DynamoDB tables successfully. The Lambda step was blocked because creating an IAM role is not permitted in this sandbox.

Done:
- `TrainCafe-Bookings` — partition key: bookingId (String) — Active
- `TrainCafe-Orders` — partition key: orderId (String) — Active

Blocked:
- IAM role `the-train-cafe-lambda-role` — `iam:CreateRole` not permitted
- Lambda functions cannot be created without the IAM role
- API Gateway cannot be set up without Lambda

The Lambda code is written and ready. As soon as the IAM role is available it can be deployed in a few minutes.

| Screenshot | What it shows |
|---|---|
| [12_dynamodb_bookings_table.png](screenshots/12_dynamodb_bookings_table.png) | TrainCafe-Bookings table active |
| [13_dynamodb_orders_table.png](screenshots/13_dynamodb_orders_table.png) | Both tables active |
| [14_error_iam_CreateRole_blocked.png](screenshots/14_error_iam_CreateRole_blocked.png) | IAM role creation blocked |

---

## Phase 4 — Connect Forms to Database (blocked)

This phase needs Lambda and API Gateway from Phase 3, so it is blocked for the same reason. The booking and order forms already have the JavaScript to send POST requests — they just need the API Gateway URL to be filled in once it is available.

---

## Team

| Name | Role | Work |
|---|---|---|
| Veronika | Concept & PM | Café idea, About Us text, project plan, presentation |
| Laura | Content | Menu copy, image selection, storytelling |
| Claire | Design | Color palette, fonts, initial index.html and index.css |
| Svitlana | AWS & Frontend | booking.html, order.html, error.html, JavaScript, S3 deployment, DynamoDB, README |

---

## Notes

The Canvas Sandbox blocks several AWS actions that are needed for a full deployment: `wafv2:CreateWebACL`, `amplify:CreateApp`, and `iam:CreateRole`. These are not mistakes in the setup — they are account-level restrictions. I reported this to the instructor and documented every attempt with screenshots.

In a normal AWS account all phases would work without any issues.
