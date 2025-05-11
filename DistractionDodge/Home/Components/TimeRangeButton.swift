//
//  TimeRangeButton.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI

/// A styled button for time range selection.
/// - Supports selected/unselected states
/// - Provides consistent styling with capsule shape
/// - Includes hover and pressed states
struct TimeRangeButton: View {
    /// Button text
    let title: String
    /// Whether button represents currently selected time range
    let isSelected: Bool
    /// Action to perform when tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isSelected ? .white : .white.opacity(0.15))
                        .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 5)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        #if os(visionOS)
        .buttonStyle(.plain)
        #endif
    }
}
