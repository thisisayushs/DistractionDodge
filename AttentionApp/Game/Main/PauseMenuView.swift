import SwiftUI

struct PauseMenuView: View {
    @ObservedObject var viewModel: AttentionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showIntroduction = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.8), .purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 35) {
                Text("Game Paused")
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    Button {
                        dismiss()
                        viewModel.resumeGame()
                    } label: {
                        MenuButton(title: "Resume", icon: "play.fill")
                    }
                    
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.startGame()
                        }
                    } label: {
                        MenuButton(title: "Restart", icon: "arrow.clockwise")
                    }
                    
                    Button {
                        showIntroduction = true
                    } label: {
                        MenuButton(title: "Start Over", icon: "arrow.left")
                    }
                }
            }
            .padding(40)
        }
        .presentationBackground(.clear)
        .presentationCornerRadius(35)
        .interactiveDismissDisabled() 
        .fullScreenCover(isPresented: $showIntroduction) {
            OnboardingView()
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.system(.title3, design: .rounded))
                .bold()
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}
