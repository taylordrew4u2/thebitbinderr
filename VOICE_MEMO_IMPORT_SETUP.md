# Voice Memo Import Share Extension Setup

To complete the Voice Memo import feature, you need to add a Share Extension to your Xcode project. This allows users to share voice memos directly from the Voice Memos app to thebitbinder.

## Steps to Add Share Extension in Xcode:

### 1. Add New Target
1. Open the project in Xcode
2. Go to **File → New → Target**
3. Select **iOS → Share Extension**
4. Name it: `VoiceMemoImport`
5. Bundle Identifier: `com.taylordrew.thebitbinder.VoiceMemoImport`
6. Click **Finish**
7. When prompted to activate the scheme, click **Cancel** (you can keep using the main app scheme)

### 2. Replace Generated Files
Replace the auto-generated files with the ones in the `VoiceMemoImport` folder:
- `ShareViewController.swift` - Already created
- `Info.plist` - Already created  
- `VoiceMemoImport.entitlements` - Already created

### 3. Configure App Group
1. Select the **thebitbinder** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → Add **App Groups**
4. Add: `group.com.taylordrew.thebitbinder`

5. Select the **VoiceMemoImport** target
6. Go to **Signing & Capabilities**
7. Click **+ Capability** → Add **App Groups**
8. Add the same: `group.com.taylordrew.thebitbinder`

### 4. Update Share Extension Info.plist
The Info.plist is configured to accept audio files. The extension will appear when sharing from Voice Memos.

### 5. Build and Run
1. Build and run on your device
2. Open Voice Memos app
3. Long press on a recording
4. Tap **Share**
5. Select **thebitbinder**
6. The audio will be transcribed and saved as a joke

## How It Works

1. User shares voice memo from Voice Memos app
2. Share extension receives the audio file
3. Extension transcribes audio using Speech Recognition
4. Transcription is saved to shared App Group storage
5. When user opens thebitbinder Jokes tab, pending imports are processed
6. New jokes appear in the list

## Alternative: Browse Files Method

If you don't want to set up the share extension, users can still:
1. In Voice Memos, tap a recording → tap ••• → "Save to Files"
2. In thebitbinder, tap + → "Import Voice Memos" → "Browse Files"
3. Navigate to where they saved the file
