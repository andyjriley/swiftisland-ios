//
// Created by Niels van Hoorn for the use in the Swift Island app
// Copyright © 2023 AppTrix AB. All rights reserved.
//

import SwiftUI
import PDFKit
import Defaults
import SwiftIslandDataLogic

struct EncryptedValue: Decodable, Encodable {
    let text: String
}

struct ShakeEffect: GeometryEffect {
    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: -30 * sin(position * 2 * .pi), y: 0))
    }

    init(shakes: Int) {
        position = CGFloat(shakes)
    }

    var position: CGFloat
    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }
}

struct PuzzleView: View {
    @EnvironmentObject private var appDataModel: AppDataModel

    @Environment(\.colorScheme)
    private var colorScheme

    @Default(.puzzleStatus)
    private var puzzleStatus

    @State var puzzle: Puzzle
    @State var solution: String = ""
    @State var invalidAttempts = 0
    @State var showCelebration = false

    var body: some View {
        VStack {
            if puzzle.state != .solved {
                VStack(spacing: 16) {
                    Text(puzzle.question)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                if let tip = puzzle.tip {
                    Text(tip).font(.footnote)
                }
                HStack(spacing: 20) {
                    TextField("Who is this?", text: $solution)
                        .disableAutocorrection(true)
                        .modifier(ShakeEffect(shakes: invalidAttempts * 2))
                    Button("Check") {
                        let sanitizedSolution = sanitizeInput(solution)
                        do {
                            let decryptedValue = try decrypt(value: puzzle.encrypted, solution: sanitizedSolution, type: EncryptedValue.self)
                            // Verify the decrypted name matches the sanitized input
                            let decryptedName = sanitizeInput(decryptedValue.text)
                            if decryptedName == sanitizedSolution {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showCelebration = true
                                    puzzle.state = .solved
                                }
                            } else {
                                withAnimation(.linear) {
                                    invalidAttempts += 1
                                }
                            }
                        } catch {
                            withAnimation(.linear) {
                                invalidAttempts += 1
                            }
                        }
                    }
                }
                .padding(20)
                .navigationTitle(puzzle.title)
            } else {
                Image(systemName: "checkmark.seal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.green)
                    .frame(width: 100)
            }
        }
        .overlay(
            Group {
                if showCelebration {
                    ConfettiView(emojis: puzzle.emojis ?? ["🦭"])
                }
            }
        )
    }
}

struct PuzzleView_Previews: PreviewProvider {
    @State static var puzzle = Puzzle.forPreview(slug: "marquee", number: "16")
    static var previews: some View {
        PuzzleView( puzzle: $puzzle.wrappedValue).preferredColorScheme(.light)
        PuzzleView( puzzle: $puzzle.wrappedValue).preferredColorScheme(.dark)
    }
}
