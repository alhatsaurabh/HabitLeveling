// MARK: - File: InAppNotificationView.swift
// Purpose: Displays in-app notifications with a modern design.

import SwiftUI

struct InAppNotificationView: View {
    let notification: NotificationManager.InAppNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(ThemeColors.primaryText)
                Spacer()
            }
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .padding()
        .background(ThemeColors.panelBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private var iconName: String {
        switch notification.type {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .info:
            return ThemeColors.primaryAccent
        }
    }
}

struct InAppNotificationContainer: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            if let notification = notificationManager.currentNotification {
                VStack {
                    Spacer()
                    InAppNotificationView(notification: notification)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notificationManager.currentNotification)
    }
} 