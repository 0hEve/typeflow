import CoreGraphics
import Foundation

final class KeyboardEmitter {
    private let source = CGEventSource(stateID: .hidSystemState)

    func type(_ character: Character) {
        postUnicode(String(character), keyDown: true)
        postUnicode(String(character), keyDown: false)
    }

    func backspace() {
        guard let down = CGEvent(
            keyboardEventSource: source,
            virtualKey: 51,
            keyDown: true
        ), let up = CGEvent(
            keyboardEventSource: source,
            virtualKey: 51,
            keyDown: false
        ) else { return }

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func postUnicode(_ string: String, keyDown: Bool) {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0,
            keyDown: keyDown
        ) else { return }

        let utf16 = Array(string.utf16)
        utf16.withUnsafeBufferPointer { buffer in
            guard let address = buffer.baseAddress else { return }
            event.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: address
            )
        }
        event.post(tap: .cghidEventTap)
    }
}
