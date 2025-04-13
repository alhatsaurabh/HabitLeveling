import Foundation

public struct CalendarDay: Identifiable {
    public let id = UUID()
    public let date: Date
    public let isCurrentMonth: Bool
    public let isToday: Bool
    public let isSelected: Bool
    
    public var number: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    public init(date: Date, isCurrentMonth: Bool, isToday: Bool, isSelected: Bool = false) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.isSelected = isSelected
    }
} 