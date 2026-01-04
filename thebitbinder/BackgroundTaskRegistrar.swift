import BackgroundTasks

enum BackgroundTaskIdentifier {
    static let refresh = "com.taylordrew.thebitbinder.bg.refresh"
    static let processing = "com.taylordrew.thebitbinder.bg.processing"
}

final class BackgroundTaskRegistrar {
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskIdentifier.refresh, using: nil) { task in
            task.setTaskCompleted(success: true)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskIdentifier.processing, using: nil) { task in
            task.setTaskCompleted(success: true)
        }
    }
}
