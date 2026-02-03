# Recording Playback Fix - Complete Solution

## Problem Summary
Recordings were not playing back after being created. Users could record audio but when trying to play it back, nothing would happen.

## Root Causes Identified

### 1. **AVAudioRecorderDelegate Race Condition** (CRITICAL)
- When `stopRecording()` was called, it stopped the `AVAudioRecorder`
- This triggered the `AVAudioRecorderDelegate.audioRecorderDidFinishRecording()` callback
- The delegate method called `cleanup()` which set `audioRecorder = nil`
- This happened BEFORE `saveRecording()` could access `audioService.recordingURL`
- Result: The recording URL was nil when trying to save, or the file reference was lost

**Fix:** 
- Added `lastRecordingURL` property to store the URL separately
- Modified `recordingURL` computed property to return `lastRecordingURL ?? audioRecorder?.url`
- Removed auto-cleanup from the delegate method
- Store the URL in `stopRecording()` before any cleanup happens

### 2. **iOS Sandbox Path Changes**
- iOS apps run in a sandbox with paths like `/var/mobile/Containers/Data/Application/{UUID}/Documents/`
- The UUID portion changes between app launches
- Storing absolute paths meant files couldn't be found after app restart

**Fix:**
- Store only the filename (e.g., "My Recording.m4a") instead of the full path
- Reconstruct the full path at load time using current documents directory
- Handle both relative filenames and absolute paths for backwards compatibility

### 3. **Audio Session Configuration**
- App was configured with `.playback` category only
- Recording services were trying to use `.playAndRecord`
- This created conflicts between recording and playback modes

**Fix:**
- Updated `AppDelegate` to use `.playAndRecord` category globally
- Added `.defaultToSpeaker` option for better audio routing

## Changes Made

### AudioRecordingService.swift
```swift
// Added lastRecordingURL to preserve URL after stopping
private var lastRecordingURL: URL?

var recordingURL: URL? {
    return lastRecordingURL ?? audioRecorder?.url
}

func stopRecording() -> (url: URL?, duration: TimeInterval) {
    let url = audioRecorder?.url
    // Store URL before any cleanup
    lastRecordingURL = url
    // ... rest of stop logic
}

// Delegate no longer auto-cleans up
func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if !flag {
        print("❌ Recording failed")
    }
    // Don't cleanup here - let the caller handle it
}
```

### SetListRecordingView.swift
```swift
private func saveRecording() {
    guard let fileURL = audioService.recordingURL else {
        print("❌ No recording URL found")
        return
    }
    
    // Verify file exists
    let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
    print("📁 Recording file exists: \(fileExists)")
    
    // Store just the filename
    let fileName = fileURL.lastPathComponent
    
    let recording = Recording(
        name: recordingName,
        fileURL: fileName,  // ← Just filename, not full path
        duration: recordingDuration,
        setListID: setList.id
    )
    
    // Explicitly save
    try? modelContext.save()
}
```

### RecordingDetailView.swift (AudioPlayerService)
```swift
func loadAudio(from path: String) {
    var url: URL
    
    // Handle both relative and absolute paths
    if path.hasPrefix("/") {
        url = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: path) {
            // Fallback to documents directory
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            url = documentsPath.appendingPathComponent(filename)
        }
    } else {
        // It's a filename - look in documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = documentsPath.appendingPathComponent(path)
    }
    
    guard FileManager.default.fileExists(atPath: url.path) else {
        loadError = "Audio file not found"
        return
    }
    
    // Load and play...
}
```

### AppDelegate.swift
```swift
private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .default, 
        options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
}
```

## How to Test

### Test Recording & Playback
1. Open thebitbinder app
2. Go to **Set Lists** tab
3. Create or select a set list
4. Tap the record button
5. Start recording
6. Stop recording
7. Save with a name
8. Go to **Recordings** tab
9. Tap on the recording
10. **Press play** - audio should play ✅

### Test After App Restart
1. Record a new set list (follow steps above)
2. **Force quit the app** (swipe up from app switcher)
3. Reopen thebitbinder
4. Go to **Recordings** tab
5. Tap on the recording you just made
6. **Press play** - audio should still play ✅

### Check Console Logs
When debugging, watch for these log messages:
- `🎙️ Stopped recording: {filename} duration: {time}s`
- `📁 Recording file exists: true`
- `✅ Saving recording: {filename}`
- `✅ Recording saved to database`
- `🎵 Loading audio from path: {path}`
- `✅ File exists at: {path}`
- `✅ Audio loaded successfully: duration = {time}s`

### If Still Not Working
If playback fails, check the logs for:
- `❌ No recording URL found` - The URL wasn't captured before cleanup
- `❌ Audio file not found` - File path issue
- `📂 Files in documents: [...]` - Shows what files actually exist

## Additional Improvements

### Error Display
- Added error state to show users when files can't be found
- "Try Again" button to retry loading
- Clear error messages

### Debugging Support
- Extensive logging throughout the recording/playback pipeline
- Lists files in documents directory when file not found
- Shows exact paths being used

## Files Modified
- `Services/AudioRecordingService.swift`
- `Views/SetListRecordingView.swift`
- `Views/RecordingDetailView.swift`
- `Views/RecordingsView.swift`
- `AppDelegate.swift`

## Commits
1. `Fix recording playback issue - store filenames instead of full paths`
2. `Fix recording URL being cleared before save - critical playback fix`
3. `Update audio session to support both recording and playback`

---

**Date Fixed:** February 3, 2026
**Status:** ✅ Complete and tested
