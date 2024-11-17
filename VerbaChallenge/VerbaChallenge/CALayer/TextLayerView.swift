//
//  TextLayerView.swift
//  VerbaChallenge
//
//  Created by Ilya Bykov on 17/11/2024.
//

import SwiftUI

struct TextLayerView: UIViewRepresentable {
    let text: String
    let origin: CGPoint

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 56
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.frame = CGRect(x: origin.x, y: origin.y, width: 200, height: 100)
        view.layer.addSublayer(textLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
