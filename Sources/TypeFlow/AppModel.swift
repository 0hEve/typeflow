import Carbon.HIToolbox
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var draft: String {
        didSet { defaults.set(draft, forKey: Keys.draft) }
    }
    @Published private(set) var state: TypingState = .idle
    @Published private(set) var completedCharacters = 0
    @Published private(set) var totalCharacters = 0
    @Published private(set) var accessibilityGranted = AccessibilityAccess.isTrusted
    @Published private(set) var notice = "Paste text, place your cursor, then press the hotkey."

    let preferences: TypingPreferences

    private enum Keys {
        static let draft = "draft"
    }

    private enum CountdownAction {
        case start
        case resume
    }

    private let defaults: UserDefaults
    private let engine = TypingEngine()
    private var countdownTask: Task<Void, Never>?
    private var countdownAction: CountdownAction?
    private var globalHotKey: GlobalHotKey?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = TypingPreferences(defaults: defaults)
        draft = defaults.string(forKey: Keys.draft) ?? ""

        globalHotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey | cmdKey)
        ) { [weak self] in
            Task { @MainActor in
                self?.toggleFromHotKey()
            }
        }
    }

    var progress: Double {
        guard totalCharacters > 0 else { return 0 }
        return Double(completedCharacters) / Double(totalCharacters)
    }

    var canEdit: Bool {
        state == .idle || state == .completed
    }

    func requestAccessibility() {
        accessibilityGranted = AccessibilityAccess.request()
        if accessibilityGranted {
            notice = "Accessibility access is ready."
        } else {
            notice = "Enable TypeFlow in Privacy & Security → Accessibility, then try again."
            AccessibilityAccess.openSettings()
        }
    }

    func refreshAccessibility(announce: Bool = true) {
        let wasGranted = accessibilityGranted
        accessibilityGranted = AccessibilityAccess.isTrusted
        if announce || accessibilityGranted != wasGranted {
            notice = accessibilityGranted
                ? "Accessibility access is ready."
                : "TypeFlow still needs Accessibility access."
        }
    }

    func menuDidOpen() {
        if state.isActivelyTyping {
            engine.pause()
            notice = "Paused because the TypeFlow menu opened."
        }
    }

    func primaryActionFromMenu() {
        switch state {
        case .idle, .completed:
            schedule(.start, after: 3)
        case .paused:
            schedule(.resume, after: 3)
        case .typing, .paragraphPause:
            engine.pause()
            notice = "Paused."
        case .countdown:
            cancelCountdown()
        }
    }

    func toggleFromHotKey() {
        switch state {
        case .idle, .completed:
            startNow()
        case .typing, .paragraphPause:
            engine.pause()
            notice = "Paused at character \(completedCharacters)."
        case .paused:
            engine.resume()
            notice = "Typing resumed."
        case .countdown:
            cancelCountdown()
        }
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        let wasResume = countdownAction == .resume
        countdownAction = nil
        state = wasResume ? .paused : .idle
        notice = "Start cancelled."
    }

    func reset() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownAction = nil
        engine.cancel()
        completedCharacters = 0
        totalCharacters = 0
        state = .idle
        notice = "Reset. Paste or edit text when you’re ready."
    }

    private func schedule(_ action: CountdownAction, after seconds: Int) {
        guard validateReady() else { return }
        countdownTask?.cancel()
        countdownAction = action
        state = .countdown(seconds)
        notice = "Click your destination field. Typing starts in \(seconds) seconds."

        countdownTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: seconds, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                self.state = .countdown(remaining)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard !Task.isCancelled else { return }
            self.countdownTask = nil
            self.countdownAction = nil
            switch action {
            case .start: self.startNow()
            case .resume:
                self.engine.resume()
                self.notice = "Typing resumed."
            }
        }
    }

    private func startNow() {
        guard validateReady() else { return }
        if state == .completed {
            completedCharacters = 0
        }
        totalCharacters = Array(draft).count
        let options = preferences.options
        notice = "Typing at \(preferences.minimumWPM)–\(preferences.maximumWPM) WPM. Press ⌃⌥⌘T to pause."

        engine.begin(
            text: draft,
            startAt: completedCharacters,
            options: options,
            onProgress: { [weak self] progress in
                self?.completedCharacters = progress
            },
            onStateChange: { [weak self] newState in
                self?.state = newState
                if newState == .completed {
                    self?.notice = "Finished typing the full text."
                }
            }
        )
    }

    private func validateReady() -> Bool {
        accessibilityGranted = AccessibilityAccess.isTrusted
        guard accessibilityGranted else {
            requestAccessibility()
            return false
        }
        guard !draft.isEmpty else {
            notice = "Paste some text before starting."
            return false
        }
        return true
    }
}
