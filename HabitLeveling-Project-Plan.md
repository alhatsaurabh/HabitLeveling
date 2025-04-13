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
- Create shelter-building storyline and visual progression
- Implement shop system for mana crystal spending
- Design character rescue/help mechanics
- Link habits directly to story progression

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
- [ ] **Shelter Building System**
  - [ ] Design visual representation of shelter construction
  - [ ] Create progression stages for shelter improvements
  - [ ] Implement character rescue mechanics
  - [ ] Link habit completion directly to building progress

- [ ] **Shop System**
  - [ ] Create shop interface for spending mana crystals
  - [ ] Design items that improve shelter or help characters
  - [ ] Implement inventory management
  - [ ] Balance currency rewards and item costs

- [ ] **Simple Integration Points**
  - [ ] Mark story milestones on calendar
  - [ ] Award bonus rewards for pomodoro usage
  - [ ] Create achievement showcase for completed progress

## Next Development Focus
With the Smart Calendar feature now complete, we're moving forward with the Narrative Gamification features (shelter-building system, shop, and character mechanics) as our next priority. The Pomodoro Timer feature has significant implementation progress but will be fully completed in a later phase.

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
- **Core Story**: Building/repairing a shelter to save characters
- **Visual Progress**: Shelter improves as habits are completed
- **Characters**: People to rescue through consistent habits
- **Shop**: Spend mana crystals on improvements and items
- **Purpose**: Give meaning to habit tracking through story

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