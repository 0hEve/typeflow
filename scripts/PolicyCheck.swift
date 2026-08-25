import Foundation
@testable import TypeFlowPolicy

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("Policy check failed: \(message)\n".utf8))
        exit(1)
    }
}

var intervalRNG = SeededRandomNumberGenerator(seed: 42)
for _ in 0..<100 {
    let interval = TypingPolicy.wordsUntilNextCorrection(in: 2...4, using: &intervalRNG)
    require((2...4).contains(interval), "custom correction interval escaped 2...4")
}

var typoRNG = SeededRandomNumberGenerator(seed: 9)
guard let typo = TypingPolicy.makeTypo(for: "Kevin", using: &typoRNG) else {
    FileHandle.standardError.write(Data("Policy check failed: eligible word had no typo\n".utf8))
    exit(1)
}
require(typo != "Kevin", "typo did not change the word")
require(typo.first?.isUppercase == true, "capitalization style was not preserved")
require((4...6).contains(typo.count), "typo length was implausible")

var shortWordRNG = SeededRandomNumberGenerator(seed: 1)
require(
    TypingPolicy.makeTypo(for: "the", using: &shortWordRNG) == nil,
    "short words should be left alone"
)

var pacingRNG = SeededRandomNumberGenerator(seed: 77)
for _ in 0..<100 {
    let delay = TypingPolicy.characterDelayNanoseconds(
        for: "a",
        wordsPerMinute: 50...70,
        using: &pacingRNG
    )
    require(delay >= 171_000_000, "custom character delay was too short")
    require(delay <= 241_000_000, "custom character delay was too long")
}

var pauseRNG = SeededRandomNumberGenerator(seed: 17)
for _ in 0..<100 {
    let pause = TypingPolicy.paragraphPauseSeconds(in: 10...30, using: &pauseRNG)
    require((10...30).contains(pause), "paragraph pause escaped 10...30 seconds")
}
let fixedPause = TypingPolicy.paragraphPauseSeconds(in: 12...12, using: &pauseRNG)
require(fixedPause == 12, "fixed paragraph pause changed")

MainActor.assumeIsolated {
    let suiteName = "com.kevin.typeflow.policy-check"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        FileHandle.standardError.write(Data("Policy check failed: test defaults unavailable\n".utf8))
        exit(1)
    }
    defaults.removePersistentDomain(forName: suiteName)

    let preferences = TypingPreferences(defaults: defaults)
    require(preferences.options.wordsPerMinute == 40.0...60.0, "default WPM range changed")
    require(preferences.options.correctionInterval == 5...15, "default correction range changed")
    require(preferences.options.paragraphPauseSeconds == 10...30, "default pause range changed")

    preferences.minimumWPM = 55
    preferences.maximumWPM = 75
    preferences.repeatedMistakeChance = 100
    preferences.paragraphPauseMode = .fixed
    preferences.paragraphFixedSeconds = 18
    require(preferences.options.wordsPerMinute == 55.0...75.0, "custom WPM range was not applied")
    require(preferences.options.repeatedMistakeChance == 1, "100% retry chance was not applied")
    require(preferences.options.paragraphPauseSeconds == 18...18, "fixed pause was not applied")

    let reloaded = TypingPreferences(defaults: defaults)
    require(reloaded.minimumWPM == 55, "minimum WPM was not persisted")
    require(reloaded.maximumWPM == 75, "maximum WPM was not persisted")
    require(reloaded.repeatedMistakeChance == 100, "retry chance was not persisted")
    require(reloaded.paragraphFixedSeconds == 18, "fixed pause was not persisted")

    defaults.removePersistentDomain(forName: suiteName)
}

print("Policy checks passed: settings persistence, custom ranges, typos, pacing, and paragraph modes")
