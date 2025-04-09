// MARK: - File: CalendarView.swift
// Purpose: Displays a smart calendar for tracking habit progress.

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var completions: [Completion] = []
    @State private var completionsForSelectedDay: [String]? = nil
    @StateObject private var viewModel = CalendarViewModel()
    
    struct Completion: Identifiable {
        let id = UUID()
        let date: Date
        let habit: Habit
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month selector
                HStack {
                    Button(action: { viewModel.previousMonth() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(ThemeColors.primaryAccent)
                    }
                    
                    Text(viewModel.currentMonthTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Button(action: { viewModel.nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(ThemeColors.primaryAccent)
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
                        CalendarDayView(day: day)
                            .onTapGesture {
                                viewModel.selectDay(day, context: viewContext)
                            }
                    }
                }
                .padding()
                
                // Selected day details
                if let selectedDay = viewModel.selectedDay {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedDay.date.formatted(date: .long, time: .omitted))
                            .font(.headline)
                            .foregroundColor(ThemeColors.primaryText)
                        
                        if let completions = viewModel.completionsForSelectedDay {
                            ForEach(completions, id: \.self) { completion in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(completion)
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                            }
                        } else {
                            Text("No completions on this day")
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                    }
                    .padding()
                    .background(ThemeColors.panelBackground.opacity(0.3))
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Progress Calendar")
        }
    }
}

struct CalendarDayView: View {
    let day: CalendarDay
    
    var body: some View {
        VStack {
            Text(day.number)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(day.isCurrentMonth ? ThemeColors.primaryText : ThemeColors.secondaryText)
            
            if day.hasCompletions {
                Circle()
                    .fill(ThemeColors.primaryAccent)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(day.isSelected ? ThemeColors.primaryAccent.opacity(0.2) : Color.clear)
        )
    }
}

class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDay: CalendarDay?
    @Published var completionsForSelectedDay: [String]? = nil
    
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
        let previousMonthDays = (daysInPreviousMonth - monthFirstWeekday + 2)...daysInPreviousMonth
        for day in previousMonthDays {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: previousMonth),
                                                        month: calendar.component(.month, from: previousMonth),
                                                        day: day))!
            days.append(CalendarDay(date: date, isCurrentMonth: false))
        }
        
        // Add days from current month
        for day in 1...daysInMonth {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: currentDate),
                                                        month: calendar.component(.month, from: currentDate),
                                                        day: day))!
            days.append(CalendarDay(date: date, isCurrentMonth: true))
        }
        
        // Add days from next month to complete the grid
        let remainingDays = 42 - days.count // 6 rows * 7 days
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        for day in 1...remainingDays {
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: nextMonth),
                                                        month: calendar.component(.month, from: nextMonth),
                                                        day: day))!
            days.append(CalendarDay(date: date, isCurrentMonth: false))
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
        selectedDay = day
        loadCompletions(for: day.date, context: context)
    }
    
    private func loadCompletions(for date: Date, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completionDate >= %@ AND completionDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let logs = try context.fetch(fetchRequest)
            let habitIDs = logs.compactMap { $0.habitID }
            
            let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            habitFetchRequest.predicate = NSPredicate(format: "id IN %@", habitIDs)
            
            let habits = try context.fetch(habitFetchRequest)
            completionsForSelectedDay = habits.map { habit in
                habit.name ?? "Unknown Habit"
            }
        } catch {
            print("Error loading completions: \(error)")
            completionsForSelectedDay = nil
        }
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    var isSelected: Bool = false
    var hasCompletions: Bool = false
    
    var number: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
} 