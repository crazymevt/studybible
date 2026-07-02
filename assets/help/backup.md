# Backup & Restore

Because StudyBible is an offline-first application, your personal data (journals, sermons, and notes) lives entirely on your device. We provide robust backup and sync tools to ensure you never lose your data.

## JSON Backups
You can take a complete snapshot of your user data at any time.
1. Open the **Backup & Restore** screen from the hamburger menu (App Drawer).
2. Tap **Export Backup** to generate a `.json` file containing all your notes, journals, and prayers.
3. Save this file to iCloud, Google Drive, or email it to yourself.
4. To restore, tap **Import Backup** on any device and select your `.json` file. 

*Note: Importing a backup merges the data. Existing data on the device is updated if the backup has newer timestamps, and missing data is added. No data is hard-deleted during an import!*

## Sync Folder
For automatic syncing across devices (like between your Mac and iPhone), you can configure a **Sync Folder** in the Settings.
- If you set your Sync Folder to an iCloud Drive directory, StudyBible will automatically sync your changes seamlessly in the background!

## Auto Sync
By default, sync runs when you press the **Sync** button. Turn on **Settings → Sync → Auto sync** to have the app sync by itself: once shortly after it starts, and then on a schedule you choose (every 15 minutes by default) for as long as it stays open. This keeps the Dashboard's **Continue reading** card and your notes, highlights, and progress fresh across devices without thinking about it. Auto sync is silent — if a sync fails (say, you're offline), it simply tries again at the next interval.

> 🌐 **Needs internet** — Writing the backup file itself is offline, but your cloud drive (iCloud, Google Drive, etc.) needs a connection to upload those changes and pull them down on your other devices.
