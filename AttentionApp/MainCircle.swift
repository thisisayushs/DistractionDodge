import SwiftUI

struct MainCircle: View {
    let isGazingAtTarget: Bool
    let position: CGPoint
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: isGazingAtTarget ?
                                     [.green, .mint] : [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 200)
            .scaleEffect(isGazingAtTarget ? 1.2 : 1.0)
            .shadow(color: isGazingAtTarget ? .green.opacity(0.5) : .blue.opacity(0.5),
                    radius: isGazingAtTarget ? 15 : 10)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .position(x: position.x, y: position.y)
            .animation(.easeInOut(duration: 2), value: position)
            .animation(.easeInOut(duration: 0.3), value: isGazingAtTarget)
    }
}

// End of file
