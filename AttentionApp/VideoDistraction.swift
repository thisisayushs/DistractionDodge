import SwiftUI

struct VideoContent: Identifiable {
    let id = UUID()
    let title: String
    let username: String
    let description: String
    let gradientColors: [Color]
    let emojis: [String]
    let symbols: [String]
}

struct FloatingElement: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    let content: String
}

struct VideoDistraction: View {
    @State private var offset: CGFloat = 0
    @State private var currentIndex = 0
    @State private var floatingElements: [FloatingElement] = []
    
    let videos = [
        VideoContent(
            title: "Amazing Dance Moves! 🔥",
            username: "@dancepro",
            description: "Check out these incredible moves! #dance #viral",
            gradientColors: [.purple, .pink],
            emojis: ["💃", "🕺", "🎵", "✨"],
            symbols: ["flame.fill", "star.fill", "bolt.fill"]
        ),
        VideoContent(
            title: "Funny Cat Compilation 😹",
            username: "@catvideos",
            description: "You won't believe what these cats did! #cats #funny",
            gradientColors: [.blue, .green],
            emojis: ["😹", "🐱", "🙀", "🎭"],
            symbols: ["pawprint.fill", "heart.fill", "face.smiling"]
        ),
        VideoContent(
            title: "Epic Stunts! 💪",
            username: "@extremesports",
            description: "Don't try this at home! #extreme #sports",
            gradientColors: [.orange, .red],
            emojis: ["🏄‍♂️", "🚴‍♀️", "🏂", "🤸‍♂️"],
            symbols: ["speedometer", "flag.fill", "trophy.fill"]
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
                
                // Floating elements container with clipping
                ZStack {
                    ForEach(floatingElements) { element in
                        Text(element.content)
                            .font(.system(size: 30))
                            .position(element.position)
                            .scaleEffect(element.scale)
                            .rotationEffect(.degrees(element.rotation))
                    }
                }
                .clipped() // Add clipping to contain floating elements
                
                VStack(alignment: .leading, spacing: 15) { // Increased spacing
                    Spacer()
                    
                    // Video title with padding
                    Text(videos[currentIndex].title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(.horizontal, 10)
                    
                    // Username with padding
                    Text(videos[currentIndex].username)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                    
                    // Description with padding
                    Text(videos[currentIndex].description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    
                    // Mock interaction buttons with padding
                    HStack(spacing: 20) { // Increased spacing between buttons
                        ForEach(["heart.fill", "message.fill", "arrow.2.squarepath"], id: \.self) { symbolName in
                            Image(systemName: symbolName)
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15) // Added bottom padding
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.6)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 10)
            .offset(y: offset)
            .onAppear {
                startAnimations(in: geometry)
            }
        }
    }
    
    private func startAnimations(in geometry: GeometryProxy) {
        // Store geometry values locally
        let width = geometry.size.width
        let height = geometry.size.height
        
        // Vertical bouncing animation
        withAnimation(
            Animation
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            offset = 30
        }
        
        // Change video content periodically
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % videos.count
                // Use stored values instead of geometry directly
                resetFloatingElements(width: width, height: height)
            }
        }
        
        // Initial floating elements
        resetFloatingElements(width: width, height: height)
        
        // Animate floating elements
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                // Use stored values instead of geometry directly
                updateFloatingElements(height: height)
            }
        }
    }
    
    // Updated to accept width and height instead of GeometryProxy
    private func resetFloatingElements(width: CGFloat, height: CGFloat) {
        let currentVideo = videos[currentIndex]
        floatingElements = (currentVideo.emojis + currentVideo.symbols).map { content in
            FloatingElement(
                position: CGPoint(
                    x: CGFloat.random(in: 0...width),
                    y: CGFloat.random(in: 0...height)
                ),
                scale: CGFloat.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                content: content
            )
        }
    }
    
    // Updated to accept height instead of GeometryProxy
    private func updateFloatingElements(height: CGFloat) {
        for i in floatingElements.indices {
            floatingElements[i].position.y -= CGFloat.random(in: 1...3)
            floatingElements[i].rotation += Double.random(in: -5...5)
            floatingElements[i].scale += CGFloat.random(in: -0.05...0.05).clamped(to: 0.5...1.5)
            
            if floatingElements[i].position.y < 0 {
                floatingElements[i].position.y = height
            }
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
