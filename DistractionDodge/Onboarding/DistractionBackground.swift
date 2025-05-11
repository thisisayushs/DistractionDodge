//
//  DistractionBackground.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 2/11/25.
//
#if os(iOS)
import SwiftUI

/// A view that creates an animated background with floating circles.
///
/// DistractionBackground provides:
/// - Randomly positioned translucent circles
/// - Gentle floating animation using HoverMotion
/// - Visual depth and movement to backgrounds
///
/// Usage:
/// ```swift
/// ZStack {
///     DistractionBackground()
///     // Your content
/// }
/// ```
struct DistractionBackground: View {
    // MARK: - Properties
    
    /// Controls the animation state of floating circles
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        // ADD: GeometryReader to get the available size
        GeometryReader { geometry in
            ZStack {
                // Generate multiple floating circles
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 10...30))
                        .position(
                            // CHANGE: Use geometry proxy for dimensions
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .modifier(HoverMotion(isAnimating: isAnimating))
                }
            }
            // Move onAppear inside GeometryReader or attach to ZStack
            .onAppear {
                // Start animation only if geometry size is valid
                if geometry.size != .zero {
                    isAnimating = true
                }
            }
            // Optional: Add onChange to handle potential size changes
            .onChange(of: geometry.size) { oldSize, newSize in
                if newSize != .zero && !isAnimating {
                    // Start animation if size becomes valid and not already animating
                    isAnimating = true
                } else if newSize == .zero && isAnimating {
                    // Optionally stop animation if size becomes zero?
                    // isAnimating = false
                }
            }
        }
        // Keep ignoresSafeArea if needed by the parent context, but often better applied by the parent
        // .ignoresSafeArea() // Example: Can be added here or by the view using DistractionBackground
    }
}
#endif
