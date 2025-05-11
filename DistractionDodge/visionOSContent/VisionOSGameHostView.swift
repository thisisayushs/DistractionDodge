//
//  VisionOSGameHostView.swift
//  DistractionDodge
//
//  Created by Alex (AI Assistant) on 5/11/25.
//

import SwiftUI
import SwiftData

#if os(visionOS)
struct VisionOSGameHostView: View {
    @Environment(\.modelContext) private var modelContext
    let duration: Double
    @ObservedObject var healthKitManager: HealthKitManager

    var body: some View {
        visionOSContentView(duration: duration, modelContext: modelContext, healthKitManager: healthKitManager)
    }
}
#endif
