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

// Preview (requires a sample Distraction)
struct VisionOSDistractionView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDistractionCalendar = Distraction(
            position: .zero,
            title: "Upcoming: Project Sync",
            message: "Meeting in 15 minutes. Agenda includes Q2 planning and feature review.",
            appIcon: "calendar.badge.clock",
            iconColors: [Color.orange, Color.red],
            soundID: 0
        )

        let sampleDistractionMessages = Distraction(
            position: .zero,
            title: "New Message from Jane",
            message: "Hey! Are you free to catch up later today? Let me know!",
            appIcon: "message.fill",
            iconColors: [Color.green, Color.mint],
            soundID: 0
        )
        
        ZStack {
            // A slightly more visionOS-like preview background
            LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // VStack to show multiple previews if needed
            VStack(spacing: 20) {
                Text("VisionOS Distraction Preview")
                    .font(.title2)
                    .padding(.bottom, 20)
                    .foregroundColor(.white.opacity(0.8))

                VisionOSDistractionView(distraction: sampleDistractionCalendar)
                VisionOSDistractionView(distraction: sampleDistractionMessages)
            }
        }
        .previewLayout(.fixed(width: 400, height: 400)) // Adjust preview size
    }
}
#endif
