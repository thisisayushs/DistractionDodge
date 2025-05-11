//
//  ChartContainer.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI

/// A reusable container view for charts with consistent styling.
/// - Provides title and content area
/// - Applies glass-like background effect
/// - Adds consistent padding and shadows
struct ChartContainer<Content: View>: View {
    /// Title displayed above chart content
    let title: String
    /// Chart content view
    let content: Content
    
    /// Creates a new chart container.
    /// - Parameters:
    ///   - title: Title text displayed above content
    ///   - content: Chart view builder closure
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            content
                .frame(height: 180)
                .padding(.horizontal, 5)
        }
        .padding(20)
        .frame(maxWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 15)
        )
    }
}
