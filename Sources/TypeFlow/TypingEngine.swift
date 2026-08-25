import Foundation

@MainActor
final class TypingEngine {
    private let emitter = KeyboardEmitter()
    private var task: Task<Void, Never>?
    private var isPaused = false
    private var isCancelled = false
    private var onStateChange: ((TypingState) -> Void)?

    func begin(
        text: String,
        startAt startIndex: Int,
        options: TypingOptions,
        onProgress: @escaping (Int) -> Void,
        onStateChange: @escaping (TypingState) -> Void
    ) {
        cancel()
        isCancelled = false
        isPaused = false
        self.onStateChange = onStateChange
        onStateChange(.typing)

        task = Task { [weak self] in
            guard let self else { return }
            await self.run(
                characters: Array(text),
                startAt: startIndex,
                options: options,
                onProgress: onProgress
            )
        }
    }

    func pause() {
        guard !isPaused, !isCancelled else { return }
        isPaused = true
        onStateChange?(.paused)
    }

    func resume() {
        guard isPaused, !isCancelled else { return }
        isPaused = false
        onStateChange?(.typing)
    }

    func cancel() {
        isCancelled = true
        isPaused = false
        task?.cancel()
        task = nil
        onStateChange = nil
    }

    private func run(
        characters: [Character],
        startAt startIndex: Int,
        options: TypingOptions,
        onProgress: @escaping (Int) -> Void
    ) async {
        var rng = SystemRandomNumberGenerator()
        var cursor = min(max(startIndex, 0), characters.count)
        var wordsUntilCorrection = TypingPolicy.wordsUntilNextCorrection(
            in: options.correctionInterval,
            using: &rng
        )
        var wordsUntilShortPause = Int.random(in: 25...60, using: &rng)

        while cursor < characters.count {
            guard await waitWhilePaused(), !isCancelled else { return }

            if isWordCharacter(characters[cursor]) {
                let wordEnd = endOfWord(in: characters, startingAt: cursor)
                let word = String(characters[cursor..<wordEnd])
                wordsUntilCorrection -= 1

                if options.naturalCorrections,
                   wordsUntilCorrection <= 0,
                   let typo = TypingPolicy.makeTypo(for: word, using: &rng) {
                    guard await typeCorrection(
                        typo: typo,
                        correctWord: word,
                        repeatedMistakeChance: options.repeatedMistakeChance,
                        wordsPerMinute: options.wordsPerMinute,
                        rng: &rng
                    ) else { return }
                    wordsUntilCorrection = TypingPolicy.wordsUntilNextCorrection(
                        in: options.correctionInterval,
                        using: &rng
                    )
                } else {
                    guard await typeCharacters(
                        Array(word),
                        wordsPerMinute: options.wordsPerMinute,
                        rng: &rng
                    ) else { return }
                }

                cursor = wordEnd
                onProgress(cursor)
                wordsUntilShortPause -= 1
                continue
            }

            let character = characters[cursor]
            emitter.type(character)
            cursor += 1
            onProgress(cursor)

            guard await sleep(TypingPolicy.characterDelayNanoseconds(
                for: character,
                wordsPerMinute: options.wordsPerMinute,
                using: &rng
            )) else {
                return
            }

            if character == "\n", cursor >= 2, characters[cursor - 2] == "\n",
               options.paragraphPauses {
                let seconds = TypingPolicy.paragraphPauseSeconds(
                    in: options.paragraphPauseSeconds,
                    using: &rng
                )
                guard await paragraphPause(seconds: seconds) else { return }
            } else if ".,!?;:".contains(character) {
                let pause = UInt64.random(in: 180_000_000...650_000_000, using: &rng)
                guard await sleep(pause) else { return }
            } else if character.isWhitespace, wordsUntilShortPause <= 0 {
                let pause = UInt64.random(in: 700_000_000...2_400_000_000, using: &rng)
                guard await sleep(pause) else { return }
                wordsUntilShortPause = Int.random(in: 25...60, using: &rng)
            }
        }

        guard !isCancelled else { return }
        onStateChange?(.completed)
        task = nil
    }

    private func typeCorrection<R: RandomNumberGenerator>(
        typo: String,
        correctWord: String,
        repeatedMistakeChance: Double,
        wordsPerMinute: ClosedRange<Double>,
        rng: inout R
    ) async -> Bool {
        let attempts = Double.random(in: 0..<1, using: &rng) < repeatedMistakeChance ? 2 : 1

        for attempt in 0..<attempts {
            let attemptText: String
            if attempt == 0 {
                attemptText = typo
            } else {
                attemptText = TypingPolicy.makeTypo(for: correctWord, using: &rng) ?? typo
            }

            guard await typeCharacters(
                Array(attemptText),
                wordsPerMinute: wordsPerMinute,
                rng: &rng
            ) else { return false }
            let reaction = UInt64.random(in: 350_000_000...900_000_000, using: &rng)
            guard await sleep(reaction) else { return false }

            for _ in attemptText {
                guard await waitWhilePaused(), !isCancelled else { return false }
                emitter.backspace()
                let eraseDelay = UInt64.random(in: 55_000_000...115_000_000, using: &rng)
                guard await sleep(eraseDelay) else { return false }
            }
            guard await sleep(160_000_000) else { return false }
        }

        return await typeCharacters(
            Array(correctWord),
            wordsPerMinute: wordsPerMinute,
            rng: &rng
        )
    }

    private func typeCharacters<R: RandomNumberGenerator>(
        _ characters: [Character],
        wordsPerMinute: ClosedRange<Double>,
        rng: inout R
    ) async -> Bool {
        for character in characters {
            guard await waitWhilePaused(), !isCancelled else { return false }
            emitter.type(character)
            let delay = TypingPolicy.characterDelayNanoseconds(
                for: character,
                wordsPerMinute: wordsPerMinute,
                using: &rng
            )
            guard await sleep(delay) else { return false }
        }
        return true
    }

    private func paragraphPause(seconds: Int) async -> Bool {
        for remaining in stride(from: seconds, through: 1, by: -1) {
            guard await waitWhilePaused(), !isCancelled else { return false }
            onStateChange?(.paragraphPause(remaining))
            guard await sleep(1_000_000_000) else { return false }
        }
        onStateChange?(.typing)
        return true
    }

    private func waitWhilePaused() async -> Bool {
        while isPaused, !isCancelled {
            guard await sleep(100_000_000) else { return false }
        }
        return !isCancelled && !Task.isCancelled
    }

    private func sleep(_ nanoseconds: UInt64) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
            return !isCancelled && !Task.isCancelled
        } catch {
            return false
        }
    }

    private func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    private func endOfWord(in characters: [Character], startingAt start: Int) -> Int {
        var index = start
        while index < characters.count, isWordCharacter(characters[index]) {
            index += 1
        }
        return index
    }
}
