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

    var body: some View {
            if puzzle.state != .solved {
                Text(puzzle.question).font(.largeTitle)
                if let tip = puzzle.tip {
                    Text(tip).font(.footnote)
                }
                HStack(spacing: 20) {
                    TextField("Solution", text: $solution)
                        .disableAutocorrection(true)
                        .modifier(ShakeEffect(shakes: invalidAttempts * 2))
                    Button("Check") {
                        do {
                            let hint = try decrypt(value: puzzle.encrypted, solution: solution, type: EncryptedValue.self)
                            withAnimation {
                                puzzle.state = .solved
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
}

struct PuzzleView_Previews: PreviewProvider {
    @State static var puzzle = Puzzle.forPreview(slug: "marquee", number: "16")
    static var previews: some View {
        PuzzleView( puzzle: $puzzle.wrappedValue).preferredColorScheme(.light)
        PuzzleView( puzzle: $puzzle.wrappedValue).preferredColorScheme(.dark)
    }
}
