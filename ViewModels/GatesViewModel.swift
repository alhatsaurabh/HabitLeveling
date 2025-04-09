// MARK: - File: GatesViewModel.swift (Updated April 3, 2025)
// Updated cost properties to match GateManager

import SwiftUI
import CoreData
import Combine

class GatesViewModel: ObservableObject {
    // --- Properties ---
    @Published var gates: [GateStatus] = []
    @Published var manaCrystals: Int = 0
    @Published var actionErrorMessage: String? = nil

    private var viewContext = PersistenceController.shared.container.viewContext
    private var userProfile: UserProfile?
    private var cancellables = Set<AnyCancellable>()

    // --- UPDATED Cost Properties ---
    // Get costs directly from the manager's constants
    let analysisCost = GateManager.shared.analysisCost
    let refreshLockedCost = GateManager.shared.refreshLockedCost
    let refreshAnalyzedCost = GateManager.shared.refreshAnalyzedCost

    init() {
        fetchUserProfile()
        fetchGates()
        // Observe Reset
        NotificationCenter.default.publisher(for: .didPerformReset)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in print("GatesViewModel received reset notification."); self?.fetchUserProfile(); self?.fetchGates() }.store(in: &cancellables)
        // Observe Profile Update
        NotificationCenter.default.publisher(for: .didUpdateUserProfile)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in print("GatesViewModel received profile update notification."); self?.fetchUserProfile(); self?.fetchGates() }.store(in: &cancellables)
    }

    // --- Data Fetching ---

    func fetchUserProfile() {
        // (Code remains the same)
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest(); fetchRequest.fetchLimit = 1
        do { if let profile = try viewContext.fetch(fetchRequest).first { self.userProfile = profile; DispatchQueue.main.async { self.manaCrystals = Int(profile.manaCrystals) } } else { print("GatesViewModel: UserProfile not found."); DispatchQueue.main.async { self.manaCrystals = 0 } }
        } catch { print("GatesViewModel: Error fetching UserProfile: \(error)"); DispatchQueue.main.async { self.manaCrystals = 0 } }
    }

    func fetchGates() {
        // (Code remains the same)
        let request: NSFetchRequest<GateStatus> = GateStatus.fetchRequest(); request.sortDescriptors = [ NSSortDescriptor(keyPath: \GateStatus.statusChangeDate, ascending: false) ]
        do { let fetchedGates = try viewContext.fetch(request); DispatchQueue.main.async { self.gates = fetchedGates; print("GatesViewModel: Fetched \(fetchedGates.count) gates.") }
        } catch { print("GatesViewModel: Error fetching gates: \(error)"); DispatchQueue.main.async { self.gates = [] } }
    }

    // --- Actions ---

    func attemptAnalysis(gate: GateStatus) {
        // (Code remains the same, uses self.analysisCost)
        guard let profile = userProfile else { DispatchQueue.main.async { self.actionErrorMessage = "Error: User data not loaded." }; return }; DispatchQueue.main.async { self.actionErrorMessage = nil }
        let success = GateManager.shared.analyzeGate(gate: gate, profile: profile)
        if success { print("Analysis successful via ViewModel.") } else { DispatchQueue.main.async { if profile.manaCrystals < self.analysisCost { self.actionErrorMessage = "Not enough Mana Crystals (\(profile.manaCrystals)/\(self.analysisCost))." } else if gate.status != "Locked" { self.actionErrorMessage = "Gate is no longer locked." } else { self.actionErrorMessage = "Analysis failed for an unknown reason." } }; print("Analysis attempt failed for gate.") }
    }

    func attemptClear(gate: GateStatus) {
        // (Code remains the same)
        guard let profile = userProfile else { print("Cannot clear: UserProfile not loaded."); DispatchQueue.main.async { self.actionErrorMessage = "Error: User data not loaded." }; return }; DispatchQueue.main.async { self.actionErrorMessage = nil }
        print("--> Checking clear condition via ViewModel..."); let conditionMet = GateManager.shared.checkClearCondition(gate: gate, profile: profile, context: viewContext)
        guard conditionMet else { print("<-- Clear condition not met for Gate ID: \(gate.id?.uuidString ?? "N/A")"); DispatchQueue.main.async { self.actionErrorMessage = "Clear condition not yet met! (\(gate.clearConditionDescription ?? ""))" }; return }
        print("<-- Clear condition met. Attempting to clear gate..."); let success = GateManager.shared.clearGate(gate: gate, profile: profile)
        if success { print("Gate cleared successfully via ViewModel.") } else { DispatchQueue.main.async { self.actionErrorMessage = "Failed to clear gate." }; print("Clearing attempt failed for gate.") }
    }

    func attemptRefresh(gate: GateStatus) {
        // (Code remains the same, manager now handles different costs)
        guard let profile = userProfile else { DispatchQueue.main.async { self.actionErrorMessage = "Error: User data not loaded." }; return }; DispatchQueue.main.async { self.actionErrorMessage = nil }
        let result = GateManager.shared.refreshGate(gate: gate, profile: profile, context: viewContext)
        if result.success { print("Gate refreshed successfully via ViewModel.") } else { DispatchQueue.main.async { self.actionErrorMessage = result.message ?? "Failed to refresh gate." }; print("Refresh attempt failed for gate.") }
    }

    func deleteGate(gate: GateStatus) {
        viewContext.delete(gate)
        do {
            try viewContext.save()
            fetchGates() // Refresh the list
        } catch {
            print("Error deleting gate: \(error)")
            DispatchQueue.main.async {
                self.actionErrorMessage = "Failed to delete gate."
            }
        }
    }
}
