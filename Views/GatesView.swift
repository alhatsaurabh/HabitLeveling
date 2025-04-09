
import SwiftUI
import CoreData

struct SanctumView: View {
    @StateObject private var viewModel = SanctumViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SanctumItem.unlockDate, ascending: true)],
        animation: .default)
    private var placedItems: FetchedResults<SanctumItem>

    let themeAccentColor = Color.cyan

    // --- Define Grid Columns ---
    // Adaptive columns: creates as many columns as fit with a minimum width
    let gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 15) // Adjust minimum width and spacing
    ]

    var body: some View {
        NavigationView {
            // Use ScrollView instead of List for more layout flexibility with Grid
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { // Use VStack to stack sections

                    // --- Fragment Count Section ---
                    Section { // Use Section for semantic grouping, header added manually below
                        HStack { /* ... Fragment count HStack ... */
                            Image(systemName: "circle.hexagongrid.fill").foregroundColor(themeAccentColor).font(.title3); Text("Essence Fragments:").font(.headline); Spacer(); Text("\(viewModel.fragmentCount)").font(.headline).fontWeight(.bold)
                        }
                    }
                    .modifier(SoloPanelModifier()) // Apply style to the content


                    // --- Available Blueprints Section ---
                    VStack(alignment: .leading) { // VStack for header + content
                        Text("Available Blueprints") // Manual Section Header
                            .font(.title2).fontWeight(.semibold).foregroundColor(.gray)
                            .padding([.leading, .top]).padding(.bottom, 5)

                        // Content for Available Blueprints
                        VStack(spacing: 0) {
                            if viewModel.availableItems.isEmpty {
                                 Text("No blueprints available yet.").foregroundColor(.gray).modifier(SoloPanelModifier())
                            } else {
                                ForEach(viewModel.availableItems) { item in
                                    HStack { /* ... Blueprint row HStack ... */
                                        Image(systemName: item.iconName).foregroundColor(themeAccentColor).font(.title3).frame(width: 35, alignment: .center); VStack(alignment: .leading) { Text(item.name).font(.headline); Text(item.description).font(.caption).foregroundColor(.gray); Text("Cost: \(item.fragmentCost) Fragments").font(.subheadline).foregroundColor(viewModel.fragmentCount >= item.fragmentCost ? .yellow : .red.opacity(0.7)) }; Spacer(); Button { viewModel.attemptToBuild(item: item) } label: { Image(systemName: "hammer.fill") }.disabled(viewModel.fragmentCount < item.fragmentCost || itemIsAlreadyPlaced(item.elementType)).buttonStyle(.borderedProminent).tint(themeAccentColor)
                                    }
                                     .modifier(SoloPanelModifier())
                                }
                            }
                        }
                    }
                    .padding(.top) // Space above this section


                    // --- Constructed Elements Section (Using Grid) ---
                    VStack(alignment: .leading) {
                        Text("Constructed Elements") // Manual Section Header
                           .font(.title2).fontWeight(.semibold).foregroundColor(.gray)
                           .padding([.leading, .top]).padding(.bottom, 5)

                        if placedItems.isEmpty {
                            Text("Your Sanctum is currently empty. Build items or level up!")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .soloPanelStyle() // Apply style to empty message
                        } else {
                            // --- Use LazyVGrid ---
                            LazyVGrid(columns: gridColumns, spacing: 15) {
                                ForEach(placedItems) { item in
                                    // Content for each grid item
                                    VStack(spacing: 8) {
                                        Image(systemName: getIconForElementType(item.elementType))
                                            .font(.largeTitle) // Larger icon for grid
                                            .foregroundColor(.green)

                                        Text(item.elementType ?? "Unknown")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.center) // Center text below icon

                                        Text("\(item.unlockDate ?? Date(), style: .date)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100) // Give grid items a minimum height
                                    .soloPanelStyle() // Apply panel style to each grid item
                                }
                            }
                            .padding(.horizontal) // Padding for the grid itself
                            // --- End LazyVGrid ---
                        }
                    }
                    .padding(.top) // Space above this section


                     // Display Build Error Message if any
                     if let errorMessage = viewModel.buildErrorMessage {
                         Text("Build Failed: \(errorMessage)")
                             .font(.subheadline).foregroundColor(.red)
                             .padding()
                             .frame(maxWidth: .infinity, alignment: .center)
                             .soloPanelStyle() // Apply style to error message
                             .padding(.top)
                     }

                } // End Main VStack
                .padding(.bottom) // Padding at the very bottom
            } // End ScrollView
            .navigationTitle("Inner Sanctum")
            .background(Color.black.ignoresSafeArea())
            .onAppear { viewModel.fetchUserProfile() }
        } // End NavigationView
         .tint(themeAccentColor)
         .preferredColorScheme(.dark)
    }

    // Helper functions (itemIsAlreadyPlaced, getIconForElementType) remain the same
    private func itemIsAlreadyPlaced(_ elementType: String) -> Bool { /* ... */ return placedItems.contains { $0.elementType == elementType } }
    private func getIconForElementType(_ elementType: String?) -> String { /* ... */ switch elementType { case "Foundation Stone": return "square.stack.3d.up.fill"; case "Training Post": return "figure.martial.arts"; case "Meditation Rock": return "leaf.fill"; case "Small Library": return "books.vertical.fill"; case "Glowing Crystal": return "sparkle"; default: return "questionmark.diamond.fill" } }
}


// MARK: - Previews

struct SanctumView_Previews: PreviewProvider { /* ... */ static var previews: some View { SanctumView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).preferredColorScheme(.dark) } }
