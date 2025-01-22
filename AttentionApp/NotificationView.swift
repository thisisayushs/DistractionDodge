import SwiftUI

struct GlassBackground: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.15)
            
            // Blur effect
            Rectangle()
                .fill(Color.white)
                .opacity(0.05)
                .blur(radius: 10)
            
            // Subtle gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct NotificationView: View {
    let distraction: Distraction
    let index: Int
    @EnvironmentObject var viewModel: AttentionViewModel
    @State private var isHovered = false
    @State private var isDismissing = false
    
    var body: some View {
        // Content wrapper to handle taps on the entire notification
        Button(action: {
            withAnimation {
                viewModel.handleDistractionTap()
            }
        }) {
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
                            .foregroundColor(.white)
                        Text(distraction.message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Modified close button with game over trigger
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isDismissing = true
                            // Add delay to allow animation to complete before game over
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.handleDistractionTap()
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .opacity(isHovered ? 1 : 0.7)
                    }
                    // Prevent the parent tap from triggering
                    .buttonStyle(PlainButtonStyle())
                    // Stop tap from propagating to parent
                    .allowsHitTesting(true)
                }
                .padding()
            }
        }
        // Use plain style to keep custom appearance
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                GlassBackground()
                    .cornerRadius(14)
                
                // Subtle border
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            }
        )
        .frame(width: 300)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .rotationEffect(isDismissing ? .degrees(10) : .zero)
        .opacity(isDismissing ? 0 : 1)
        .offset(x: isDismissing ? 100 : 0)
        .modifier(NotificationAnimation(index: index))
    }
}

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

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            NotificationView(
                distraction: Distraction(
                    position: .zero,
                    title: "Message",
                    message: "New message from John",
                    appIcon: "message.fill",
                    iconColors: [.green, .blue],
                    soundID: 1007
                ),
                index: 0
            )
        }
    }
}
