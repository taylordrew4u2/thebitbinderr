import UIKit
import BackgroundTasks
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        BackgroundTaskRegistrar.register()
        configureAudioSession()
        setupAudioSessionNotifications()
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Configure for both recording and playback with optimal settings for iOS 17
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .defaultToSpeaker,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .allowAirPlay,
                    .mixWithOthers
                ]
            )
            
            // Activate the session
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("✅ Audio session configured successfully")
            print("   Category: \(session.category.rawValue)")
            print("   Mode: \(session.mode.rawValue)")
            print("   Sample Rate: \(session.sampleRate) Hz")
            print("   Input Available: \(session.isInputAvailable)")
            print("   Output Volume: \(session.outputVolume)")
            
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioSessionNotifications() {
        // Handle audio interruptions (phone calls, alarms, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Handle route changes (headphones plugged/unplugged, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Handle media services were reset
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("🔇 Audio session interrupted (began)")
            // Audio session has been deactivated
            // Recording/playback should pause automatically
            
        case .ended:
            print("🔊 Audio session interruption ended")
            
            // Check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("   Should resume audio")
                    // Reactivate the audio session
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        print("   ✅ Audio session reactivated")
                    } catch {
                        print("   ❌ Failed to reactivate audio session: \(error)")
                    }
                }
            }
            
        @unknown default:
            print("⚠️ Unknown audio interruption type")
        }
    }
    
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        
        switch reason {
        case .newDeviceAvailable:
            print("🎧 New audio device available")
            print("   Current route: \(session.currentRoute.outputs.first?.portType.rawValue ?? "unknown")")
            
        case .oldDeviceUnavailable:
            print("🎧 Audio device disconnected")
            // Pause playback if headphones were unplugged
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                let wasUsingHeadphones = previousRoute.outputs.contains { output in
                    output.portType == .headphones || output.portType == .bluetoothA2DP
                }
                if wasUsingHeadphones {
                    print("   Headphones unplugged - playback should pause")
                }
            }
            
        case .categoryChange:
            print("🔄 Audio category changed: \(session.category.rawValue)")
            
        case .override, .wakeFromSleep, .noSuitableRouteForCategory, .routeConfigurationChange:
            print("🔄 Audio route changed: \(reason)")
            
        @unknown default:
            print("⚠️ Unknown route change reason")
        }
    }
    
    @objc private func handleMediaServicesReset(notification: Notification) {
        print("⚠️ Media services were reset - reconfiguring audio session")
        configureAudioSession()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Ensure audio session is active when app becomes active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session reactivated on app becoming active")
        } catch {
            print("❌ Failed to reactivate audio session: \(error)")
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Don't deactivate - let the system handle it
        print("ℹ️ App will resign active")
    }
}
