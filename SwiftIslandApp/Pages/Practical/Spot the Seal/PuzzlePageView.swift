//
// Created by Niels van Hoorn for the use in the Swift Island app
// Copyright © 2023 AppTrix AB. All rights reserved.
//

import SwiftUI
import Defaults
import SwiftIslandDataLogic

extension Defaults.Keys {
    static let puzzleStatus = Key<[String: PuzzleState]>("puzzleStatus", default: [:])
    static let puzzleHints = Key<[String: String]>("puzzleHints", default: [:])
}

enum PuzzleState: String, Defaults.Serializable {
    case notFound = "Not Found"
    case found = "Found"
    case nearby = "Nearby"
    case activated = "Activated"
    case solved = "Solved"

    var next: PuzzleState {
        switch self {
        // Not all states are currently used, they were part of an more elaborate flow we had in mind initially. Currently we only use .NotFound, .Found and .Solved
        case .notFound: return .found
        case .found: return .nearby
        case .nearby: return .activated
        case .activated: return .solved
        case .solved: return .notFound
        }
    }
}

extension Puzzle {
    var state: PuzzleState {
        get {
            Defaults[.puzzleStatus][slug] ?? .notFound
        }
        set(newValue) {
            Defaults[.puzzleStatus][slug] = newValue
        }
    }
    var color: Color {
        switch state {
        case .notFound: return .clear
        case .found, .nearby: return .questionMarkColor
        case .activated: return .yellowDark
        case .solved: return .green
        }
    }
}


struct PuzzleGrid: View {
    @EnvironmentObject private var appDataModel: AppDataModel
    let currentPuzzleSlug: String?
    private let spacing: CGFloat = 0
    private let columns = Array(repeatElement(GridItem(.flexible(minimum: 44), spacing: 0), count: 4))
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(appDataModel.puzzles) { puzzle in
                NavigationLink(value: puzzle) {
                    PuzzleItemView(puzzle: puzzle, isCurrent: (puzzle.slug == currentPuzzleSlug))
                }
                .disabled(puzzle.state == .notFound)
            }
        }
        .padding(20)
        .navigationTitle("Spot the Seal")
    }
}

struct PuzzlePageView: View {
    @EnvironmentObject private var appDataModel: AppDataModel

    @Default(.puzzleStatus)
    var puzzleStatus
    @Default(.puzzleHints)
    var puzzleHints
    var body: some View {
        ScrollView {
            VStack {
                if appDataModel.puzzles.isEmpty {
                    Text("Loading...")
                } else {
                    Text("🦭 Find hidden seals around the venue! Tap them with your phone to scan and reveal a secret fact about a person at Swift Island. Find out who it is, enter their full name and make a new friend!")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    PuzzleGrid(currentPuzzleSlug: appDataModel.currentPuzzleSlug)
                }
            }
        }
        .task {
            await appDataModel.fetchPuzzles()
        }
        .navigationDestination(for: Puzzle.self) { puzzle in
            PuzzleView(puzzle: puzzle)
        }
    }
}

struct PuzzlePageView_Previews: PreviewProvider {
    static var previews: some View {
        let appDataModel = AppDataModel()
        PuzzlePageView().environmentObject(appDataModel)
    }
}
