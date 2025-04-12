import Foundation

struct CalendarDay: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    var isSelected: Bool = false
    
    init(date: Date, isCurrentMonth: Bool, isToday: Bool, isSelected: Bool = false) {
        self.id = UUID()
        self.date = date
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.isSelected = isSelected
    }
    
    var number: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.id == rhs.id
    }
} 