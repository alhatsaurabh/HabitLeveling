// --- Habit Row View (HabitRowView.swift) ---
// Reusable view for displaying a single habit, especially on the dashboard.
struct HabitRowView: View {
    // Use @ObservedObject for objects passed into the view
    @ObservedObject var habit: Habit
    var onComplete: (Habit) -> Void // Closure to call when checkmark is tapped

    // State to manage completion visual feedback (optional)
    @State private var recentlyCompleted = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.name ?? "Unnamed Habit")
                    .font(.headline)
                    // Basic visual cue for completed state
                    .strikethrough(recentlyCompleted, color: .gray)
                    .opacity(recentlyCompleted ? 0.6 : 1.0)

                // Add more details if needed (e.g., category, XP)
                Text("XP: \(habit.xpValue) | Streak: \(habit.streak)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer() // Pushes checkmark to the right

            Image(systemName: recentlyCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(recentlyCompleted ? .green : .cyan) // Use theme color
                .imageScale(.large)
                .onTapGesture {
                    if !recentlyCompleted { // Prevent multiple completions visually
                        onComplete(habit)
                        // Provide immediate visual feedback
                        withAnimation(.easeOut(duration: 0.2)) {
                             recentlyCompleted = true
                        }
                         // Optional: Reset visual state after a delay if needed for daily reset
                         // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                         //     withAnimation { recentlyCompleted = false }
                         // }
                    }
                }
        }
         // Apply padding within the row
        .padding(.vertical, 4)
        // Basic styling for the row
        .background(Color.black.opacity(0.01)) // Ensure taps are registered
    }
}

