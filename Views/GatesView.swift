// MARK: - File: GatesView.swift (Inside Views Group)
// Added UI Refinements: Card layout, icons, spacing

import SwiftUI
import CoreData

struct GatesView: View {
    @StateObject private var viewModel = GatesViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ThemeColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Mana Crystals Display
                        HStack {
                            Image(systemName: "circle.hexagongrid.fill")
                                .imageScale(.small)
                                .foregroundColor(ThemeColors.secondaryAccent)
                            Text("\(viewModel.manaCrystals)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeColors.secondaryAccent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(ThemeColors.panelBackground.opacity(0.85))
                                .blur(radius: 3)
                        )
                        .padding(.top)

                        if let errorMessage = viewModel.actionErrorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ThemeColors.panelBackground.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.5), lineWidth: 1))
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation { viewModel.actionErrorMessage = nil }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // List of Gates
                        if viewModel.gates.isEmpty {
                            VStack(alignment: .center, spacing: 10) {
                                Image(systemName: "shield.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(ThemeColors.secondaryText)
                                Text("No Active Gates")
                                    .font(.headline)
                                    .foregroundColor(ThemeColors.primaryText)
                                Text("Clear gates or refresh existing ones.")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        } else {
                            ForEach(viewModel.gates, id: \.self) { gate in
                                GateRowView(gate: gate, viewModel: viewModel)
                                    .padding(.horizontal)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if gate.status == "Cleared" {
                                            Button(role: .destructive) {
                                                viewModel.deleteGate(gate: gate)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(.red)
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if gate.status == "Cleared" {
                                            Button {
                                                viewModel.deleteGate(gate: gate)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(.red)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Gates")
            .onAppear {
                viewModel.fetchGates()
                viewModel.fetchUserProfile()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// Helper View for displaying a single Gate row (Refined Styling)
struct GateRowView: View {
    @ObservedObject var gate: GateStatus
    @ObservedObject var viewModel: GatesViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Rank, Type, Status
            HStack {
                Text("\(gate.gateRank ?? "N/A")-Rank")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(rankColor(gate.gateRank))
                Text(gateTypeDisplay(gate.gateType))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(typeColor(gate.gateType).opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(typeColor(gate.gateType).opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: typeColor(gate.gateType).opacity(0.3), radius: 4, x: 0, y: 0)
                Spacer()
                Text(gate.status ?? "Unknown")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(gate.status))
                    .clipShape(Capsule())
            }

            // Conditional Details based on Status
            if gate.status == "Analyzed" {
                VStack(alignment: .leading, spacing: 6) {
                    Label { Text("Condition").bold() } icon: { Image(systemName: "list.bullet.clipboard").foregroundColor(ThemeColors.secondaryText) }
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.primaryText)

                    Text(gate.clearConditionDescription ?? "N/A")
                        .font(.body)
                        .foregroundColor(ThemeColors.secondaryText)

                    Divider()
                        .padding(.vertical, 4)

                    Label { Text("Reward").bold() } icon: { Image(systemName: "gift.fill").foregroundColor(ThemeColors.secondaryText) }
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.primaryText)

                    Text(gate.rewardDescription ?? "N/A")
                        .font(.body)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                .padding(.top, 5)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Spacer()
                if gate.status == "Locked" {
                    VStack(spacing: 4) {
                        Button { viewModel.attemptRefresh(gate: gate) } label: { 
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(ThemeColors.warning)
                        .disabled(viewModel.manaCrystals < viewModel.refreshLockedCost)
                        .frame(width: 150)
                        .clipShape(Capsule())
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .imageScale(.small)
                                .foregroundColor(ThemeColors.secondaryAccent)
                            Text("\(viewModel.refreshLockedCost)")
                                .foregroundColor(ThemeColors.secondaryAccent)
                        }
                    }

                    VStack(spacing: 4) {
                        Button { viewModel.attemptAnalysis(gate: gate) } label: { 
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Analyze")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(ThemeColors.primaryAccent)
                        .disabled(viewModel.manaCrystals < viewModel.analysisCost)
                        .frame(width: 150)
                        .clipShape(Capsule())
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .imageScale(.small)
                                .foregroundColor(ThemeColors.secondaryAccent)
                            Text("\(viewModel.analysisCost)")
                                .foregroundColor(ThemeColors.secondaryAccent)
                        }
                    }
                } else if gate.status == "Analyzed" {
                    VStack(spacing: 4) {
                        Button { viewModel.attemptRefresh(gate: gate) } label: { 
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(ThemeColors.warning)
                        .disabled(viewModel.manaCrystals < viewModel.refreshAnalyzedCost)
                        .frame(width: 150)
                        .clipShape(Capsule())
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .imageScale(.small)
                                .foregroundColor(ThemeColors.secondaryAccent)
                            Text("\(viewModel.refreshAnalyzedCost)")
                                .foregroundColor(ThemeColors.secondaryAccent)
                        }
                    }

                    Button { viewModel.attemptClear(gate: gate) } label: { 
                        HStack {
                            Image(systemName: "figure.walk.arrival")
                            Text("Attempt Clear")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(ThemeColors.primaryAccent)
                    .frame(width: 150)
                    .clipShape(Capsule())
                } else if gate.status == "Cleared" {
                    Label("Cleared", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.italic())
                        .foregroundColor(ThemeColors.secondaryText)
                }
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(ThemeColors.panelBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    private func gateTypeDisplay(_ type: String?) -> String {
        switch type {
        case "red":
            return "Red Gate"
        case "blue":
            return "Blue Gate"
        default:
            return type ?? "Unknown"
        }
    }

    // Helper functions for styling
    func rankColor(_ rank: String?) -> Color {
        switch rank {
        case "E": return .gray
        case "D": return .blue
        case "C": return .green
        case "B": return .orange
        case "A": return .red
        case "S": return .purple
        default: return ThemeColors.primaryText
        }
    }

    func typeColor(_ type: String?) -> Color {
        switch type {
        case "Blue": return Color.blue
        case "Red": return Color.red
        default: return ThemeColors.secondaryText
        }
    }

    func statusColor(_ status: String?) -> Color {
        switch status {
        case "Locked": return ThemeColors.secondaryText
        case "Analyzed": return ThemeColors.warning
        case "Cleared": return ThemeColors.success
        default: return ThemeColors.primaryText
        }
    }
}

// Preview Provider
struct GatesView_Previews: PreviewProvider {
    static var previews: some View {
        GatesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
