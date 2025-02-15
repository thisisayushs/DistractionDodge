import SwiftUI
import AVFoundation

struct TextAnimator: View {
    let text: String
    let index: Int
    @Binding var activeIndex: Int
    @State private var displayedText = ""
    @State private var timer: Timer? = nil
    var onFinished: () -> Void
    private let typingInterval: TimeInterval = 0.05
    private let soundDelay: TimeInterval = 0.02
    
    var body: some View {
        HStack {
            
            Text(displayedText)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            
            if index == activeIndex {
                startTyping()
                
            }
        }
        .onChange(of: activeIndex) { _, newValue in
            
            if index == newValue {
                startTyping()
            }
        }
        .onDisappear {
            
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTyping() {
        
        displayedText = ""
        timer?.invalidate()
        
        var charIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: typingInterval, repeats: true) { timer in
            guard charIndex < self.text.count else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.onFinished()
                }
                return
            }
            
            let textIndex = self.text.index(self.text.startIndex, offsetBy: charIndex)
            let currentChar = String(self.text[textIndex])
            
            displayedText = String(self.text[...textIndex])
            charIndex += 1
            if !["", " ", ".", ",", "!", "?"].contains(currentChar) {
                DispatchQueue.main.asyncAfter(deadline: .now() + soundDelay) {
                    AudioServicesPlaySystemSound(1104)
                }
            }
        }
    }
}
