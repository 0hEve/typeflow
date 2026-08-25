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
            summary: "Uses the range as the average base pace and varies every keystroke."
        ) {
            stepperRow(
                "Minimum",
                value: Binding(
                    get: { preferences.minimumWPM },
                    set: preferences.setMinimumWPM
                ),
                suffix: "WPM"
            )
            stepperRow(
                "Maximum",
                value: Binding(
                    get: { preferences.maximumWPM },
                    set: preferences.setMaximumWPM
                ),
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
                    value: Binding(
                        get: { preferences.correctionMinimumWords },
                        set: preferences.setCorrectionMinimum
                    ),
                    suffix: "words"
                )
                stepperRow(
                    "Maximum words between",
                    value: Binding(
                        get: { preferences.correctionMaximumWords },
                        set: preferences.setCorrectionMaximum
                    ),
                    suffix: "words"
                )
                stepperRow(
                    "Second mistake chance",
                    value: Binding(
                        get: { preferences.repeatedMistakeChance },
                        set: preferences.setRepeatedMistakeChance
                    ),
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
                        value: Binding(
                            get: { preferences.paragraphMinimumSeconds },
                            set: preferences.setParagraphMinimum
                        ),
                        suffix: "seconds"
                    )
                    stepperRow(
                        "Maximum pause",
                        value: Binding(
                            get: { preferences.paragraphMaximumSeconds },
                            set: preferences.setParagraphMaximum
                        ),
                        suffix: "seconds"
                    )
                case .fixed:
                    stepperRow(
                        "Pause length",
                        value: Binding(
                            get: { preferences.paragraphFixedSeconds },
                            set: preferences.setParagraphFixed
                        ),
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
        step: Int = 1,
        suffix: String
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
            Spacer()
            NumericSettingField(title: title, value: value)
            Text(suffix)
                .foregroundStyle(.secondary)
            Stepper(title, value: value, step: step)
                .labelsHidden()
                .accessibilityLabel("\(title), \(value.wrappedValue) \(suffix)")
        }
        .font(.subheadline)
    }
}

private struct NumericSettingField: View {
    let title: String
    @Binding var value: Int

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(title: String, value: Binding<Int>) {
        self.title = title
        _value = value
        _draft = State(initialValue: String(value.wrappedValue))
    }

    var body: some View {
        TextField(title, text: $draft)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 72)
            .focused($isFocused)
            .accessibilityLabel(title)
            .onSubmit(commit)
            .onChange(of: isFocused) { focused in
                if !focused {
                    commit()
                }
            }
            .onChange(of: value) { newValue in
                if !isFocused {
                    draft = String(newValue)
                }
            }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(trimmed) else {
            draft = String(value)
            return
        }

        value = parsed
        draft = String(value)
    }
}
