import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                    isAnimating = true
                }
            }
    }
}

struct NotificationAnimation: ViewModifier {
    let index: Int
    @State private var shake = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: -20)
            .modifier(ShakeEffect(amount: shake ? 5 : 0, animatableData: shake ? 1 : 0))
            .animation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(Double(index) * 0.15),
                value: index
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatCount(3, autoreverses: true)
                ) {
                    shake = true
                }
            }
    }
}

struct NotificationView: View {
    let distraction: Distraction
    let index: Int
    @State private var isHovered = false
    @State private var isDismissing = false
    
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
                    .modifier(PulseEffect())
                
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
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        isDismissing = true
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .opacity(isHovered ? 1 : 0.5)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.1),
                        radius: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .frame(width: 300)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .rotationEffect(isDismissing ? .degrees(10) : .zero)
        .opacity(isDismissing ? 0 : 1)
        .offset(x: isDismissing ? 100 : 0)
        .modifier(NotificationAnimation(index: index))
    }
}
