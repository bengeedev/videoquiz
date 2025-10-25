# VideoQuiz iOS

A modern word puzzle game for iOS where players solve puzzles by filling in letter slots with the correct word, enhanced with video clues.

## Overview

VideoQuiz is an engaging word puzzle game that challenges players to guess words based on visual clues (images or videos). Players tap letters to fill in the slots, earning coins for correct answers and using hints when stuck.

## Current Features

### Core Gameplay
- **Word Puzzles**: Fill in letter slots to complete words
- **Visual Clues**: Images and video support for puzzle hints
- **Progressive Difficulty**: Multiple levels with increasing complexity
- **Coin System**: Earn coins by completing levels
- **Hint System**: Multiple hint types to help solve difficult puzzles
  - Remove incorrect letters
  - Reveal correct letters
  - Skip level

### UI/UX
- **Clean Interface**: Modern, programmatic UIKit-based design
- **Smooth Animations**: Success/error feedback with spring animations
- **Modal System**: Dedicated screens for hints, gifts, achievements, and more
- **Progress Tracking**: Level completion and streak tracking

### Bonus Features
- **Achievement System**: Unlock achievements as you progress
- **Spin Wheel**: Random coin rewards (placeholder for monetization)
- **Scratch Cards**: Mini-game for bonus coins
- **Daily Gifts**: Reward system for engagement

## Project Structure

```
videoquiz iOS/
├── App/                  - Application entry point
├── Models/               - Data models (Level, etc.)
├── ViewModels/           - Business logic layer
├── Views/                - UI components
│   ├── AchievementCell
│   ├── GameBoardManager
│   ├── GameToolbarView
│   └── VideoOverlayView
├── ViewControllers/      - Screen controllers
│   ├── GameViewController
│   └── MenuViewController
├── Modals/               - Modal view controllers
│   ├── Achievement, Coin, Gift, Hint
│   ├── NextLevel, WatchAd, Win
│   └── ScratchCard, SpinWheel
├── Managers/             - Feature managers
│   └── AchievementManager
├── Utils/                - Utilities and constants
│   ├── Animations
│   └── Constants
└── Resources/            - Assets and data
    ├── levels_en.json
    └── Videos/
```

## Tech Stack

- **Language**: Swift
- **UI Framework**: UIKit (100% programmatic)
- **Architecture**: MVVM pattern
- **Data Storage**: UserDefaults for progress, JSON for level data
- **Minimum iOS**: iOS 14+

## Current State

### ✅ Implemented
- Complete game loop (menu → game → level completion)
- Letter slot and keyboard interaction
- Coin earning and tracking
- Basic achievement system
- Video playback support
- Multiple modal screens
- Animation system
- Level progression

### 🚧 In Progress
- Theme-based level organization (Food, Animals, Objects, etc.)
- Enhanced achievement unlock logic
- Improved UI/UX polish

### 📋 Planned Features
- **Monetization**
  - In-app purchases for coin bundles
  - Rewarded video ads integration
  - Remove ads purchase option

- **Game Features**
  - GameCenter integration (leaderboards, achievements)
  - Multi-language support (i18n)
  - More puzzle themes
  - Daily challenges

- **Polish**
  - Tutorial/onboarding for first-time players
  - Sound effects and music
  - Enhanced animations
  - iPad optimization

## Development

### Prerequisites
- Xcode 16.2+
- iOS 14.0+ deployment target
- Swift 5.0+

### Building
1. Clone the repository
2. Open `videoquiz.xcodeproj` in Xcode
3. Select the `videoquiz iOS` target
4. Build and run (⌘R)

### Adding Levels
Levels are defined in `Resources/levels_en.json`. Each level requires:
```json
{
  "id": 1,
  "image": "image_name",  // or "video": "video_name"
  "word": "ANSWER",
  "extraLetters": ["A", "B", "C", ...]
}
```

## Architecture Highlights

### Clean Separation
- **Models**: Pure data structures
- **ViewModels**: Business logic, no UI references
- **Views**: Reusable UI components
- **ViewControllers**: Coordination and user interaction

### Game Flow
```
Menu → Theme Selection (planned) → Game → Level Complete → Next Level
                                     ↓
                              Hints/Achievements/Gifts
```

### State Management
- Level progress stored in UserDefaults
- Coin balance persisted across sessions
- Achievement tracking
- Streak counting

## Contributing

This is currently a private project. If you have access and want to contribute:
1. Create a feature branch
2. Follow the existing code structure
3. Ensure all files are in the correct folders
4. Test thoroughly before committing

## License

Proprietary - All rights reserved

## Contact

For questions or issues, please contact the development team.

---

*Last updated: October 2025*
