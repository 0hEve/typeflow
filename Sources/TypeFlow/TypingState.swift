import Foundation

enum TypingState: Equatable {
    case idle
    case countdown(Int)
    case typing
    case paused
    case paragraphPause(Int)
    case completed

    var title: String {
        switch self {
        case .idle: "Ready"
        case .countdown(let seconds): "Starting in \(seconds)s"
        case .typing: "Typing"
        case .paused: "Paused"
        case .paragraphPause(let seconds): "Paragraph pause · \(seconds)s"
        case .completed: "Finished"
        }
    }

    var symbol: String {
        switch self {
        case .idle: "keyboard"
        case .countdown: "timer"
        case .typing: "keyboard.fill"
        case .paused: "pause.circle.fill"
        case .paragraphPause: "hourglass"
        case .completed: "checkmark.circle.fill"
        }
    }

    var isActivelyTyping: Bool {
        switch self {
        case .typing, .paragraphPause: true
        default: false
        }
    }
}
