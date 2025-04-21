# HabitLeveling Project Plan

## Project Overview
HabitLeveling is a gamified habit tracking app with RPG elements including levels, gates, stats, and artifacts. The app allows users to create and track habits, gain XP, level up, and unlock rewards. The core purpose is to help users build and maintain habits, with gamification serving as a retention tool.

## Current Status
- Basic app structure is implemented
- Core Data models are defined
- Main views are created
- Stats tracking and rewards system are functional
- Smart calendar for progress tracking is implemented
- Some critical bugs have been fixed

## Recent Fixes
- ✅ Fixed StatCategory enum definition conflicts
- ✅ Fixed gate condition checking for habit categories
- ✅ Fixed gate mana crystal rewards to consistently grant 50 mana crystals
- ✅ Implemented swipe-to-delete for cleared gates
- ✅ Fixed habit reminder notifications system
- ✅ Implemented smart calendar with heat map visualization

## Development Phases

### Phase 1: Stability (Current)
- Ensure all core functionality works reliably
- Fix critical bugs
- Improve error handling and user feedback

### Phase 2: Quality of Life Updates (Current)
- ✅ Implement smart calendar for progress tracking
- Add pomodoro timer functionality
- Improve core habit tracking experience

### Phase 3: Narrative Gamification
- Create Hunter's Association HQ progression system with visual representation
- Implement shadow extraction and shadow army system
- Enhance gate system with Solo Leveling themed mechanics
- Design hunter equipment and ranking system
- Implement shop for mana crystal spending
- Link habits directly to hunter progression and shadow army

### Phase 4: Polish & Refinement
- Enhance visuals and animations
- Optimize performance
- Improve user experience
- Refine narrative content based on feedback

## Todo List

### Immediate Priority (Quality of Life Updates)
- [✅] Implement Smart Calendar for Progress Tracking
  - [✅] Create calendar view with habit completion history
  - [✅] Add heat map visualization for consistency
  - [✅] Implement basic progress metrics
  - [✅] Design intuitive UI for reviewing past performance

- [ ] Add Pomodoro Timer Feature
  - [ ] Design timer interface with work/break cycles
  - [ ] Implement customizable session lengths
  - [ ] Add notifications for session transitions
  - [ ] Link pomodoro completion to habit progress

### High Priority
- [✅] Fix habit reminder notifications system
- [✅] Fix gate rewards for mana crystals
- [✅] Implement swipe-to-delete for cleared gates
- [ ] Review all references to StatCategory and ensure consistency
- [ ] Add thorough error handling in gate completion logic
- [ ] Add validation for user inputs in habit creation
- [ ] Implement data persistence safeguards to prevent data loss

### Narrative Gamification Features
- [ ] **Hunter's Association HQ System**
  - [ ] Design visual representation of HQ at different ranks
  - [ ] Create progression stages from E-Rank to S-Rank HQ
  - [ ] Implement interactive HQ elements
  - [ ] Link HQ improvements to hunter level and achievements

- [ ] **Shadow Army System**
  - [ ] Design shadow extraction mechanics from special gates
  - [ ] Create shadow types based on habit categories
  - [ ] Implement shadow leveling through habit completion
  - [ ] Design shadow army interface for management

- [ ] **Enhanced Gate System**
  - [ ] Expand gates with E to S rank classifications
  - [ ] Create special "Red Gates" with higher difficulty/rewards
  - [ ] Implement gate artifacts and equipment rewards
  - [ ] Design visual representation of cleared gates

- [ ] **Hunter Equipment System**
  - [ ] Create equipment models for weapons, armor and accessories
  - [ ] Implement equipment effects on habits and streaks
  - [ ] Design inventory interface for equipment management
  - [ ] Link equipment upgrades to gates and achievements

- [ ] **Guild Shop System**
  - [ ] Create shop interface for spending mana crystals
  - [ ] Design items that improve hunter abilities and HQ
  - [ ] Implement shadow enhancement items
  - [ ] Balance currency rewards and item costs

## Next Development Focus
With the Smart Calendar feature now complete, we're moving forward with the Solo Leveling-inspired Narrative Gamification features (Hunter's Association HQ, shadow army, and enhanced gate system) as our next priority. The Pomodoro Timer feature has significant implementation progress but will be fully completed in a later phase.

## Feature Details

### Smart Calendar (Complete)
- ✅ Calendar view showing habit completion history
- ✅ Heat map visualization for consistency
- ✅ Streak tracking and statistics
- ✅ Simple filtering by habit type

### Pomodoro Timer
- Work/break interval timer
- Session notifications
- Basic statistics tracking
- Integration with habit completion

### Narrative Gamification
- **Core Theme**: Solo Leveling inspired hunter progression system
- **Hunter HQ**: Visual progression from E-Rank to S-Rank headquarters
- **Shadow Army**: Extract and level shadows from completed gates
- **Equipment**: Weapons, armor and accessories to enhance habit completion
- **Gates**: Enhanced gate system with ranks and special rewards
- **Purpose**: Give meaning to habit tracking through hunter progression

## Development Guidelines
1. Keep implementations simple and focused
2. Prioritize visual feedback for user actions
3. Ensure smooth integration between features
4. Test thoroughly after each change
5. Remember the core purpose: Help users build habits

## Testing Checklist
- [✅] Test habit reminder notifications
- [ ] Test habit creation and editing
- [ ] Test habit completion and streaks
- [✅] Test gate clearing and mana crystal rewards
- [ ] Test level progression and XP calculation
- [✅] Test calendar view and history tracking
- [ ] Test pomodoro timer functionality
- [ ] Test story progression mechanics
- [ ] Test shop functionality and currency management

## Implementation Details

### Hunter's Association HQ Implementation

#### Models
```swift
// HunterHQ+CoreDataClass.swift
class HunterHQ: NSManagedObject {
    // Core Data implementation
}

// HunterHQ+CoreDataProperties.swift
extension HunterHQ {
    @NSManaged public var rank: String // E, D, C, B, A, or S
    @NSManaged public var level: Int16 // Current level within rank
    @NSManaged public var facilities: [String] // Unlocked facilities
    @NSManaged public var lastUpgrade: Date
    @NSManaged public var profile: UserProfile // Relationship to user profile
}

// HQFacility model (enum or struct)
enum HQFacilityType: String, Codable {
    case trainingRoom = "Training Room"
    case infirmary = "Infirmary"
    case armory = "Armory"
    case gateMonitor = "Gate Monitor"
    case shadowChamber = "Shadow Chamber"
    case library = "Association Library"
    case rankingBoard = "Ranking Board"
    // More facilities...
}
```

#### ViewModels
```swift
// HunterHQViewModel.swift
class HunterHQViewModel: ObservableObject {
    @Published var currentRank: String = "E"
    @Published var hqLevel: Int = 1
    @Published var unlockedFacilities: [HQFacilityType] = []
    @Published var nextUpgradeRequirements: [String] = []
    
    // Methods for upgrading and managing HQ
    func upgradeHQ() { /* Implementation */ }
    func unlockFacility(_ facility: HQFacilityType) { /* Implementation */ }
    func calculateNextUpgrade() { /* Implementation */ }
}
```

#### Views
```swift
// HunterHQView.swift - Main interface for Hunter's HQ
struct HunterHQView: View {
    @StateObject private var viewModel = HunterHQViewModel()
    
    var body: some View {
        // HQ visualization UI
    }
}

// HQFacilityDetailView.swift - For interacting with specific facilities
struct HQFacilityDetailView: View {
    var facilityType: HQFacilityType
    @ObservedObject var viewModel: HunterHQViewModel
    
    var body: some View {
        // Facility detail UI
    }
}
```

#### Integration Points
1. Update `UserProfile` to track HQ progression
2. Add HQ upgrade events when leveling up
3. Create notifications for HQ-related achievements
4. Link habits and gate clearance to HQ improvements

#### Initial Implementation Steps
1. Create CoreData models for HQ and facilities
2. Build basic HQ visualization with rank differences
3. Implement upgrade mechanics tied to user level
4. Add interactive elements for facility access
5. Design notification system for HQ events

This feature will serve as the foundation for the narrative gamification system, with shadow army and enhanced gates built on top of it.

### Shadow Army Implementation

#### Models
```swift
// Shadow+CoreDataClass.swift
class Shadow: NSManagedObject {
    // Core Data implementation
}

// Shadow+CoreDataProperties.swift
extension Shadow {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var type: String // Based on StatCategory
    @NSManaged public var level: Int16
    @NSManaged public var experience: Int32
    @NSManaged public var extractionDate: Date
    @NSManaged public var specialAbility: String?
    @NSManaged public var isAssigned: Bool
    @NSManaged public var assignedHabitID: UUID?
    @NSManaged public var profile: UserProfile // Relationship to user profile
    
    // Computed properties
    var statCategory: StatCategory? {
        return StatCategory(rawValue: type)
    }
    
    var experienceToNextLevel: Int32 {
        return Int32(level * 100) // Simple formula, can be adjusted
    }
}

// ShadowGate model - special gates that allow shadow extraction
struct ShadowGate {
    let id: UUID
    let difficultyRank: String // E through S rank
    let statCategory: StatCategory
    let clearCondition: String
    let shadowName: String
    let shadowAbility: String?
}
```

#### ViewModels
```swift
// ShadowArmyViewModel.swift
class ShadowArmyViewModel: ObservableObject {
    @Published var shadows: [Shadow] = []
    @Published var activeShadows: [Shadow] = []
    @Published var availableShadowGates: [ShadowGate] = []
    
    // Methods
    func extractShadow(from gate: ShadowGate) { /* Implementation */ }
    func assignShadow(_ shadow: Shadow, toHabit habitID: UUID) { /* Implementation */ }
    func unassignShadow(_ shadow: Shadow) { /* Implementation */ }
    func levelUpShadow(_ shadow: Shadow, xpGained: Int) { /* Implementation */ }
    func generateShadowGate(forCategory category: StatCategory) { /* Implementation */ }
}
```

#### Views
```swift
// ShadowArmyView.swift - Main interface for shadow management
struct ShadowArmyView: View {
    @StateObject private var viewModel = ShadowArmyViewModel()
    
    var body: some View {
        // Shadow army visualization UI
    }
}

// ShadowDetailView.swift - For viewing/managing individual shadows
struct ShadowDetailView: View {
    var shadow: Shadow
    @ObservedObject var viewModel: ShadowArmyViewModel
    
    var body: some View {
        // Shadow detail and management UI
    }
}

// ShadowGateView.swift - For completing shadow extraction challenges
struct ShadowGateView: View {
    var gate: ShadowGate
    @ObservedObject var viewModel: ShadowArmyViewModel
    
    var body: some View {
        // Shadow gate challenge UI
    }
}
```

#### Integration Points
1. Create shadow extraction opportunities after streak achievements
2. Add shadow bonuses to habit completion rewards
3. Display active shadows on habit detail screens
4. Include shadow army stats in user profile

#### Initial Implementation Steps
1. Create CoreData models for shadows
2. Implement shadow extraction mechanics for habit streaks
3. Design shadow army visualization screen
4. Add shadow assignment system for habits
5. Create shadow leveling mechanics

This feature will provide a compelling reason for users to maintain streaks (to unlock and power up shadows) while tying directly into the Solo Leveling theme. 
