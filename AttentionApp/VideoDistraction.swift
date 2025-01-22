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
    @EnvironmentObject var viewModel: AttentionViewModel
    @State private var offset: CGFloat = 0
    @State private var currentIndex = 0
    @State private var floatingElements: [FloatingElement] = []
    @GestureState private var translation: CGFloat = 0
    
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
                
                // Floating elements container with improved visibility
                ZStack {
                    ForEach(floatingElements) { element in
                        if element.content.first?.isEmoji ?? false {
                            Text(element.content)
                                .font(.system(size: 35))
                                .position(element.position)
                                .scaleEffect(element.scale)
                                .rotationEffect(.degrees(element.rotation))
                        } else {
                            Image(systemName: element.content)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .position(element.position)
                                .scaleEffect(element.scale)
                                .rotationEffect(.degrees(element.rotation))
                        }
                    }
                }
                .clipped()
                
                VStack(alignment: .leading, spacing: 15) {
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
                    HStack(spacing: 20) {
                        ForEach(["heart.fill", "message.fill", "arrow.2.squarepath"], id: \.self) { symbolName in
                            Image(systemName: symbolName)
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.6)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 10)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold = geometry.size.height * 0.25
                        if abs(value.translation.height) > threshold {
                            withAnimation {
                                currentIndex = value.translation.height > 0 ?
                                    (currentIndex - 1 + videos.count) % videos.count :
                                    (currentIndex + 1) % videos.count
                                resetFloatingElements(width: geometry.size.width, height: geometry.size.height)
                                
                                // Add delay before game over
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.handleDistractionTap()
                                }
                            }
                        }
                    }
            )
            .onTapGesture {
                viewModel.handleDistractionTap()
            }
            .onAppear {
                startAnimations(in: geometry)
                // Initial elements with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    resetFloatingElements(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .onDisappear {
                // Clean up timers
                invalidateTimers()
            }
        }
    }
    
    // Add timer properties
    @State private var contentTimer: Timer?
    @State private var animationTimer: Timer?
    
    private func invalidateTimers() {
        contentTimer?.invalidate()
        animationTimer?.invalidate()
        contentTimer = nil
        animationTimer = nil
    }
    
    private func startAnimations(in geometry: GeometryProxy) {
        // Store geometry values
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
        
        // Improved content timer
        invalidateTimers()
        contentTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % videos.count
                resetFloatingElements(width: width, height: height)
            }
        }
        
        // Improved animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.05)) {
                updateFloatingElements(height: height)
            }
        }
    }
    
    private func resetFloatingElements(width: CGFloat, height: CGFloat) {
        let currentVideo = videos[currentIndex]
        let elements = (currentVideo.emojis + currentVideo.symbols)
        
        // Ensure minimum number of elements
        let minimumElements = 8
        let repeatedElements = elements.count < minimumElements ?
            elements + elements : elements
        
        floatingElements = repeatedElements.map { content in
            FloatingElement(
                position: CGPoint(
                    x: CGFloat.random(in: 0...width),
                    y: CGFloat.random(in: 0...height)
                ),
                scale: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360),
                content: content
            )
        }
    }
    
    private func updateFloatingElements(height: CGFloat) {
        for i in floatingElements.indices {
            floatingElements[i].position.y -= CGFloat.random(in: 1.5...2.5)
            floatingElements[i].rotation += Double.random(in: -3...3)
            
            // Smoother scale changes
            let scaleChange = CGFloat.random(in: -0.02...0.02)
            floatingElements[i].scale = (floatingElements[i].scale + scaleChange).clamped(to: 0.8...1.2)
            
            // Reset position with offset for continuous flow
            if floatingElements[i].position.y < -50 {
                floatingElements[i].position.y = height + 50
            }
        }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = UnicodeScalar(String(self)) else { return false }
        return scalar.properties.isEmoji
    }
}

extension String {
    var isEmoji: Bool {
        count == 1 && first?.isEmoji == true
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
