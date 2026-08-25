import Foundation

enum ParagraphPauseMode: String, CaseIterable, Identifiable {
    case range
    case fixed

    var id: Self { self }

    var title: String {
        switch self {
        case .range: "Range"
        case .fixed: "Fixed"
        }
    }
}

@MainActor
final class TypingPreferences: ObservableObject {
    static let defaultMinimumWPM = 40
    static let defaultMaximumWPM = 60
    static let defaultCorrectionMinimum = 5
    static let defaultCorrectionMaximum = 15
    static let defaultRepeatedMistakeChance = 20
    static let defaultParagraphMinimum = 10
    static let defaultParagraphMaximum = 30
    static let defaultParagraphFixed = 20

    @Published private(set) var minimumWPM: Int { didSet { save(minimumWPM, Keys.minimumWPM) } }
    @Published private(set) var maximumWPM: Int { didSet { save(maximumWPM, Keys.maximumWPM) } }
    @Published var naturalCorrections: Bool {
        didSet { save(naturalCorrections, Keys.naturalCorrections) }
    }
    @Published private(set) var correctionMinimumWords: Int {
        didSet { save(correctionMinimumWords, Keys.correctionMinimumWords) }
    }
    @Published private(set) var correctionMaximumWords: Int {
        didSet { save(correctionMaximumWords, Keys.correctionMaximumWords) }
    }
    @Published private(set) var repeatedMistakeChance: Int {
        didSet { save(repeatedMistakeChance, Keys.repeatedMistakeChance) }
    }
    @Published var paragraphPauses: Bool {
        didSet { save(paragraphPauses, Keys.paragraphPauses) }
    }
    @Published var paragraphPauseMode: ParagraphPauseMode {
        didSet { save(paragraphPauseMode.rawValue, Keys.paragraphPauseMode) }
    }
    @Published private(set) var paragraphMinimumSeconds: Int {
        didSet { save(paragraphMinimumSeconds, Keys.paragraphMinimumSeconds) }
    }
    @Published private(set) var paragraphMaximumSeconds: Int {
        didSet { save(paragraphMaximumSeconds, Keys.paragraphMaximumSeconds) }
    }
    @Published private(set) var paragraphFixedSeconds: Int {
        didSet { save(paragraphFixedSeconds, Keys.paragraphFixedSeconds) }
    }

    private enum Keys {
        static let minimumWPM = "minimumWPM"
        static let maximumWPM = "maximumWPM"
        static let naturalCorrections = "naturalCorrections"
        static let correctionMinimumWords = "correctionMinimumWords"
        static let correctionMaximumWords = "correctionMaximumWords"
        static let repeatedMistakeChance = "repeatedMistakeChance"
        static let paragraphPauses = "paragraphPauses"
        static let paragraphPauseMode = "paragraphPauseMode"
        static let paragraphMinimumSeconds = "paragraphMinimumSeconds"
        static let paragraphMaximumSeconds = "paragraphMaximumSeconds"
        static let paragraphFixedSeconds = "paragraphFixedSeconds"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let loadedMinimumWPM = Self.integer(
            defaults,
            key: Keys.minimumWPM,
            fallback: Self.defaultMinimumWPM
        )
        let normalizedMinimumWPM = min(max(loadedMinimumWPM, 1), Int.max - 1)
        minimumWPM = normalizedMinimumWPM
        let loadedMaximumWPM = Self.integer(
            defaults,
            key: Keys.maximumWPM,
            fallback: Self.defaultMaximumWPM
        )
        maximumWPM = max(loadedMaximumWPM, normalizedMinimumWPM + 1)

        naturalCorrections = Self.boolean(
            defaults,
            key: Keys.naturalCorrections,
            fallback: true
        )
        let loadedCorrectionMinimum = Self.integer(
            defaults,
            key: Keys.correctionMinimumWords,
            fallback: Self.defaultCorrectionMinimum
        )
        let normalizedCorrectionMinimum = min(max(loadedCorrectionMinimum, 1), Int.max - 1)
        correctionMinimumWords = normalizedCorrectionMinimum
        let loadedCorrectionMaximum = Self.integer(
            defaults,
            key: Keys.correctionMaximumWords,
            fallback: Self.defaultCorrectionMaximum
        )
        correctionMaximumWords = max(loadedCorrectionMaximum, normalizedCorrectionMinimum + 1)
        repeatedMistakeChance = min(max(Self.integer(
            defaults,
            key: Keys.repeatedMistakeChance,
            fallback: Self.defaultRepeatedMistakeChance
        ), 0), 100)

        paragraphPauses = Self.boolean(
            defaults,
            key: Keys.paragraphPauses,
            fallback: true
        )
        paragraphPauseMode = ParagraphPauseMode(
            rawValue: defaults.string(forKey: Keys.paragraphPauseMode) ?? ""
        ) ?? .range
        let loadedParagraphMinimum = Self.integer(
            defaults,
            key: Keys.paragraphMinimumSeconds,
            fallback: Self.defaultParagraphMinimum
        )
        let normalizedParagraphMinimum = min(max(loadedParagraphMinimum, 1), Int.max - 1)
        paragraphMinimumSeconds = normalizedParagraphMinimum
        let loadedParagraphMaximum = Self.integer(
            defaults,
            key: Keys.paragraphMaximumSeconds,
            fallback: Self.defaultParagraphMaximum
        )
        paragraphMaximumSeconds = max(
            loadedParagraphMaximum,
            normalizedParagraphMinimum + 1
        )
        paragraphFixedSeconds = max(Self.integer(
            defaults,
            key: Keys.paragraphFixedSeconds,
            fallback: Self.defaultParagraphFixed
        ), 1)
    }

    var options: TypingOptions {
        let paragraphRange = paragraphPauseMode == .fixed
            ? paragraphFixedSeconds...paragraphFixedSeconds
            : paragraphMinimumSeconds...paragraphMaximumSeconds

        return TypingOptions(
            naturalCorrections: naturalCorrections,
            correctionInterval: correctionMinimumWords...correctionMaximumWords,
            repeatedMistakeChance: Double(repeatedMistakeChance) / 100,
            paragraphPauses: paragraphPauses,
            paragraphPauseSeconds: paragraphRange,
            wordsPerMinute: Double(minimumWPM)...Double(maximumWPM)
        )
    }

    func restoreDefaults() {
        minimumWPM = Self.defaultMinimumWPM
        maximumWPM = Self.defaultMaximumWPM
        naturalCorrections = true
        correctionMinimumWords = Self.defaultCorrectionMinimum
        correctionMaximumWords = Self.defaultCorrectionMaximum
        repeatedMistakeChance = Self.defaultRepeatedMistakeChance
        paragraphPauses = true
        paragraphPauseMode = .range
        paragraphMinimumSeconds = Self.defaultParagraphMinimum
        paragraphMaximumSeconds = Self.defaultParagraphMaximum
        paragraphFixedSeconds = Self.defaultParagraphFixed
    }

    func setMinimumWPM(_ value: Int) {
        minimumWPM = min(max(value, 1), maximumWPM - 1)
    }

    func setMaximumWPM(_ value: Int) {
        maximumWPM = max(value, minimumWPM + 1)
    }

    func setCorrectionMinimum(_ value: Int) {
        correctionMinimumWords = min(max(value, 1), correctionMaximumWords - 1)
    }

    func setCorrectionMaximum(_ value: Int) {
        correctionMaximumWords = max(value, correctionMinimumWords + 1)
    }

    func setRepeatedMistakeChance(_ value: Int) {
        repeatedMistakeChance = min(max(value, 0), 100)
    }

    func setParagraphMinimum(_ value: Int) {
        paragraphMinimumSeconds = min(max(value, 1), paragraphMaximumSeconds - 1)
    }

    func setParagraphMaximum(_ value: Int) {
        paragraphMaximumSeconds = max(value, paragraphMinimumSeconds + 1)
    }

    func setParagraphFixed(_ value: Int) {
        paragraphFixedSeconds = max(value, 1)
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }

    private static func integer(_ defaults: UserDefaults, key: String, fallback: Int) -> Int {
        defaults.object(forKey: key) as? Int ?? fallback
    }

    private static func boolean(_ defaults: UserDefaults, key: String, fallback: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? fallback
    }
}
