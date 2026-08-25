import Foundation

struct TypingOptions {
    var naturalCorrections = true
    var correctionInterval = 5...15
    var repeatedMistakeChance = 0.2
    var paragraphPauses = true
    var paragraphPauseSeconds = 10...30
    var wordsPerMinute = 40.0...60.0
}

enum TypingPolicy {
    private static let adjacentKeys: [Character: [Character]] = [
        "a": ["q", "w", "s", "z"], "b": ["v", "g", "h", "n"],
        "c": ["x", "d", "f", "v"], "d": ["s", "e", "r", "f", "c", "x"],
        "e": ["w", "s", "d", "r"], "f": ["d", "r", "t", "g", "v", "c"],
        "g": ["f", "t", "y", "h", "b", "v"], "h": ["g", "y", "u", "j", "n", "b"],
        "i": ["u", "j", "k", "o"], "j": ["h", "u", "i", "k", "m", "n"],
        "k": ["j", "i", "o", "l", "m"], "l": ["k", "o", "p"],
        "m": ["n", "j", "k"], "n": ["b", "h", "j", "m"],
        "o": ["i", "k", "l", "p"], "p": ["o", "l"],
        "q": ["w", "a"], "r": ["e", "d", "f", "t"],
        "s": ["a", "w", "e", "d", "x", "z"], "t": ["r", "f", "g", "y"],
        "u": ["y", "h", "j", "i"], "v": ["c", "f", "g", "b"],
        "w": ["q", "a", "s", "e"], "x": ["z", "s", "d", "c"],
        "y": ["t", "g", "h", "u"], "z": ["a", "s", "x"]
    ]

    static func wordsUntilNextCorrection<R: RandomNumberGenerator>(
        in range: ClosedRange<Int>,
        using rng: inout R
    ) -> Int {
        Int.random(in: range, using: &rng)
    }

    static func paragraphPauseSeconds<R: RandomNumberGenerator>(
        in range: ClosedRange<Int>,
        using rng: inout R
    ) -> Int {
        Int.random(in: range, using: &rng)
    }

    static func makeTypo<R: RandomNumberGenerator>(
        for word: String,
        using rng: inout R
    ) -> String? {
        var characters = Array(word)
        guard characters.count >= 4 else { return nil }

        let candidates = characters.indices.filter {
            guard let lower = String(characters[$0]).lowercased().first else { return false }
            return adjacentKeys[lower] != nil
        }
        guard let index = candidates.randomElement(using: &rng) else { return nil }

        switch Int.random(in: 0...2, using: &rng) {
        case 0:
            guard let lower = String(characters[index]).lowercased().first,
                  let replacement = adjacentKeys[lower]?.randomElement(using: &rng) else {
                return nil
            }
            characters[index] = characters[index].isUppercase
                ? Character(String(replacement).uppercased())
                : replacement
        case 1:
            characters.insert(characters[index], at: index)
        default:
            let neighbor = index < characters.count - 1 ? index + 1 : index - 1
            characters.swapAt(index, neighbor)
        }

        let typo = String(characters)
        return typo == word ? nil : typo
    }

    static func characterDelayNanoseconds<R: RandomNumberGenerator>(
        for character: Character,
        wordsPerMinute range: ClosedRange<Double>,
        using rng: inout R
    ) -> UInt64 {
        let targetWPM = Double.random(in: range, using: &rng)
        let baseSeconds = 60.0 / (targetWPM * 5.0)
        let rhythmJitter = Double.random(in: 0.68...1.32, using: &rng)
        let characterFactor = character.isWhitespace ? 0.55 : 1.1
        return UInt64(baseSeconds * rhythmJitter * characterFactor * 1_000_000_000)
    }
}
