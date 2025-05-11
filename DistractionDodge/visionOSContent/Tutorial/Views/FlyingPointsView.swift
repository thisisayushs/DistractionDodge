//
//  FlyingPointsView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI

/// A view that displays a `FlyingPoint` model.
///
/// This view animates the text upwards and fades it out on appear.
public struct FlyingPointsView: View {
    /// The `FlyingPoint` data model to display.
    let point: FlyingPoint
    /// The current opacity of the text, animated on appear.
    @State private var opacity: Double = 1.0
    /// The vertical offset of the text, animated on appear to create an upward motion.
    @State private var offsetY: CGFloat = 0

    /// Initializes a new `FlyingPointsView`.
    /// - Parameter point: The `FlyingPoint` data to render.
    public init(point: FlyingPoint) {
        self.point = point
    }

    /// The body of the `FlyingPointsView`.
    public var body: some View {
        Text(point.text)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundColor(.yellow)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            .position(x: point.position.x, y: point.position.y + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: FlyingPoint.animationDuration)) {
                    offsetY = -60
                    opacity = 0
                }
            }
    }
}
#endif
