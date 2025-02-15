import SwiftUI

struct NotificationView: View {
    let distraction: Distraction
    let index: Int
    @EnvironmentObject var viewModel: AttentionViewModel
    @State private var isHovered = false
    @State private var isDismissing = false
    
    var body: some View {
        
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
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isDismissing = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.handleDistractionTap()
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .opacity(isHovered ? 1 : 0.7)
                    }
                    
                    .buttonStyle(PlainButtonStyle())
                    .allowsHitTesting(true)
                }
                .padding()
            }
        }
        
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                GlassBackground()
                    .cornerRadius(14)
                
                
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
