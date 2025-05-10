//
//  VisionOSDistractionView.swift
//  DistractionDodge
//  Created by Alex (AI Assistant) on 5/11/25. // Or your name/date
//

import SwiftUI

#if os(visionOS)
struct VisionOSDistractionView: View {
    let distraction: Distraction

    var body: some View {
        HStack(alignment: .top, spacing: 12) { // Align icon with top of text block, add spacing
            Image(systemName: distraction.appIcon)
                .font(.system(size: 20)) // ADJUSTED: Icon font size for better proportion
                .frame(width: 36, height: 36) // ADJUSTED: Icon frame size
                .foregroundStyle(LinearGradient(colors: distraction.iconColors, startPoint: .top, endPoint: .bottom))
                .background(.thinMaterial.opacity(0.7))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) { // VStack for title and message
                Text(distraction.title)
                    .font(.subheadline.weight(.semibold)) // ADJUSTED: Font for title
                    .foregroundColor(.primary)
                    .lineLimit(1) // Ensure title is one line

                Text(distraction.message)
                    .font(.caption) // ADJUSTED: Font for message, making it smaller
                    .foregroundColor(.secondary)
                    .lineLimit(1, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true) // Allows text to wrap and define its own height up to 2 lines
            }
            // If content needs to be pushed left within a flexible width, a Spacer here would be useful.
            // For fixed width, content will naturally fill or be aligned by parent.
        }
       // ADJUSTED: Padding for internal content
        .frame(width: 250, height: 88) // ADJUSTED: Frame for a more compact, wider notification style
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 18)) // ADJUSTED: Corner radius for glass
        
        .transition(.scale(scale: 0.9, anchor: .center).combined(with: .opacity)) // ADJUSTED: Scale animation
    }
}


#endif
