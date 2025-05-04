import SwiftUI

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

