//
//  IdleBreathing.swift
//  Yes? No? Go!
//
//  A slow, continuous breathe used to keep hero elements alive at rest.
//

import SwiftUI

extension View {
    @ViewBuilder
    func idleBreathing(_ isActive: Bool, scale: CGFloat = 1.03, duration: Double = 2.6) -> some View {
        if isActive {
            phaseAnimator([false, true]) { content, lifted in
                content.scaleEffect(lifted ? scale : 1)
            } animation: { _ in
                .easeInOut(duration: duration)
            }
        } else {
            self
        }
    }
}
