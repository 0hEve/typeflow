import AppKit
import SwiftUI

struct MenuContentView: View {
    private enum Panel: String, CaseIterable, Identifiable {
        case text = "Text"
        case settings = "Settings"

        var id: Self { self }
    }

    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPanel = Panel.text

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            panelPicker

            switch selectedPanel {
            case .text:
                textPanel
            case .settings:
                SettingsView(preferences: model.preferences)
            }

            footer
        }
        .padding(16)
        .frame(width: 420)
        .onAppear {
            model.refreshAccessibility()
            model.menuDidOpen()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                model.refreshAccessibility(announce: false)
            }
        }
    }

    private var panelPicker: some View {
        Picker("TypeFlow panel", selection: $selectedPanel) {
            Label("Text", systemImage: "text.alignleft")
                .tag(Panel.text)
            Label("Settings", systemImage: "gearshape")
                .tag(Panel.settings)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            editor
            progress

            if !model.accessibilityGranted {
                permissionCard
            }

            controls
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: model.state.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("TypeFlow")
                    .font(.headline)
                Text(model.state.title)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("⌃⌥⌘T")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
                .accessibilityLabel("Global hotkey: Control Option Command T")
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Text to type")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(model.draft.count) characters")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.draft)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .disabled(!model.canEdit)
                    .accessibilityLabel("Text to type")

                if model.draft.isEmpty {
                    Text("Paste your text here…")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 150, maxHeight: 190)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            .opacity(model.canEdit ? 1 : 0.72)
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: model.progress)
                .accessibilityLabel("Typing progress")
                .accessibilityValue("\(Int(model.progress * 100)) percent")
            Text(model.notice)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Status: \(model.notice)")
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Accessibility access is required to send keystrokes.", systemImage: "hand.raised.fill")
                .font(.caption.weight(.semibold))
            Text("After an update, remove the old TypeFlow entry and add this copy again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Grant access") {
                    model.requestAccessibility()
                }
                Button("Check again") {
                    model.refreshAccessibility()
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var controls: some View {
        HStack(spacing: 9) {
            Button(primaryTitle) {
                let shouldDismiss = model.state == .idle || model.state == .completed || model.state == .paused
                model.primaryActionFromMenu()
                if shouldDismiss {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])

            Button("Stop and reset") {
                model.reset()
            }
            .controlSize(.large)
            .disabled(model.state == .idle && model.completedCharacters == 0)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit TypeFlow") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .accessibilityLabel("Quit TypeFlow")
        }
    }

    private var primaryTitle: String {
        switch model.state {
        case .idle, .completed: "Start in 3 seconds"
        case .countdown: "Cancel start"
        case .typing, .paragraphPause: "Pause"
        case .paused: "Resume in 3 seconds"
        }
    }

    private var statusColor: Color {
        switch model.state {
        case .typing: .green
        case .paused, .paragraphPause, .countdown: .orange
        case .completed: .blue
        case .idle: .secondary
        }
    }
}
