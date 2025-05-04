import SwiftUI

struct BackgroundView: View {
    let currentPage: Int
    let colors: [(start: Color, end: Color)]
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colors[currentPage].start,
                colors[currentPage].end
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: currentPage)
    }
}