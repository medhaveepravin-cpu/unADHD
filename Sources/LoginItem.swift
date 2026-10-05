import ServiceManagement

// Launch-at-login via SMAppService (macOS 13+). Source of truth is the system status.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("unADHD login-item error: \(error.localizedDescription)")
        }
    }
}
