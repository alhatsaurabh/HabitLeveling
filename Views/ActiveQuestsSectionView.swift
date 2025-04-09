// MARK: - File: ActiveQuestsSectionView.swift
// Purpose: Displays the list of active habits/quests on the Dashboard.
// Dependencies: DashboardViewModel, ThemeColors, Habit CoreData Entity
// Update: Optimized layout for better vertical space utilization.

import SwiftUI
import CoreData

struct ActiveQuestsSectionView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onAddTapped: () -> Void
    @Binding var habitToEdit: Habit?
    
    @State private var selectedCategory: StatCategory? // nil represents "All"
    
    private var filteredHabits: [Habit] {
        guard let selectedCategory = selectedCategory else { 
            // Return all habits sorted by creation date, newest first
            return Array(viewModel.activeHabits).sorted { 
                ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
            }
        }
        // Filter by category and sort by creation date, newest first
        return viewModel.activeHabits.filter { habit in
            guard let habitCategory = habit.statCategory else { return false }
            return habitCategory == selectedCategory.rawValue
        }.sorted {
            ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Add button
            HStack {
                Text("Active Quests")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeColors.secondaryText)
                Spacer()
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(ThemeColors.primaryAccent)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        label: "All",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(StatCategory.allCases) { category in
                        FilterButton(
                            label: category.rawValue,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(ThemeColors.panelBackground.opacity(0.2))
            
            // Habits List
            if filteredHabits.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredHabits) { habit in
                        HabitRowView(habit: habit, onComplete: { completedHabit in
                            viewModel.completeHabit(habit: completedHabit)
                        })
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading) {
                            Button {
                                habitToEdit = habit
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(ThemeColors.secondaryAccent)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "scroll")
                .font(.system(size: 40))
                .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
            Text("No active quests")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
            Text("Tap '+' to add your first quest")
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct FilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : ThemeColors.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? ThemeColors.primaryAccent : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : ThemeColors.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct ActiveQuestsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveQuestsSectionView(
            viewModel: DashboardViewModel(),
            onAddTapped: { print("Add tapped") },
            habitToEdit: .constant(nil)
        )
        .padding()
        .background(ThemeColors.background)
        .preferredColorScheme(.dark)
    }
}
