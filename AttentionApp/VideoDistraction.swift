import SwiftUI

// Video content model
struct VideoContent: Identifiable {
    let id = UUID()
    let title: String
    let username: String
    let description: String
    let gradientColors: [Color]
}

struct VideoDistraction: View {
    @State private var offset: CGFloat = 0
    @State private var currentIndex = 0
    
    // Sample video content
    let videos = [
        VideoContent(
            title: "Amazing Dance Moves! 🔥",
            username: "@dancepro",
            description: "Check out these incredible moves! #dance #viral",
            gradientColors: [.purple, .pink]
        ),
        VideoContent(
            title: "Funny Cat Compilation 😹",
            username: "@catvideos",
            description: "You won't believe what these cats did! #cats #funny",
            gradientColors: [.blue, .green]
        ),
        VideoContent(
            title: "Epic Stunts! 💪",
            username: "@extremesports",
            description: "Don't try this at home! #extreme #sports",
            gradientColors: [.orange, .red]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient animation
                LinearGradient(
                    gradient: Gradient(colors: videos[currentIndex].gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.8)
                .animation(.easeInOut(duration: 1.0), value: currentIndex)
                
                VStack(alignment: .leading, spacing: 10) {
                    Spacer()
                    
                    // Video title
                    Text(videos[currentIndex].title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    // Username
                    Text(videos[currentIndex].username)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Description
                    Text(videos[currentIndex].description)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.4)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 10)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = 50
                }
                
                // Change video content periodically
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % videos.count
                    }
                }
            }
        }
    }
}

#Preview {
    VideoDistraction()
        .frame(width: 300, height: 500)
        .background(Color.black)
}

