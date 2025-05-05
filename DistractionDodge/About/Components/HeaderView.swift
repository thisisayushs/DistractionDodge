import SwiftUI

/// A view component displaying the app's header information.
/// - Shows app icon with consistent styling
/// - Displays location and credibility information
/// - Applies consistent spacing and shadow effects
struct HeaderView: View {
    var body: some View {
        VStack {
            Image("Icon")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(width: 100, height: 100)
                .shadow(color: .white.opacity(0.3), radius: 10)
            
            VStack(spacing: 15) {
                Text("Made with love in Naples, Italy 🇮🇹")
                Text("Science Backed")
            }
            .padding()
            .italic()
            .font(.body)
            .foregroundStyle(.white)
          
        }
        .padding(.top, 80)
    }
}
