
// --- Sanctum View (SanctumView.swift) ---
// Placeholder for the Inner Sanctum view.
struct SanctumView: View {
     @Environment(\.managedObjectContext) private var viewContext

     // Fetch unlocked sanctum items
     @FetchRequest(
         sortDescriptors: [NSSortDescriptor(keyPath: \SanctumItem.unlockDate, ascending: true)],
         animation: .default)
     private var sanctumItems: FetchedResults<SanctumItem>

     // Fetch user profile to display fragment count
     @FetchRequest(
         sortDescriptors: [],
         predicate: nil, // Fetches all UserProfiles (should be only one)
         animation: .default)
     private var profiles: FetchedResults<UserProfile>


    var body: some View {
        NavigationView {
             VStack {
                Text("Inner Sanctum")
                    .font(.largeTitle)
                    .padding()

                 // Display Fragment Count (from UserProfile)
                 Text("Essence Fragments: \(profiles.first?.fragmentCount ?? 0)")
                     .font(.title3)
                     .foregroundColor(.gray)
                     .padding(.bottom)


                 // Display unlocked items (simple list for now)
                 List {
                     if sanctumItems.isEmpty {
                         Text("Your Sanctum is currently empty. Level up to unlock elements!")
                             .foregroundColor(.gray)
                     } else {
                         ForEach(sanctumItems) { item in
                             HStack {
                                 Image(systemName: "square.grid.3x3.fill") // Placeholder icon
                                     .foregroundColor(.cyan)
                                 VStack(alignment: .leading) {
                                     Text(item.elementType ?? "Unknown Element")
                                         .font(.headline)
                                     Text("Unlocked: \(item.unlockDate ?? Date(), style: .date)")
                                         .font(.caption)
                                         .foregroundColor(.gray)
                                 }
                             }
                         }
                         .listRowBackground(Color.black.opacity(0.3))
                     }
                 }
                 .listStyle(InsetGroupedListStyle())


                Spacer() // Pushes content up
            }
            .navigationTitle("Sanctum")
            .navigationBarHidden(true) // Hide redundant navigation bar if needed
        }
    }
}
