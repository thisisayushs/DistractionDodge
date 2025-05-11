//
//  EmptyStateView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
import SwiftUI

/// A view displayed when no statistics are available.
///
/// Features:
/// - Large iconic chart symbol with gradient
/// - Informative message about first session
/// - Glass-like container styling
/// - Consistent visual design with app theme
///
/// This view provides a visually appealing placeholder and clear
/// call-to-action for users who haven't completed any sessions.
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 25) {
            // Chart icon with gradient
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 70))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 10)
            
            // Title with gradient
            Text("No Stats Yet")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Informative message
            Text("Complete your first focus training session\nto see your progress here!")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
        }
        // Container styling
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }
}
