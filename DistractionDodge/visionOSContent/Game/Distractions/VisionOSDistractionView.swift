//
//  VisionOSDistractionView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//

#if os(visionOS)
import SwiftUI
/// A view that displays a distraction notification, specifically styled for visionOS.
///
/// This view takes a `Distraction` object and presents its content (icon, title, message)
/// within a glass-like rounded rectangle, mimicking a system notification.
/// It's designed to be compact and visually distinct.
struct VisionOSDistractionView: View {
    /// The distraction data to display in the notification.
    /// This `Distraction` struct is expected to be defined elsewhere, likely in the core game logic.
    let distraction: Distraction // Distraction struct needs to be public or accessible

    /// Initializes a new `VisionOSDistractionView`.
    /// - Parameter distraction: The `Distraction` model containing the data to display.
    init(distraction: Distraction) { 
        self.distraction = distraction
    }

    /// The body of the `VisionOSDistractionView`.
    var body: some View {
        HStack(alignment: .top, spacing: 12) { // Align icon with top of text block, add spacing
            Image(systemName: distraction.appIcon)
                .font(.system(size: 20)) // Icon font size
                .frame(width: 36, height: 36) // Icon frame size
                .foregroundStyle(LinearGradient(colors: distraction.iconColors, startPoint: .top, endPoint: .bottom))
                .background(.thinMaterial.opacity(0.7))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) { // VStack for title and message
                Text(distraction.title)
                    .font(.subheadline.weight(.semibold)) // Font for title
                    .foregroundColor(.primary)
                    .lineLimit(1) // Ensure title is one line

                Text(distraction.message)
                    .font(.caption) // Font for message
                    .foregroundColor(.secondary)
                    .lineLimit(1, reservesSpace: true) // Limits to one line, reserving space for it.
                    .fixedSize(horizontal: false, vertical: true) // Ensures the text view takes its ideal vertical space for the single line.
            }
        }
        .padding(12) // Padding around the HStack content, inside the glass background
        .frame(width: 250, height: 88) // Frame for a compact, wider notification style
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 18)) // Corner radius for glass
        
        .transition(.scale(scale: 0.9, anchor: .center).combined(with: .opacity)) // Scale and opacity animation
    }
}
#endif
