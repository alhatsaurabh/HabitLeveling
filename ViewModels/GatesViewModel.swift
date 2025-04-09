
import SwiftUI
import CoreData
import Combine

class SanctumViewModel: ObservableObject {
    // --- Properties ---
    @Published var fragmentCount: Int = 0
    @Published var buildErrorMessage: String? = nil
    let availableItems: [AvailableSanctumItem] = AvailableSanctumItem.buildableItems

    private var viewContext = PersistenceController.shared.container.viewContext
    private var userProfile: UserProfile?
    private var cancellables = Set<AnyCancellable>() // Store observers

    init() {
        fetchUserProfile()
        // --- ADD Observer for Reset Notification ---
        NotificationCenter.default.publisher(for: .didPerformReset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("SanctumViewModel received reset notification. Refreshing data.")
                self?.fetchUserProfile() // Re-fetch profile to update fragment count
                // Note: Placed items list uses @FetchRequest in View, should update automatically
            }
            .store(in: &cancellables)
        // --- END Observer ---
    }

    // --- Functions (fetchUserProfile, attemptToBuild) ---
    // No changes needed inside these functions for reset, just the observer in init()
    func fetchUserProfile() { /* ... */ let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest(); fetchRequest.fetchLimit = 1; do { if let profile = try viewContext.fetch(fetchRequest).first { self.userProfile = profile; self.fragmentCount = Int(profile.fragmentCount); /* print("SanctumViewModel: UserProfile fetched...") */ } else { print("SanctumViewModel: UserProfile not found."); self.fragmentCount = 0 } } catch { print("SanctumViewModel: Error fetching UserProfile: \(error)"); self.fragmentCount = 0 } }
    func attemptToBuild(item: AvailableSanctumItem) { /* ... */ guard let profile = userProfile else { print("Cannot build: UserProfile not loaded."); self.buildErrorMessage = "Error: User data not loaded."; return }; self.buildErrorMessage = nil; let success = SanctumManager.shared.spendFragmentsToBuild(item: item, profile: profile); if success { fetchUserProfile() } else { if profile.fragmentCount < item.fragmentCost { self.buildErrorMessage = "Not enough fragments." } else { self.buildErrorMessage = "'\(item.name)' already constructed." }; print("Build attempt failed for \(item.name).") } }
}
