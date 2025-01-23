import SwiftUI

struct TypewriterText: View {
    let text: String
    let index: Int
    @Binding var activeIndex: Int
    @State private var displayedText = ""
    @State private var timer: Timer? = nil
    var onFinished: () -> Void
    
    var body: some View {
        HStack {
            // Add left-to-right slide in animation
            Text(displayedText)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            // Start animation if this is the active index
            if index == activeIndex {
                startTyping()
            }
        }
        .onChange(of: activeIndex) { _, newValue in
            // Start animation when this becomes the active index
            if index == newValue {
                startTyping()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTyping() {
        // Reset state
        displayedText = ""
        timer?.invalidate()
        
        var charIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard charIndex < self.text.count else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onFinished()
                }
                return
            }
            
            let textIndex = self.text.index(self.text.startIndex, offsetBy: charIndex)
            displayedText = String(self.text[...textIndex])
            charIndex += 1
        }
    }
}
