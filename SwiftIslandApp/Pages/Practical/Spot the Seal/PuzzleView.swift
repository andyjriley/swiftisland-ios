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

struct ConfettiPiece: View {
    let color: Color
    @State private var yOffset: CGFloat = -50
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let delay: Double
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 3.0).delay(delay)) {
                    yOffset = screenHeight + 100
                    xOffset = Double.random(in: -100...100)
                    rotation = Double.random(in: 0...720)
                }
                withAnimation(.easeOut(duration: 2.0).delay(delay + 1.5)) {
                    opacity = 0
                }
            }
    }
}

struct ConfettiView: View {
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(
                    color: [Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple, Color.pink].randomElement() ?? Color.red,
                    screenWidth: screenSize.width,
                    screenHeight: screenSize.height,
                    delay: Double.random(in: 0...1.0)
                )
                .position(
                    x: Double.random(in: 0...screenSize.width),
                    y: -50
                )
            }
        }
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
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        puzzle.state = .solved
                                        showCelebration = false
                                    }
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
                    GeometryReader { geometry in
                        ZStack {
                            ConfettiView(screenSize: geometry.size)
                            
                            VStack(spacing: 20) {
                                Text("🎉")
                                    .font(.system(size: 80))
                                    .scaleEffect(showCelebration ? 1.2 : 0.5)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showCelebration)
                                
                                Text("New Friend Made!")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .scaleEffect(showCelebration ? 1.0 : 0.8)
                                    .opacity(showCelebration ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showCelebration)
                            }
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        }
                    }
                    .allowsHitTesting(false)
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
