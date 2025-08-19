# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift Island iOS app - official app for Swift Island conference. Built with SwiftUI targeting iOS 16+, using Xcode 14+. 

**Core Architecture:**
- **Main App** (`SwiftIslandApp/`): SwiftUI views, utilities, resources
- **Data Logic** (`SwiftIslandDataLogic/`): Swift Package managing Firebase/static JSON data fetching
- **Widgets** (`SwiftIslandWidgets/`): iOS widgets for conference schedule

## Key Commands

**Build & Run:**
```bash
# Build in Xcode (no CLI build script available)
# Set SWIFTISLAND_BRANCH environment variable in scheme for different branch content
```

**Testing:**
```bash
# Run tests through Xcode Test Navigator
# Test plan: SwiftIsland.xctestplan
```

**Linting:**
- Uses SwiftLint with custom rules (see README.md)
- Line limit: 200 chars warning, 300 error
- Indentation: 4 spaces
- Force unwrapping allowed for URL literals and previews only

## Data Architecture

**Static Content System:**
- JSON files in `/api/` directory serve as backend
- `DataSync.swift` handles branch-aware fetching via GitHub raw URLs
- Content comes from `main` branch by default, configurable via `SWIFTISLAND_BRANCH` env var
- ETag-based caching with local file storage in Application Support

**Data Flow:**
1. `SwiftIslandDataLogic` package fetches from static JSON endpoints (automatically adds "api/" prefix)
2. `AppDataModel` manages app state and coordinates data fetching
3. Views consume data through published properties
4. Remote images are downloaded automatically after fetching mentors

**Key Entities:**
- `Event`/`Activity`: Schedule items (Activity = template, Event = instance)
- `Mentor`: Speaker/mentor information
- `Location`: Venue/map data
- `Ticket`: Tito integration for attendee tickets
- `Puzzle`: Conference puzzles/games

## Firebase Integration

- `GoogleService-Info.plist` required for Firebase configuration
- `SwiftIslandDataLogic.configure()` must be called at launch
- Some legacy Firebase requests remain in codebase

## Secrets Management

- `Secrets.json` file (gitignored) contains Tito API credentials
- Structure: `{"CHECKIN_LIST_SLUG": "tito-slug"}`
- Accessed via `Secrets` enum in `AppDataModel.swift`

## Branch Strategy

Current branch: `feature/static-backend` - implements static JSON backend replacing Firebase for content.

## Code Style Notes

- Follows Kodeco Swift Style Guide with exceptions
- SwiftUI views organized by feature areas
- Minimal force unwrapping (URL literals and previews only)
- Extensive use of `@Published` properties for reactive UI