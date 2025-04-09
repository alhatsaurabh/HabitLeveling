// MARK: - File: AddEditHabitSubviews.swift
// Purpose: Contains subview definitions used by AddEditHabitView.

import SwiftUI

// MARK: - Assumptions for Compilation
// Ensure these are accessible globally or imported:
// - ThemeColors struct
// - StatCategory enum
// - AddEditHabitView.Field enum (or pass FocusState binding differently)
// - ViewModifiers defined in ViewModifiers.swift (inputLabelStyle, inputFieldStyle)

// MARK: - Subview Definitions

struct StatCategoryPicker: View {
    @Binding var selection: StatCategory
    let themeAccentColor = ThemeColors.primaryAccent
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Stat Category").inputLabelStyle() // Assumes modifier exists
            Picker("Stat Category", selection: $selection) {
                ForEach(StatCategory.allCases) { category in Text(category.rawValue).tag(category) }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(ThemeColors.panelBackground.opacity(0.5)) // Use ThemeColors
            .cornerRadius(8)
            .tint(themeAccentColor)
        }
    }
}

struct QuestTitleInput: View {
    @Binding var name: String
    var focusedField: FocusState<AddEditHabitView.Field?>.Binding // Use correct FocusState type
    let themeAccentColor = ThemeColors.primaryAccent
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Quest Title").inputLabelStyle() // Assumes modifier exists
            TextField("E.g., Morning Meditation", text: $name)
                .inputFieldStyle(isFocused: focusedField.wrappedValue == .title, accentColor: themeAccentColor) // Assumes modifier exists
                .focused(focusedField, equals: .title)
                .submitLabel(.next) // Suggest next field
        }
    }
}

struct DescriptionInput: View {
     @Binding var description: String
     var focusedField: FocusState<AddEditHabitView.Field?>.Binding // Use correct FocusState type
     let themeAccentColor = ThemeColors.primaryAccent
     var body: some View {
         VStack(alignment: .leading, spacing: 5) {
             Text("Description (Optional)").inputLabelStyle() // Assumes modifier exists
             TextEditor(text: $description)
                 .frame(height: 100)
                 .inputFieldStyle(isFocused: focusedField.wrappedValue == .description, accentColor: themeAccentColor) // Assumes modifier exists
                 .focused(focusedField, equals: .description)
                 // Rely on global keyboard toolbar in AddEditHabitView
         }
     }
}

struct XPInput: View {
     @Binding var xpValue: Int
     var focusedField: FocusState<AddEditHabitView.Field?>.Binding // Use correct FocusState type
     let themeAccentColor = ThemeColors.primaryAccent
     var body: some View {
         VStack(alignment: .leading, spacing: 5) {
             Text("XP Reward").inputLabelStyle() // Assumes modifier exists
             TextField("XP Value", value: $xpValue, format: .number)
                 .inputFieldStyle(isFocused: focusedField.wrappedValue == .xp, accentColor: themeAccentColor) // Assumes modifier exists
                 .keyboardType(.numberPad)
                 .focused(focusedField, equals: .xp)
                 // Rely on global keyboard toolbar in AddEditHabitView
             Text("XP earned on completion").font(.caption).foregroundColor(ThemeColors.secondaryText)
         }
     }
}

struct FrequencyPicker: View {
     @Binding var selection: String
     let frequencies: [String]
     var body: some View {
         VStack(alignment: .leading, spacing: 5) {
             Text("Frequency").inputLabelStyle() // Assumes modifier exists
             Picker("Frequency", selection: $selection) {
                 ForEach(frequencies, id: \.self) { Text($0).tag($0) }
             }.pickerStyle(.segmented)
         }
     }
}

struct ReminderSection: View {
     @Binding var notificationsEnabled: Bool
     @Binding var selectedTime: Date
     @Binding var notificationTime: Date?
     let themeAccentColor = ThemeColors.primaryAccent
     var body: some View {
         VStack(alignment: .leading, spacing: 10) {
             Text("Reminder").inputLabelStyle() // Assumes modifier exists
             Toggle("Set Reminder Time", isOn: $notificationsEnabled)
                 .tint(themeAccentColor)
                 .padding(.horizontal, 10).padding(.vertical, 8)
                 .background(ThemeColors.panelBackground.opacity(0.5)).cornerRadius(8) // Use ThemeColors
                 .onChange(of: notificationsEnabled) { _ , enabled in // Updated onChange syntax
                    if enabled { notificationTime = selectedTime } else { notificationTime = nil }
                 }
             if notificationsEnabled {
                 DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                     .datePickerStyle(.graphical).labelsHidden().frame(maxWidth: .infinity, alignment: .center)
                     .padding(10).background(ThemeColors.panelBackground.opacity(0.5)).cornerRadius(8) // Use ThemeColors
                     .onChange(of: selectedTime) { _ , newTime in // Updated onChange syntax
                        if notificationsEnabled { notificationTime = newTime }
                     }
             }
         }
     }
}

struct MakeItEasyToggle: View {
     @Binding var isTwoMinuteVersion: Bool
     let themeAccentColor = ThemeColors.primaryAccent
     var body: some View {
         VStack(alignment: .leading, spacing: 5) {
             Text("Make it Easy (Atomic Habits)").inputLabelStyle() // Assumes modifier exists
             Toggle("Start with 2-Minute Version?", isOn: $isTwoMinuteVersion)
                 .tint(themeAccentColor)
                 .padding(.horizontal, 10).padding(.vertical, 8)
                 .background(ThemeColors.panelBackground.opacity(0.5)).cornerRadius(8) // Use ThemeColors
         }
     }
}

// Add other subviews like CueInput here if needed
/*
 struct CueInput: View {
     @Binding var cue: String
     var focusedField: FocusState<AddEditHabitView.Field?>.Binding
     let themeAccentColor = ThemeColors.primaryAccent
     var body: some View {
         VStack(alignment: .leading, spacing: 5) {
             Text("Cue/Trigger (Optional)").inputLabelStyle()
             TextField("E.g., After waking up", text: $cue)
                 .inputFieldStyle(isFocused: focusedField.wrappedValue == .cue, accentColor: themeAccentColor)
                 .focused(focusedField, equals: .cue)
                 .submitLabel(.next)
             Text("What triggers this habit?").font(.caption).foregroundColor(ThemeColors.secondaryText)
         }
     }
 }
 */
