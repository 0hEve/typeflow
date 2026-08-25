import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: TypingPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                speedSection
                correctionsSection
                paragraphSection

                HStack {
                    Button("Restore defaults") {
                        preferences.restoreDefaults()
                    }
                    Spacer()
                    Text("Changes apply to the next run.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxHeight: 420)
    }

    private var speedSection: some View {
        settingsSection(
            title: "Typing speed",
            systemImage: "speedometer",
            summary: "Targets a varying pace within the selected range."
        ) {
            stepperRow(
                "Minimum",
                value: $preferences.minimumWPM,
                range: 20...max(20, preferences.maximumWPM - 5),
                suffix: "WPM"
            )
            stepperRow(
                "Maximum",
                value: $preferences.maximumWPM,
                range: min(120, preferences.minimumWPM + 5)...120,
                suffix: "WPM"
            )
        }
    }

    private var correctionsSection: some View {
        settingsSection(
            title: "Corrections",
            systemImage: "delete.backward",
            summary: "Uses nearby US QWERTY keys, duplication, or transposition."
        ) {
            Toggle("Add natural corrections", isOn: $preferences.naturalCorrections)

            if preferences.naturalCorrections {
                stepperRow(
                    "Minimum words between",
                    value: $preferences.correctionMinimumWords,
                    range: 1...max(1, preferences.correctionMaximumWords - 1),
                    suffix: "words"
                )
                stepperRow(
                    "Maximum words between",
                    value: $preferences.correctionMaximumWords,
                    range: min(50, preferences.correctionMinimumWords + 1)...50,
                    suffix: "words"
                )
                stepperRow(
                    "Second mistake chance",
                    value: $preferences.repeatedMistakeChance,
                    range: 0...100,
                    step: 5,
                    suffix: "%"
                )
            }
        }
    }

    private var paragraphSection: some View {
        settingsSection(
            title: "Paragraph pauses",
            systemImage: "text.append",
            summary: "A blank line marks the end of a paragraph."
        ) {
            Toggle("Pause between paragraphs", isOn: $preferences.paragraphPauses)

            if preferences.paragraphPauses {
                Picker("Pause timing", selection: $preferences.paragraphPauseMode) {
                    ForEach(ParagraphPauseMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch preferences.paragraphPauseMode {
                case .range:
                    stepperRow(
                        "Minimum pause",
                        value: $preferences.paragraphMinimumSeconds,
                        range: 1...max(1, preferences.paragraphMaximumSeconds - 1),
                        suffix: "seconds"
                    )
                    stepperRow(
                        "Maximum pause",
                        value: $preferences.paragraphMaximumSeconds,
                        range: min(180, preferences.paragraphMinimumSeconds + 1)...180,
                        suffix: "seconds"
                    )
                case .fixed:
                    stepperRow(
                        "Pause length",
                        value: $preferences.paragraphFixedSeconds,
                        range: 1...180,
                        suffix: "seconds"
                    )
                }
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        systemImage: String,
        summary: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }

    private func stepperRow(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        suffix: String
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
            Spacer()
            Text("\(value.wrappedValue) \(suffix)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Stepper(title, value: value, in: range, step: step)
                .labelsHidden()
                .accessibilityLabel("\(title), \(value.wrappedValue) \(suffix)")
        }
        .font(.subheadline)
    }
}
