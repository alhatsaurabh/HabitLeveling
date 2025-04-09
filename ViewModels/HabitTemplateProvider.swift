// MARK: - File: HabitTemplateProvider.swift
// Purpose: Provides a static list of predefined habit templates.

import Foundation

struct HabitTemplateProvider {

    // Static list of predefined habit templates
    static let templates: [HabitTemplate] = [
        HabitTemplate(
            name: "Morning Exercise",
            description: "Engage in physical activity for at least 15 minutes.",
            category: .body,
            xpValue: 15,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Read a Book Chapter",
            description: "Read at least one chapter of a book.",
            category: .mind,
            xpValue: 10,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Meditate",
            description: "Practice mindfulness meditation for 5-10 minutes.",
            category: .wellbeing,
            xpValue: 10,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Drink Water Regularly",
            description: "Drink at least 8 glasses of water throughout the day.",
            category: .body,
            xpValue: 5,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Practice a Skill",
            description: "Dedicate 30 minutes to practicing a chosen skill (e.g., coding, instrument).",
            category: .skill,
            xpValue: 20,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Plan Your Day",
            description: "Take 5 minutes to plan your tasks and priorities for the day.",
            category: .discipline,
            xpValue: 5,
            frequency: "Daily"
        ),
        HabitTemplate(
            name: "Weekly Review",
            description: "Review your progress and plan for the upcoming week.",
            category: .discipline,
            xpValue: 25,
            frequency: "Weekly"
        ),
        // Add more templates as desired...
    ]
}
