import SwiftUI
import AVFoundation


struct Distraction: Identifiable {
    let id = UUID()
    var position: CGPoint
    var title: String
    var message: String
    var appIcon: String
    var iconColors: [Color]
    var soundID: SystemSoundID
}


