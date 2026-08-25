import Carbon.HIToolbox

final class GlobalHotKey {
    private static var callbacks: [UInt32: () -> Void] = [:]
    private static var eventHandler: EventHandlerRef?
    private static var nextID: UInt32 = 1

    private var hotKey: EventHotKeyRef?
    private let identifier: UInt32

    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        identifier = Self.nextID
        Self.nextID += 1
        Self.callbacks[identifier] = action
        Self.installHandlerIfNeeded()

        let keyID = EventHotKeyID(signature: Self.signature, id: identifier)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            keyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    deinit {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }
        Self.callbacks[identifier] = nil
    }

    private static let signature: OSType = 0x5459464C // TYFL

    private static func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, _ in
            guard let event else { return OSStatus(eventNotHandledErr) }
            var keyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &keyID
            )
            guard status == noErr, keyID.signature == GlobalHotKey.signature else {
                return OSStatus(eventNotHandledErr)
            }
            GlobalHotKey.callbacks[keyID.id]?()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }
}
