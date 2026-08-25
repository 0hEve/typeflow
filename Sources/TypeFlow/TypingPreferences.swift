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

    @Published var minimumWPM: Int { didSet { save(minimumWPM, Keys.minimumWPM) } }
    @Published var maximumWPM: Int { didSet { save(maximumWPM, Keys.maximumWPM) } }
    @Published var naturalCorrections: Bool {
        didSet { save(naturalCorrections, Keys.naturalCorrections) }
    }
    @Published var correctionMinimumWords: Int {
        didSet { save(correctionMinimumWords, Keys.correctionMinimumWords) }
    }
    @Published var correctionMaximumWords: Int {
        didSet { save(correctionMaximumWords, Keys.correctionMaximumWords) }
    }
    @Published var repeatedMistakeChance: Int {
        didSet { save(repeatedMistakeChance, Keys.repeatedMistakeChance) }
    }
    @Published var paragraphPauses: Bool {
        didSet { save(paragraphPauses, Keys.paragraphPauses) }
    }
    @Published var paragraphPauseMode: ParagraphPauseMode {
        didSet { save(paragraphPauseMode.rawValue, Keys.paragraphPauseMode) }
    }
    @Published var paragraphMinimumSeconds: Int {
        didSet { save(paragraphMinimumSeconds, Keys.paragraphMinimumSeconds) }
    }
    @Published var paragraphMaximumSeconds: Int {
        didSet { save(paragraphMaximumSeconds, Keys.paragraphMaximumSeconds) }
    }
    @Published var paragraphFixedSeconds: Int {
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
        let normalizedMinimumWPM = min(max(loadedMinimumWPM, 20), 115)
        minimumWPM = normalizedMinimumWPM
        let loadedMaximumWPM = Self.integer(
            defaults,
            key: Keys.maximumWPM,
            fallback: Self.defaultMaximumWPM
        )
        maximumWPM = min(max(loadedMaximumWPM, normalizedMinimumWPM + 5), 120)

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
        let normalizedCorrectionMinimum = min(max(loadedCorrectionMinimum, 1), 49)
        correctionMinimumWords = normalizedCorrectionMinimum
        let loadedCorrectionMaximum = Self.integer(
            defaults,
            key: Keys.correctionMaximumWords,
            fallback: Self.defaultCorrectionMaximum
        )
        correctionMaximumWords = min(max(
            loadedCorrectionMaximum,
            normalizedCorrectionMinimum + 1
        ), 50)
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
        let normalizedParagraphMinimum = min(max(loadedParagraphMinimum, 1), 179)
        paragraphMinimumSeconds = normalizedParagraphMinimum
        let loadedParagraphMaximum = Self.integer(
            defaults,
            key: Keys.paragraphMaximumSeconds,
            fallback: Self.defaultParagraphMaximum
        )
        paragraphMaximumSeconds = min(max(
            loadedParagraphMaximum,
            normalizedParagraphMinimum + 1
        ), 180)
        paragraphFixedSeconds = min(max(Self.integer(
            defaults,
            key: Keys.paragraphFixedSeconds,
            fallback: Self.defaultParagraphFixed
        ), 1), 180)
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
