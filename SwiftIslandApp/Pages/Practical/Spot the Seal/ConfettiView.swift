//
// Created by Niels van Hoorn for the use in the Swift Island app
// Copyright © 2025 AppTrix AB. All rights reserved.
//

import UIKit
import SwiftUI

class ConfettiUIView: UIView {
    
    private let emitter = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.addSublayer(emitter)
    }
    
    func setEmojis(_ emojis: [String]) {
        var cells: [CAEmitterCell] = []
        for emoji in emojis {
            let cell = CAEmitterCell()
            cell.birthRate = Float(50 / emojis.count)
            
            cell.lifetime = 10.0
            cell.velocity = CGFloat.random(in: 200...300)
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi
            cell.spin = 5.5
            cell.spinRange = 1.0
            cell.scale = 0.6
            cell.scaleRange = 0.3

            let size = CGSize(width: 40, height: 40)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            (emoji as NSString).draw(in: CGRect(origin: .zero, size: size),
                                     withAttributes: [.font: UIFont.systemFont(ofSize: 36)])
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cell.contents = image?.cgImage
            cells.append(cell)
        }
        emitter.emitterCells = cells
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update emitter sizing/position now that we have correct bounds
        emitter.frame = bounds
        emitter.emitterShape = .point
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY) // top-center
        emitter.emitterSize = CGSize(width: bounds.width, height: 2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ConfettiView: UIViewRepresentable {
    let emojis: [String]
    init(emojis: [String] = ["🦭"]) {
        self.emojis = emojis.count == 0 ? ["🦭"] : emojis
    }
    func makeUIView(context: Context) -> ConfettiUIView {
        let view = ConfettiUIView()
        view.setEmojis(emojis)
        return view
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
    }
}
