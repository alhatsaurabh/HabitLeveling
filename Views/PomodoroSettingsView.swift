// MARK: - File: PomodoroSettingsView.swift
// Purpose: Settings interface for customizing Pomodoro timer parameters
// Dependencies: PomodoroViewModel, ThemeColors

import SwiftUI

struct PomodoroSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var pomodoroViewModel: PomodoroViewModel
    
    // Local state for editing
    @State private var workDuration: Double
    @State private var shortBreakDuration: Double
    @State private var longBreakDuration: Double
    @State private var sessionsUntilLongBreak: Double
    @State private var autoStartBreaks: Bool
    @State private var autoStartFocus: Bool
    
    // Initialize with current values from the viewModel
    init(pomodoroViewModel: PomodoroViewModel) {
        self.pomodoroViewModel = pomodoroViewModel
        
        // Convert minutes to local state
        _workDuration = State(initialValue: Double(pomodoroViewModel.workDuration / 60))
        _shortBreakDuration = State(initialValue: Double(pomodoroViewModel.shortBreakDuration / 60))
        _longBreakDuration = State(initialValue: Double(pomodoroViewModel.longBreakDuration / 60))
        _sessionsUntilLongBreak = State(initialValue: Double(pomodoroViewModel.sessionsUntilLongBreak))
        _autoStartBreaks = State(initialValue: pomodoroViewModel.autoStartBreaks)
        _autoStartFocus = State(initialValue: pomodoroViewModel.autoStartFocus)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Focus Duration
                        SettingsSlider(
                            value: $workDuration,
                            range: 1...60,
                            step: 1,
                            title: "Focus Duration",
                            subtitle: "Duration of each focus session",
                            valueLabel: formatDuration(workDuration),
                            iconName: "timer"
                        )
                        
                        // Short Break Duration
                        SettingsSlider(
                            value: $shortBreakDuration,
                            range: 1...20,
                            step: 1,
                            title: "Short Break",
                            subtitle: "Duration of regular breaks",
                            valueLabel: formatDuration(shortBreakDuration),
                            iconName: "cup.and.saucer"
                        )
                        
                        // Long Break Duration
                        SettingsSlider(
                            value: $longBreakDuration,
                            range: 5...30,
                            step: 1,
                            title: "Long Break",
                            subtitle: "Duration of extended breaks",
                            valueLabel: formatDuration(longBreakDuration),
                            iconName: "figure.walk"
                        )
                        
                        // Sessions Until Long Break
                        SettingsSlider(
                            value: $sessionsUntilLongBreak,
                            range: 2...6,
                            step: 1,
                            title: "Sessions Until Long Break",
                            subtitle: "Number of focus sessions before a long break",
                            valueLabel: "\(Int(sessionsUntilLongBreak))",
                            iconName: "repeat.circle"
                        )
                        
                        // Toggle switches
                        VStack(spacing: 12) {
                            SettingsToggle(
                                isOn: $autoStartBreaks,
                                title: "Auto-start breaks",
                                subtitle: "Automatically start breaks after focus sessions",
                                iconName: "arrow.triangle.2.circlepath"
                            )
                            
                            SettingsToggle(
                                isOn: $autoStartFocus,
                                title: "Auto-start focus",
                                subtitle: "Automatically start focus after breaks",
                                iconName: "arrow.triangle.2.circlepath.circle"
                            )
                        }
                        .padding()
                        .background(ThemeColors.panelBackground.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Reset to Defaults button
                        Button(action: resetToDefaults) {
                            Text("Reset to Defaults")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(ThemeColors.warning.opacity(0.2))
                                )
                                .foregroundColor(ThemeColors.warning)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeColors.primaryAccent)
                }
            }
        }
    }
    
    private func formatDuration(_ minutes: Double) -> String {
        let integer = Int(minutes)
        return integer == 1 ? "1 min" : "\(integer) mins"
    }
    
    private func saveSettings() {
        // Convert minutes back to seconds for the view model
        pomodoroViewModel.workDuration = Double(Int(workDuration) * 60)
        pomodoroViewModel.shortBreakDuration = Double(Int(shortBreakDuration) * 60)
        pomodoroViewModel.longBreakDuration = Double(Int(longBreakDuration) * 60)
        pomodoroViewModel.sessionsUntilLongBreak = Int(sessionsUntilLongBreak)
        pomodoroViewModel.autoStartBreaks = autoStartBreaks
        pomodoroViewModel.autoStartFocus = autoStartFocus
        
        // Save settings to user defaults
        pomodoroViewModel.saveSettings()
        
        // Reset the current timer with new settings
        pomodoroViewModel.resetTimer()
    }
    
    private func resetToDefaults() {
        workDuration = 25 // Default 25 minutes
        shortBreakDuration = 5 // Default 5 minutes
        longBreakDuration = 15 // Default 15 minutes
        sessionsUntilLongBreak = 4 // Default 4 sessions
        autoStartBreaks = true
        autoStartFocus = false
    }
}

// MARK: - Helper Views

struct SettingsSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let title: String
    let subtitle: String
    let valueLabel: String
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(ThemeColors.primaryAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                Text(valueLabel)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeColors.primaryAccent)
                    .frame(width: 60, alignment: .trailing)
            }
            
            HStack {
                Text(formatValueLabel(range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(ThemeColors.secondaryText)
                
                Slider(value: $value, in: range, step: step)
                    .accentColor(ThemeColors.primaryAccent)
                
                Text(formatValueLabel(range.upperBound))
                    .font(.caption2)
                    .foregroundColor(ThemeColors.secondaryText)
            }
        }
        .padding()
        .background(ThemeColors.panelBackground.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatValueLabel(_ value: Double) -> String {
        if title.contains("Sessions") {
            return "\(Int(value))"
        } else {
            return "\(Int(value))"
        }
    }
}

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String
    let iconName: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(ThemeColors.primaryAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ThemeColors.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: ThemeColors.primaryAccent))
        }
    }
}

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView(pomodoroViewModel: PomodoroViewModel())
            .preferredColorScheme(.dark)
    }
} 