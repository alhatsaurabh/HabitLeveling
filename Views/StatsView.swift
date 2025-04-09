// MARK: - File: StatsView.swift
// Purpose: Displays user statistics and artifacts.
// Update: Removed duplicate Notification.Name extension.
// Update 2: Fixed deprecated onChange modifier warning in ArtifactRowView.
// Update 3: Removed conflicting local definitions from PreviewProvider.

import SwiftUI
import CoreData
import Combine

// MARK: - XP Progress View (Embedded)
struct XPProgressView: View {
    let currentXP: Int
    let xpGoal: Int
    let themeAccentColor: Color // Assume ThemeColors exists globally

    private var progress: Double {
        guard xpGoal > 0 else { return 0.0 }
        return Double(currentXP) / Double(xpGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("XP")
                    .font(.headline)
                    .foregroundColor(ThemeColors.primaryText)
                Spacer()
                Text("\(currentXP) / \(xpGoal)")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeAccentColor))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}


// MARK: - Main Stats View
struct StatsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = StatsViewModel() // Assuming StatsViewModel is accessible globally
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    let themeAccentColor = ThemeColors.primaryAccent // Assuming ThemeColors is accessible globally

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Header ---
                VStack(spacing: 4) {
                    Text("Hunter Status").font(.title2).bold().foregroundColor(ThemeColors.primaryText)
                    Text("View your achievements and current stats").font(.subheadline).foregroundColor(ThemeColors.secondaryText)
                }.padding(.vertical)

                // --- Tabs ---
                Picker("View", selection: $selectedTab) {
                    Text("Stats").tag(0)
                    Text("Artifacts").tag(1)
                }
                .pickerStyle(.segmented)
                .background(ThemeColors.panelBackground.opacity(0.5).cornerRadius(8))
                .padding(.horizontal)
                .padding(.bottom)

                // --- Content Area ---
                if selectedTab == 0 { // Stats Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .center) { // Radar Chart Section
                                Text("Stat Distribution (XP Based)").font(.title3).fontWeight(.semibold).foregroundColor(ThemeColors.secondaryText).padding(.bottom, 5)
                                // Use the GLOBAL StatsRadarChartView
                                StatsRadarChartView(statPoints: viewModel.statPoints)
                                    .frame(height: 250)
                                    .animation(.easeInOut, value: viewModel.statPoints) // Animate changes
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                             // Use the GLOBAL SoloPanelModifier
                            .modifier(SoloPanelModifier())
                            .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 15) { // Core Stats Section
                                Text("Core Stats").font(.title3).fontWeight(.semibold).foregroundColor(ThemeColors.secondaryText).padding(.bottom, 5)
                                XPProgressView(currentXP: viewModel.xp, xpGoal: viewModel.xpGoal, themeAccentColor: themeAccentColor) // Uses embedded definition
                                    .padding(.bottom, 5)
                                Divider().background(ThemeColors.secondaryText.opacity(0.5)).padding(.bottom, 5)
                                StatRow(label: "Level", value: "\(viewModel.level)", icon: "star.fill", color: themeAccentColor) // Uses embedded definition
                                StatRow(label: "Rank", value: viewModel.hunterRank, icon: "figure.stand", color: ThemeColors.secondaryText)
                                StatRow(label: "Title", value: viewModel.title, icon: "medal.fill", color: ThemeColors.tertiaryAccent) // Added fallback
                                StatRow(label: "Job", value: viewModel.job, icon: "briefcase.fill", color: ThemeColors.secondaryText)
                                StatRow(label: "Overall Streak", value: "\(viewModel.overallStreak) days", icon: "flame.fill", color: ThemeColors.warning)
                                StatRow(label: "Total Completions", value: "\(viewModel.totalCompletions)", icon: "checkmark.circle.fill", color: ThemeColors.success)
                            }
                             // Use the GLOBAL SoloPanelModifier
                            .modifier(SoloPanelModifier())
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else { // Artifacts Tab (Tag 1)
                    ArtifactsListView() // Uses definition embedded below
                }
                Spacer()
            }
            .navigationBarHidden(true)
            .background(ThemeColors.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .safeAreaInset(edge: .top) { // Custom Top Bar
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    .padding([.top, .trailing])
                }
            }
            .onAppear {
                viewModel.fetchData()
            }
        }
        .navigationViewStyle(.stack)
        // Note: This view relies on GLOBAL definitions for:
        // ThemeColors, SoloPanelModifier, StatsRadarChartView, StatsViewModel, PersistenceController
        // Notification.Name.didToggleArtifactEquipStatus
    }

    // MARK: - Embedded Subviews (StatRow definition)
    private struct StatRow: View {
        let label: String; let value: String; let icon: String; let color: Color
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                    .frame(width: 25, alignment: .center)
                Text(label)
                    .font(.headline)
                    .foregroundColor(ThemeColors.primaryText)
                Spacer()
                Text(value)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeColors.primaryText)
            }
            .padding(.vertical, 5)
        }
    }
}


// MARK: - Artifacts List View Definition (Embedded)
struct ArtifactsListView: View {
    @State private var userProfile: UserProfile?
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest( sortDescriptors: [NSSortDescriptor(keyPath: \Artifact.name, ascending: true)], animation: .default ) private var artifacts: FetchedResults<Artifact>

    var body: some View {
        VStack {
            List {
                if artifacts.isEmpty {
                    Text("No artifact definitions found. Seeding may be needed.")
                        .foregroundColor(.secondary).padding().listRowBackground(Color.clear)
                } else {
                    ForEach(artifacts) { artifact in
                        ArtifactRowView( // Uses definition embedded below
                            artifact: artifact,
                            userProfile: userProfile,
                            viewContext: viewContext
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.bottom, 8)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.clear) // Use theme background if needed
        }
        .onAppear {
            fetchUserProfile()
        }
    }
    private func fetchUserProfile() {
        guard userProfile == nil else { return }
        let req: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        req.fetchLimit = 1
        do {
            self.userProfile = try viewContext.fetch(req).first
            if self.userProfile == nil { print("Warning: ArtifactsListView - No UserProfile found.") }
        } catch {
            print("Failed fetch profile for artifacts list: \(error)")
        }
    }
}

/** Displays a single row for an Artifact definition. (Embedded) */
struct ArtifactRowView: View {
    @ObservedObject var artifact: Artifact
    let userProfile: UserProfile?
    let viewContext: NSManagedObjectContext
    @State private var userArtifact: UserArtifact? = nil
    @State private var ownershipChecked: Bool = false
    @State private var isCurrentlyEquipped: Bool = false // Local state for UI
    let themeAccentColor = ThemeColors.primaryAccent // Assuming ThemeColors is accessible globally

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack { // Image Placeholder
                 Image(systemName: getSymbolForRarity(artifact.rarity)).resizable().scaledToFit().frame(width: 40, height: 40).padding(5).background(getColorForRarity(artifact.rarity).opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundColor(getColorForRarity(artifact.rarity))
            }
            VStack(alignment: .leading, spacing: 4) { // Details
                 Text(artifact.name ?? "?").font(.headline).foregroundColor(.primary) // Use .primary which adapts
                 Text("Rarity: \(artifact.rarity ?? "?")").font(.subheadline).fontWeight(.medium).foregroundColor(getColorForRarity(artifact.rarity))
                 if let d = artifact.desc, !d.isEmpty { Text(d).font(.caption).foregroundColor(.secondary).lineLimit(2) } // Use .secondary which adapts
                 if let bT = artifact.statBoostType, !bT.isEmpty, artifact.statBoostValue != 0 { Text("Boosts: \(bT) (+ \(String(format: "%.1f", artifact.statBoostValue)))").font(.caption).foregroundColor(.blue.opacity(0.8)) }
                 if let c = artifact.acquisitionCondition, !c.isEmpty { Text("How to get: \(c)").font(.caption).foregroundColor(.gray).italic() }
                 if userArtifact != nil { // Ownership / Equip Status
                      HStack(spacing: 6) { Text("OWNED").font(.caption.weight(.bold)).foregroundColor(.yellow); if isCurrentlyEquipped { Text("• EQUIPPED").font(.caption.weight(.bold)).foregroundColor(.green) } }.padding(.vertical, 2).padding(.horizontal, 5).background(Color.gray.opacity(0.15)).cornerRadius(4).padding(.top, 2)
                 }
            }
            Spacer()
            if userArtifact != nil { // Equip Button
                 let currentlyEquipped = isCurrentlyEquipped // Use local state for appearance
                 Button { toggleEquippedStatus() } label: { Text(currentlyEquipped ? "Unequip" : "Equip").font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 6).foregroundColor(currentlyEquipped ? .white : themeAccentColor).background(currentlyEquipped ? Color.gray.opacity(0.8) : themeAccentColor.opacity(0.3)).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(currentlyEquipped ? Color.gray : themeAccentColor, lineWidth: 1)) }.buttonStyle(.plain)
            } else { Spacer().frame(width: 60) } // Placeholder width
        }
        .padding()
        .background(ThemeColors.panelBackground.opacity(0.7)) // Use theme panel color
        .cornerRadius(10)
        .onAppear { checkOwnership() }
        // Use new onChange syntax
        .onChange(of: userArtifact?.isEquipped) { _, newEquippedState in
             if let newEquippedState = newEquippedState {
                 isCurrentlyEquipped = newEquippedState
             }
        }
    }

    private func checkOwnership() {
        guard let p = userProfile, !ownershipChecked else { return }
        ownershipChecked = true
        let req: NSFetchRequest<UserArtifact> = UserArtifact.fetchRequest(); req.predicate = NSPredicate(format: "profile == %@ AND artifact == %@", p, artifact); req.fetchLimit = 1
        do {
            userArtifact = try viewContext.fetch(req).first
            isCurrentlyEquipped = userArtifact?.isEquipped ?? false // Initialize state
        } catch { print("Err check own: \(error)") }
    }
    private func toggleEquippedStatus() {
        guard let ua = userArtifact else { return }
        isCurrentlyEquipped.toggle() // Update state first
        ua.isEquipped = isCurrentlyEquipped // Sync Core Data object
        do {
            try viewContext.save()
            print("UserArtifact '\(artifact.name ?? "")' isEquipped set to: \(ua.isEquipped)")
            // Assume Notification.Name.didToggleArtifactEquipStatus exists globally
            NotificationCenter.default.post( name: .didToggleArtifactEquipStatus, object: nil) // Post notification
            print("Posted didToggleArtifactEquipStatus notification.")
        } catch {
            print("Failed to save equipped status change: \(error)")
            isCurrentlyEquipped.toggle() // Revert state on error
            ua.isEquipped = isCurrentlyEquipped // Sync back Core Data object
        }
    }
    private func getSymbolForRarity(_ rarity: String?) -> String {
         switch rarity?.lowercased() { case "uncommon": return "shield.lefthalf.filled"; case "rare": return "star.fill"; case "epic": return "crown.fill"; case "legendary": return "seal.fill"; case "common": fallthrough; default: return "shield" }
    }
    private func getColorForRarity(_ rarity: String?) -> Color {
         switch rarity?.lowercased() { case "uncommon": return .green; case "rare": return .blue; case "epic": return .purple; case "legendary": return .orange; case "common": fallthrough; default: return .gray }
    }
}


// MARK: - Previews
struct StatsView_Previews: PreviewProvider {
    // Mock ThemeColors if needed
    struct PreviewThemeColors { static let background = Color.black; static let primaryText = Color.white; static let secondaryText = Color.gray; static let panelBackground = Color.gray.opacity(0.2); static let glowColor = Color.cyan.opacity(0.5); static let primaryAccent = Color.cyan; static let tertiaryAccent: Color? = .yellow; static let warning = Color.orange; static let success = Color.green }
    static let ThemeColors = PreviewThemeColors.self

    // --- REMOVED Local SoloPanelModifier struct ---
    // --- REMOVED Local extension View { func soloPanelStyle()... } ---
    // --- REMOVED Local StatsRadarChartView struct ---
    // --- REMOVED Local extension Notification.Name ---

    // Previews now rely on GLOBAL definitions for:
    // - SoloPanelModifier & .soloPanelStyle() (from SoloPanelModifier.swift)
    // - StatsRadarChartView (from StatsRadarChartView.swift)
    // - Notification.Name.didToggleArtifactEquipStatus (from wherever it's defined globally)
    // - All CoreData entities, PersistenceController, StatsViewModel, etc.

    static var previews: some View {
        StatsView()
            // Ensure preview context has necessary data (Habits, Profile, Artifacts)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Assumptions for Compilation
// Ensure all globally referenced components exist:
// - ThemeColors, SoloPanelModifier, StatsRadarChartView, StatsViewModel, PersistenceController
// - Notification.Name.didToggleArtifactEquipStatus
// Ensure CoreData entities are correctly defined:
// - Habit, HabitLog, UserProfile, Artifact, UserArtifact
