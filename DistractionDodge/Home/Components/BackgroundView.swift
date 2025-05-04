import SwiftUI

/// A view that provides animated gradient backgrounds.
/// - Supports smooth transitions between color schemes
/// - Fills entire safe area
struct BackgroundView: View {
    /// Current page index determining gradient colors
    let currentPage: Int
    /// Array of gradient color pairs (start, end)
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
