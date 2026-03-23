#  AWS Lab 178 — Working with Amazon EBS

## Overview

This repository documents my hands-on experience with **Amazon Elastic Block Store (EBS)** as part of my AWS cloud learning journey. In this lab, I practiced creating, attaching, configuring, and backing up EBS volumes — core skills for any AWS cloud practitioner working with EC2 infrastructure.

---

## What I Was Learning

Before starting this lab, I had a theoretical understanding of block storage, but I had never actually created and managed EBS volumes hands-on. This lab was designed to teach me:

- What Amazon EBS is and how it fits into AWS infrastructure
- How block storage differs from object storage (like S3)
- How to create and attach additional storage to a running EC2 instance
- How Linux file systems are created and mounted
- The importance of persistent mount configuration via `/etc/fstab`
- How EBS snapshots work as point-in-time backups
- How to restore data from a snapshot to a new volume

---

## What I Did — Step by Step

### Task 1: Created a New EBS Volume
I navigated to the EC2 console and first checked the **Availability Zone** of the existing Lab EC2 instance. This was critical — EBS volumes can only be attached to instances in the **same Availability Zone**. I then created a new **1 GiB General Purpose SSD (gp2)** volume in the correct AZ and tagged it as `My Volume`.

### Task 2: Attached the Volume to the EC2 Instance
Using the EC2 console, I attached `My Volume` to the Lab instance with the device name `/dev/sdb`. The volume status changed from `Available` to `In-use` after attaching.

### Task 3: Connected to the EC2 Instance
I used **EC2 Instance Connect** to open a browser-based SSH terminal to the running Lab EC2 instance — no SSH key management required.

### Task 4: Created and Configured the File System
From the terminal, I:
1. Ran `df -h` to confirm the new volume was attached but not yet formatted
2. Created an **ext3 file system** on `/dev/sdb` using `mkfs`
3. Created the mount point directory `/mnt/data-store`
4. Mounted the volume and added a persistent entry to `/etc/fstab` (captured in two screenshots)
5. Verified the mount with `df -h` — the 1 GiB volume appeared at `/mnt/data-store`
6. Wrote a test file to the volume: `some text has been written` and verified it with `cat`

### Task 5: Created an EBS Snapshot
From the EC2 console, I created a snapshot of `My Volume` tagged as `My Snapshot`. I waited until the snapshot status changed to **Completed** before proceeding — an important lesson learned during this lab (see Challenges below).

### Task 6: Restored from the Snapshot
1. Deleted the test file from the original volume to simulate accidental data loss
2. Created a new volume (`Restored Volume`) from the completed snapshot
3. Verified the restored volume showed **Available** status in the console
4. Attached it to the Lab instance and confirmed **In-use** status
5. Mounted it and confirmed that `file.txt` was **successfully recovered** ✅

---

## Screenshots

All screenshots are organized in the `/screenshots` folder of this repository.

| # | Filename | Description |
|---|----------|-------------|
| 01 | `01_lab_instance_availability_zone.png` | Lab instance list with Availability Zone column visible |
| 02 | `02_existing_ebs_volumes.png` | EBS Volumes list showing the existing 8 GiB root volume |
| 03 | `03_create_volume_settings.png` | Create volume form with gp2, 1 GiB, correct AZ and Name tag |
| 04 | `04_volume_created_available.png` | My Volume showing Available status |
| 05 | `05_attach_volume_dialog.png` | Attach volume dialog with Lab instance and /dev/sdb selected |
| 06 | `06_volume_in_use.png` | My Volume status changed to In-use |
| 07 | `07_terminal_connected.png` | EC2 Instance Connect terminal — successfully connected |
| 08 | `08_df_before_mount.png` | `df -h` output before mounting (no 1 GiB volume yet) |
| 09 | `09_mkfs_output.png` | Terminal output of mkfs formatting /dev/sdb as ext3 |
| 10 | `10_1_mount_and_fstab.png` | Mount command executed (part 1) |
| 11 | `10_2_mount_and_fstab.png` | fstab persistent entry added (part 2) |
| 12 | `11_df_after_mount.png` | `df -h` showing 1 GiB volume mounted at /mnt/data-store |
| 13 | `12_file_written_verified.png` | file.txt written and confirmed with `cat` |
| 14 | `13_create_snapshot_form.png` | Create snapshot form with Name tag filled in |
| 15 | `14_snapshot_created.png` | Snapshot showing Pending/Creating status |
| 16 | `15_snapshot_completed.png` | My Snapshot showing Completed status |
| 17 | `16_file_deleted_verified.png` | Terminal confirming file.txt deleted |
| 18 | `17_restored_volume_available.png` | Restored Volume showing Available status |
| 19 | `18_restored_volume_in_use.png` | Restored Volume showing In-use after attaching |
| 20 | `19_file_restored_verified.png` | Terminal: file.txt successfully recovered on restored volume ✅ |

---

## Results

| Goal | Result |
|------|--------|
| Create a 1 GiB EBS volume | ✅ Successfully created in correct Availability Zone |
| Attach volume to EC2 instance | ✅ Attached on /dev/sdb, status In-use confirmed |
| Format and mount file system | ✅ ext3 fs created and mounted at /mnt/data-store |
| Persist mount across reboots | ✅ Entry added to /etc/fstab |
| Write data to volume | ✅ file.txt created and verified with cat |
| Create EBS snapshot | ✅ Snapshot completed successfully |
| Restore from snapshot | ✅ file.txt recovered on restored volume |

---

## Challenges I Faced

### 1. Snapshot Timing — The Most Important Lesson of This Lab
This was the biggest challenge I encountered. The first time I attempted Task 6, the restored volume only contained `lost+found` — meaning `file.txt` was not recovered at all. After investigating with `ls -la /mnt/data-store2/`, I confirmed the volume was completely empty. The reason: the snapshot was either taken before writing the file, or the file was deleted before the snapshot reached **Completed** status.

I had to repeat the snapshot and restore cycle multiple times to get it right. The correct order of operations must be followed strictly:

1. Write the file 
2. Create snapshot → wait for **Completed** 
3. Create new volume from snapshot 
4. Attach and mount the new volume 
5. Only then delete the file from the original 
6. Verify recovery 

### 2. Device Naming — NVMe vs. /dev/sdb
When I attached a volume as `/dev/sdb` in the AWS Console, it appeared in Linux as `/dev/nvme1n1`. Modern EC2 instances use NVMe-based EBS and automatically remap device names. By the end of the lab I had four 1 GiB volumes attached simultaneously: `nvme1n1`, `nvme3n1`, `nvme4n1`, and `nvme5n1`. Running `lsblk` was essential to track the real device names.

### 3. Mount Directory Already Exists
During repeated restore attempts I encountered `mkdir: cannot create directory '/mnt/data-store2': File exists` because the directory was already created from a previous attempt. I learned to always check current mounts with `lsblk` before creating new mount point directories.

### 4. Availability Zone Awareness
EBS volumes are scoped to a specific Availability Zone. I had to verify the Lab instance AZ before creating the volume. A volume in a different AZ simply cannot be attached — it must be migrated via snapshot first.

---

## What I Learned

### 1. Snapshot Order of Operations Is Critical
The most practical lesson of this lab: snapshots are a point-in-time capture. Writing data first, confirming the snapshot reaches **Completed**, and only then testing deletion is the correct discipline. Skipping or reordering these steps results in empty restores with no data.

### 2. EBS Is Zone-Specific, Snapshots Are Region-Wide
EBS volumes are locked to one Availability Zone. Snapshots, stored in S3, can generate new volumes in **any AZ within the same region** — making snapshots the mechanism for cross-AZ data migration.

### 3. `/etc/fstab` Makes Mounts Persistent
Without a `fstab` entry, a mounted EBS volume becomes unmounted after every instance reboot. The entry `defaults,noatime 1 2` ensures automatic remounting on startup and disables access-time writes for better performance.

### 4. `lsblk` Is Essential for Multi-Volume Environments
When working with multiple attached volumes, `lsblk` shows all block devices, their sizes, and current mount points in a clean tree view. It was the most useful diagnostic command throughout this lab.

### 5. EBS Volumes Persist Beyond Instance Lifecycle
Unlike Instance Store (ephemeral), EBS volumes exist independently of the EC2 instance. They can be detached and reattached to different instances, making them the right choice for any data that needs to survive instance stops or terminations.

### 6. Snapshots Are Incremental and Space-Efficient
Only used blocks are copied to a snapshot — an empty 1 GiB volume produces a very small snapshot. Each subsequent snapshot only stores the delta (changes) from the previous one, making them cost-efficient for regular backups.

---

## 🏗️Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│           Availability Zone: us-west-2a          │
│                                                 │
│  ┌──────────────────┐                           │
│  │   EC2 Instance   │                           │
│  │     (Lab)        │                           │
│  │                  │                           │
│  │  nvme0n1p1  ─────┼──── Root Volume  (8 GiB)  │
│  │  nvme1n1    ─────┼──── My Volume    (1 GiB)  │
│  │  nvme5n1    ─────┼──── Restored Vol (1 GiB)  │
│  └──────────────────┘                           │
│                                                 │
└─────────────────────────────────────────────────┘

    My Volume ──── snapshot ────► My Snapshot (S3)
                                        │
                                        └──► Restored Volume
                                             (file.txt recovered ✅)
```

---

## 🔗 AWS Documentation References

- [Amazon EBS Overview](https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html)
- [EBS Volume Types](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html)
- [Amazon EBS Snapshots](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-snapshots.html)
- [Making an EBS Volume Available for Use on Linux](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-using-volumes.html)
- [Connect to Your Linux Instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-linux-inst-ssh.html)

---

## 📁 Repository Structure

```
aws-lab-178-ebs/
├── README.md
├── Lab178_EBS_StepByStep_Guide.docx
└── screenshots/
    ├── 01_lab_instance_availability_zone.png
    ├── 02_existing_ebs_volumes.png
    ├── 03_create_volume_settings.png
    ├── 04_volume_created_available.png
    ├── 05_attach_volume_dialog.png
    ├── 06_volume_in_use.png
    ├── 07_terminal_connected.png
    ├── 08_df_before_mount.png
    ├── 09_mkfs_output.png
    ├── 10_1_mount_and_fstab.png
    ├── 10_2_mount_and_fstab.png
    ├── 11_df_after_mount.png
    ├── 12_file_written_verified.png
    ├── 13_create_snapshot_form.png
    ├── 14_snapshot_created.png
    ├── 15_snapshot_completed.png
    ├── 16_file_deleted_verified.png
    ├── 17_restored_volume_available.png
    ├── 18_restored_volume_in_use.png
    └── 19_file_restored_verified.png
```

---

*Lab completed as part of AWS Training and Certification coursework.*  
*© 2023 Amazon Web Services, Inc. — Lab content used for educational purposes.*
