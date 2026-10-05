import Carbon
import AppKit

// System-wide hotkey via Carbon RegisterEventHotKey.
// Fires even when unADHD is in the background, and needs NO Accessibility permission.
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onFire: (() -> Void)?

    // ⌃⌥⇧U
    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            if let userData = userData {
                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { mgr.onFire?() }
            }
            return noErr
        }, 1, &eventType, selfPtr, &handlerRef)

        let modifiers = UInt32(controlKey | optionKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_U)
        let hotKeyID = EventHotKeyID(signature: OSType(0x756e4144), id: 1) // 'unAD'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
