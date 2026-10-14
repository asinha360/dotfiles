import Carbon.HIToolbox

/// Global ⌥W via Carbon RegisterEventHotKey (needs no Accessibility permission). Lives as long as the daemon.
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init?(action: @escaping () -> Void) {
        self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            guard let ctx else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<HotKey>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &spec, ctx, &handler)
        // 'wsnc'
        let id = EventHotKeyID(signature: OSType(0x7773_6E63), id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_ANSI_W), UInt32(optionKey), id, GetApplicationEventTarget(),
                                             0, &ref)
        guard installed == noErr, registered == noErr else { return nil }
    }
}
