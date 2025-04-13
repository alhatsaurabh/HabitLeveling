// MARK: - File: CalendarView.swift
// Purpose: Displays a smart calendar for tracking habit progress with heat map visualization.
// Update: Added close button for modal presentation

import SwiftUI
import CoreData

// MARK: - CalendarViewModel
class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDay: CalendarDay?
    @Published var completionsForSelectedDay: [String]? = nil
    @Published var allCompletions: [Date: [String]] = [:]
    @Published var maxCompletionsPerDay: Int = 1 // For heat map intensity calculation
    @Published var totalCompletions: Int = 0
    @Published var mostActiveDay: (String, String) = ("0", "Day") // (count, day name)
    
    private var calendar = Calendar.current
    
    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    var weekdaySymbols: [String] {
        calendar.veryShortWeekdaySymbols
    }
    
    var days: [CalendarDay] {
        let monthInterval = calendar.dateInterval(of: .month, for: currentDate)!
        let monthFirstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)!.count
        
        var days: [CalendarDay] = []
        
        // Add days from previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
        var previousMonthStartDay = daysInPreviousMonth - monthFirstWeekday + 2
        if previousMonthStartDay > daysInPreviousMonth {
            previousMonthStartDay = previousMonthStartDay - 7
        }
        
        for day in previousMonthStartDay...daysInPreviousMonth {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: previousMonth),
                                                        month: calendar.component(.month, from: previousMonth),
                                                        day: day))!
            days.append(CalendarDay(
                date: date,
                isCurrentMonth: false,
                isToday: calendar.isDateInToday(date)
            ))
        }
        
        // Add days from current month
        for day in 1...daysInMonth {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: currentDate),
                                                        month: calendar.component(.month, from: currentDate),
                                                        day: day))!
            days.append(CalendarDay(
                date: date,
                isCurrentMonth: true,
                isToday: calendar.isDateInToday(date),
                isSelected: selectedDay?.date != nil && calendar.isDate(date, inSameDayAs: selectedDay!.date)
            ))
        }
        
        // Add days from next month to complete the grid
        let remainingDays = 42 - days.count // 6 rows * 7 days
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        for day in 1...remainingDays {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: nextMonth),
                                                        month: calendar.component(.month, from: nextMonth),
                                                        day: day))!
            days.append(CalendarDay(
                date: date,
                isCurrentMonth: false,
                isToday: calendar.isDateInToday(date)
            ))
        }
        
        return days
    }
    
    func previousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
    }
    
    func nextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
    }
    
    func selectDay(_ day: CalendarDay, context: NSManagedObjectContext) {
        // Update selected day
        if let selectedDay = selectedDay, calendar.isDate(selectedDay.date, inSameDayAs: day.date) {
            self.selectedDay = nil
            self.completionsForSelectedDay = nil
        } else {
            self.selectedDay = day
        loadCompletions(for: day.date, context: context)
        }
    }
    
    func loadAllCompletions(context: NSManagedObjectContext) {
        allCompletions = [:]
        
        let fetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        
        do {
            let logs = try context.fetch(fetchRequest)
            var dateCompletions: [Date: [String]] = [:]
            var dateCount: [Date: Int] = [:]
            var totalCount = 0
            
            for log in logs {
                guard let completionDate = log.completionDate, let habitID = log.habitID else { continue }
                
                // Get the start of day for the completion date
                let startOfDay = calendar.startOfDay(for: completionDate)
                
                // Fetch habit name
                let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                habitFetchRequest.predicate = NSPredicate(format: "id == %@", habitID as CVarArg)
                habitFetchRequest.fetchLimit = 1
                
                if let habits = try? context.fetch(habitFetchRequest), let habit = habits.first, let habitName = habit.name {
                    // Add to date completions
                    if var completions = dateCompletions[startOfDay] {
                        completions.append(habitName)
                        dateCompletions[startOfDay] = completions
                    } else {
                        dateCompletions[startOfDay] = [habitName]
                    }
                    
                    // Update count
                    dateCount[startOfDay] = (dateCount[startOfDay] ?? 0) + 1
                    totalCount += 1
                }
            }
            
            // Find max completions per day
            let maxCompletions = dateCount.values.max() ?? 1
            self.maxCompletionsPerDay = max(maxCompletions, 1) // Avoid division by zero
            
            // Find most active day
            if let (mostActiveDate, count) = dateCount.max(by: { $0.value < $1.value }) {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let dayName = formatter.string(from: mostActiveDate)
                self.mostActiveDay = ("\(count)", dayName)
            } else {
                self.mostActiveDay = ("0", "None")
            }
            
            self.allCompletions = dateCompletions
            self.totalCompletions = totalCount
            
        } catch {
            print("Error loading all completions: \(error)")
        }
    }
    
    func updateCompletions(for category: String?, context: NSManagedObjectContext) {
        loadAllCompletions(context: context)
        if let selectedDay = selectedDay {
            loadCompletions(for: selectedDay.date, context: context, category: category)
        }
    }
    
    private func loadCompletions(for date: Date, context: NSManagedObjectContext, category: String? = nil) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completionDate >= %@ AND completionDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let logs = try context.fetch(fetchRequest)
            let habitIDs = logs.compactMap { $0.habitID }
            
            var habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            
            if let category = category {
                habitFetchRequest.predicate = NSPredicate(format: "id IN %@ AND statCategory == %@", habitIDs, category)
            } else {
            habitFetchRequest.predicate = NSPredicate(format: "id IN %@", habitIDs)
            }
            
            let habits = try context.fetch(habitFetchRequest)
            completionsForSelectedDay = habits.map { habit in
                habit.name ?? "Unknown Habit"
            }
        } catch {
            print("Error loading completions: \(error)")
            completionsForSelectedDay = nil
        }
    }
    
    func completionIntensity(for date: Date) -> Double {
        let startOfDay = calendar.startOfDay(for: date)
        
        if let completions = allCompletions[startOfDay], !completions.isEmpty {
            return Double(completions.count) / Double(maxCompletionsPerDay)
        }
        return 0.0
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedCategory: StatCategory? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ThemeColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                                viewModel.updateCompletions(for: nil, context: viewContext)
                            }
                            
                            ForEach(StatCategory.allCases) { category in
                                CategoryButton(title: category.rawValue, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                    viewModel.updateCompletions(for: category.rawValue, context: viewContext)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(ThemeColors.panelBackground.opacity(0.3))
                    
                    // Month selector
                    HStack {
                        Button(action: { viewModel.previousMonth() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(ThemeColors.primaryAccent)
                                .font(.title3)
                                .padding(10)
                                .background(Circle().fill(ThemeColors.panelBackground.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        Text(viewModel.currentMonthTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: { viewModel.nextMonth() }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(ThemeColors.primaryAccent)
                                .font(.title3)
                                .padding(10)
                                .background(Circle().fill(ThemeColors.panelBackground.opacity(0.5)))
                        }
                    }
                    .padding()
                    
                    // Weekday headers
                    HStack {
                        ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeColors.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(viewModel.days) { day in
                            CalendarDayView(day: day, completionIntensity: viewModel.completionIntensity(for: day.date))
                                .onTapGesture {
                                    viewModel.selectDay(day, context: viewContext)
                                }
                        }
                    }
                    .padding()
                    
                    // Stats section
                    HStack {
                        VStack(alignment: .center) {
                            Text("\(viewModel.totalCompletions)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeColors.primaryText)
                            Text("Completions")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                            .background(ThemeColors.secondaryText.opacity(0.3))
                        
                        VStack(alignment: .center) {
                            Text("\(viewModel.mostActiveDay.0)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeColors.primaryText)
                            Text("\(viewModel.mostActiveDay.1)")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(ThemeColors.panelBackground.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Selected day details
                    if let selectedDay = viewModel.selectedDay {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedDay.date.formatted(date: .long, time: .omitted))
                                    .font(.headline)
                                    .foregroundColor(ThemeColors.primaryText)
                                
                                Spacer()
                                
                                Text("\(viewModel.completionsForSelectedDay?.count ?? 0) completions")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            
                            if let completions = viewModel.completionsForSelectedDay, !completions.isEmpty {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(completions, id: \.self) { completion in
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text(completion)
                                                    .foregroundColor(ThemeColors.secondaryText)
                                                
                                                Spacer()
                                                
                                                Image(systemName: categoryIcon(for: completion))
                                                    .foregroundColor(categoryColor(for: completion))
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200) // Limit the height of the scrollable area
                            } else {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(ThemeColors.secondaryText)
                                    Text("No completions on this day")
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(ThemeColors.panelBackground.opacity(0.3))
                        .cornerRadius(12)
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Progress Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ThemeColors.secondaryText)
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                viewModel.loadAllCompletions(context: viewContext)
            }
        }
    }
    
    // Helper function to get icon for habit category
    private func categoryIcon(for habitName: String) -> String {
        // This is a simplified approach - ideally we would have the category information directly
        if habitName.lowercased().contains("exercise") || habitName.lowercased().contains("workout") {
            return "figure.walk"
        } else if habitName.lowercased().contains("read") || habitName.lowercased().contains("study") {
            return "book.fill"
        } else if habitName.lowercased().contains("meditate") {
            return "brain.head.profile"
        }
        return "sparkles"
    }
    
    // Helper function to get color for habit category
    private func categoryColor(for habitName: String) -> Color {
        // This is a simplified approach - ideally we would have the category information directly
        if habitName.lowercased().contains("exercise") || habitName.lowercased().contains("workout") {
            return .orange
        } else if habitName.lowercased().contains("read") || habitName.lowercased().contains("study") {
            return .blue
        } else if habitName.lowercased().contains("meditate") {
            return .purple
        }
        return .green
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? ThemeColors.primaryAccent : ThemeColors.panelBackground)
                )
                .foregroundColor(isSelected ? .white : ThemeColors.secondaryText)
        }
    }
}

struct CalendarDayView: View {
    let day: CalendarDay
    let completionIntensity: Double // 0.0 to 1.0
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    day.isToday ? ThemeColors.secondaryAccent.opacity(0.3) :
                    !day.isCurrentMonth ? ThemeColors.panelBackground.opacity(0.3) : Color.clear
                )
            
            // Heat map background
            if completionIntensity > 0 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(heatMapColor(for: completionIntensity))
            }
            
            // Day content
            VStack {
                Text(day.number)
                    .font(.system(size: 16, weight: day.isToday ? .bold : .medium))
                    .foregroundColor(dayTextColor())
            }
        }
        .frame(height: 40)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(day.isSelected ? ThemeColors.primaryAccent : Color.clear, lineWidth: 2)
        )
    }
    
    // Helper function to determine text color based on state
    private func dayTextColor() -> Color {
        if day.isToday {
            return ThemeColors.primaryText
        } else if !day.isCurrentMonth {
            return ThemeColors.secondaryText.opacity(0.5)
        } else {
            return ThemeColors.primaryText
        }
    }
    
    // Helper function to get heat map color based on intensity
    private func heatMapColor(for intensity: Double) -> Color {
        if intensity <= 0 {
            return Color.clear
        } else if intensity < 0.25 {
            return Color.green.opacity(0.2)
        } else if intensity < 0.5 {
            return Color.green.opacity(0.4)
        } else if intensity < 0.75 {
            return Color.green.opacity(0.6)
        } else {
            return Color.green.opacity(0.8)
        }
    }
} 