import SwiftUI
import AVFoundation

// Move Distraction model to its own file
struct Distraction: Identifiable {
    let id = UUID()
    var position: CGPoint
    var title: String
    var message: String
    var appIcon: String
    var iconColors: [Color]
    var soundID: SystemSoundID
}

// End of file
