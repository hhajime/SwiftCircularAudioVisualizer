//
//  NeonEffect.swift
//  SwiftCircularAudioVisualizer
//
//  Created by Ha Jong Myeong on 2023/04/12.
//

import SwiftUI

struct NeonEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(content
                        .blur(radius: radius)
                        .offset(x: x, y: y)
                        .blendMode(.screen))
            .overlay(content
                        .blur(radius: radius)
                        .offset(x: -x, y: -y)
                        .blendMode(.screen))
            .overlay(color)
            .blendMode(.overlay)
    }
}
