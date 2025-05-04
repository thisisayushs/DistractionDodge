import SwiftUI
import HealthKit

struct StatsSidebarView: View {
    let sessions: [GameSession]
    @Binding var isSynced: Bool
    @Binding var isAuthorizing: Bool
    @Binding var showError: Bool
    @Binding var showSettings: Bool
    @Environment(\.healthStore) private var healthStore
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return seconds < 60 ? "\(Int(seconds))s" :
               "\(minutes)m \(remainingSeconds)s"
    }
    
    private func syncToHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            showError = true
            return
        }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let status = healthStore.authorizationStatus(for: mindfulType)
        
        if !isSynced {
            if status == .notDetermined {
                isSynced = false
                isAuthorizing = true
                
                healthStore.requestAuthorization(toShare: [mindfulType], read: []) { success, error in
                    DispatchQueue.main.async {
                        isAuthorizing = false
                        if success {
                            withAnimation {
                                isSynced = true
                            }
                        } else {
                            showError = true
                        }
                    }
                }
            } else {
                showSettings = true
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
                .frame(height: 100)
                
            StatCard(
                title: "Games Played",
                value: "\(sessions.count)",
                icon: "gamecontroller.fill"
            )
            
            StatCard(
                title: "Best Score",
                value: "\(sessions.map { $0.score }.max() ?? 0)",
                icon: "trophy.fill"
            )
            
            StatCard(
                title: "Best Streak",
                value: formatTime(sessions.map { $0.bestStreak }.max() ?? 0),
                icon: "bolt.fill"
            )

            Button(action: syncToHealth) {
                HStack(spacing: 12) {
                    if isAuthorizing {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } else if isSynced {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.green)
                            .shadow(color: .green.opacity(0.5), radius: 4)
                    } else {
                        Image("Icon - Apple Health")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(isSynced ? "Synced to Apple Health" : "Sync to Apple Health")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(isAuthorizing)
            .alert("Health Access Required", isPresented: $showSettings) {
                Button("Open Health", role: .none) {
                    if let url = URL(string: "x-apple-health://") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable Health access in the Health app to sync your mindful minutes.")
            }
            .alert("Could not sync with Health", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please make sure Health access is enabled for the app in Settings.")
            }
        }
    }
}