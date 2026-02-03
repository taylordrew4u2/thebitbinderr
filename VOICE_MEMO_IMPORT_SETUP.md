# Voice Memo Import Guide

## How to Import Voice Memos into thebitbinder

There are two ways to import voice memos into thebitbinder as jokes:

---

## Method 1: Save to Files (Recommended)

This is the simplest and most reliable method:

1. **Open the Voice Memos app** on your iPhone
2. **Tap on the recording** you want to import
3. **Tap the ••• (more options) button**
4. **Tap "Save to Files"**
5. **Choose a location** (e.g., "On My iPhone" or iCloud Drive)
6. **Open thebitbinder**
7. **Go to Jokes tab → tap + → "Import Voice Memos"**
8. **Tap "Browse Files"**
9. **Navigate to where you saved the file and select it**
10. **The audio will be transcribed and saved as a joke!**

---

## Method 2: Share Extension (If Set Up)

If the Share Extension is properly configured in Xcode:

1. Open Voice Memos app
2. Tap on a recording
3. Tap the ••• button → Share
4. Look for **"Save to Jokes"** in the share sheet
5. The audio will be transcribed automatically

**Note:** The share extension requires additional Xcode setup (see below).

---

## Share Extension Setup (For Developers)

To enable the "Save to Jokes" share option:

### 1. Add New Target
1. Open the project in Xcode
2. Go to **File → New → Target**
3. Select **iOS → Share Extension**
4. Name it: `VoiceMemoImport`
5. Bundle Identifier: `com.taylordrew.thebitbinder.VoiceMemoImport`
6. Click **Finish**

### 2. Configure App Group
1. Select the **thebitbinder** target → Signing & Capabilities → + Capability → App Groups
2. Add: `group.com.taylordrew.thebitbinder`
3. Do the same for the **VoiceMemoImport** target

### 3. Build and Run
Build and run on your device. The "Save to Jokes" option should appear in the share sheet when sharing audio files.

---

## Supported Audio Formats

- .m4a (Voice Memos default)
- .mp3
- .wav
- .aac
- .caf
- .aiff

---

## Troubleshooting

**Q: I don't see "Save to Jokes" in the share sheet**
A: Use Method 1 (Save to Files) instead. The share extension requires additional Xcode setup.

**Q: Transcription failed**
A: Make sure you have granted speech recognition permission in Settings → thebitbinder. Also ensure you have an internet connection.

**Q: The transcription quality is poor**
A: Speech recognition works best with clear audio. Background noise may reduce accuracy.
