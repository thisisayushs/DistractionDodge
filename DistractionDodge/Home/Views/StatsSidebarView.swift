//
//  StatsSidebarView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI

/// Sidebar view displaying session statistics and HealthKit integration.
/// - Shows game count, best score, and best streak
/// - Manages HealthKit authorization and sync
/// - Handles error states and settings
struct StatsSidebarView: View {
    /// Array of completed game sessions
    let sessions: [GameSession]
    /// All-time longest streak for iOS (time-based)
    let longestIOSStreak: TimeInterval
    /// All-time longest streak for visionOS (count-based)
    let longestVisionOSStreak: Double
    
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Formats time interval into human-readable string
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string (e.g. "2m 30s")
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0s" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 && remainingSeconds > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(remainingSeconds)s"
        }
    }
    
    /// Initiates HealthKit authorization and sync process
    private func syncToHealth() {
        healthKitManager.syncHistoricalSessions(sessions)
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
            
            #if os(visionOS)
            StatCard(
                title: "Best Streak",
                value: "\(Int(longestVisionOSStreak))",
                icon: "sparkles"
            )
            #else
            StatCard(
                title: "Best Streak",
                value: formatTime(longestIOSStreak),
                icon: "bolt.fill"
            )
            #endif

            Button(action: syncToHealth) {
                HStack(spacing: 12) {
                    if healthKitManager.isAuthorizing {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } else if healthKitManager.isSynced {
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
                    
                    Text(healthKitManager.isSynced ? "Synced to Apple Health" : "Sync to Apple Health")
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
            #if os(visionOS)
            .buttonStyle(.plain)
            #endif
            .disabled(healthKitManager.isAuthorizing)
            .alert("Health Access Denied", isPresented: $healthKitManager.showSettingsAlert) {
                Button("Open Settings", role: .none) { 
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                         UIApplication.shared.open(url)
                    } else if let url = URL(string: "x-apple-health://") { 
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable Health access in Settings to sync your mindful minutes.") 
            }
            .alert("Could not sync with Health", isPresented: $healthKitManager.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please make sure Health access is enabled for the app in Settings and that Health data is available on this device.") 
            }
        }
    }
}
