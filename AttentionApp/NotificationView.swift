import SwiftUI

struct NotificationAnimation: ViewModifier {
    let index: Int
    
    func body(content: Content) -> some View {
        content
            .offset(y: -20)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(Double(index) * 0.15),
                value: index
            )
    }
}

struct NotificationView: View {
    let distraction: Distraction
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: distraction.appIcon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: distraction.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(distraction.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(distraction.message)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.5))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.1),
                        radius: 5)
        )
        .frame(width: 300)
        .modifier(NotificationAnimation(index: index))
    }
}

// End of file
