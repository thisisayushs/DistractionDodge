import SwiftUI
import HealthKit

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
    /// HealthKit sync status
    @Binding var isSynced: Bool
    /// HealthKit authorization status
    @Binding var isAuthorizing: Bool
    /// Error alert presentation flag
    @Binding var showError: Bool
    /// Settings sheet presentation flag
    @Binding var showSettings: Bool
    @Environment(\.healthStore) private var healthStore
    
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
        guard HKHealthStore.isHealthDataAvailable() else {
            showError = true
            return
        }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let currentStatus = healthStore.authorizationStatus(for: mindfulType)
        
        if currentStatus == .notDetermined {
            isAuthorizing = true // Show progress indicator
            healthStore.requestAuthorization(toShare: [mindfulType], read: []) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Permission granted, now write historical data
                        self.writeHistoricalDataToHealthKit { writeSuccess in
                            // The writeSuccess parameter indicates if the batch save was generally successful
                            // Individual errors are logged within writeHistoricalDataToHealthKit
                            if writeSuccess {
                                withAnimation { self.isSynced = true }
                            } else {
                                // Optionally, show a more specific error if the batch write failed
                                self.showError = true // Using generic error for now
                            }
                            self.isAuthorizing = false // Hide progress indicator
                        }
                    } else {
                        self.showError = true
                        self.isAuthorizing = false // Hide progress indicator
                    }
                }
            }
        } else if currentStatus == .sharingAuthorized {
            // Already authorized, user might be tapping to ensure historical data is synced
            // or if isSynced state variable was false for some reason.
            isAuthorizing = true // Show progress indicator
            self.writeHistoricalDataToHealthKit { writeSuccess in
                DispatchQueue.main.async {
                    if writeSuccess {
                        withAnimation { self.isSynced = true }
                    } else {
                        self.showError = true
                    }
                    self.isAuthorizing = false // Hide progress indicator
                }
            }
        } else { // currentStatus is .sharingDenied
            showSettings = true // Prompt user to go to settings
        }
    }
    
    private func writeHistoricalDataToHealthKit(completion: @escaping (Bool) -> Void) {
        guard !sessions.isEmpty else {
            print("HealthKit Sync: No historical sessions to write.")
            completion(true) // Nothing to sync, consider it a success
            return
        }

        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        var samplesToSave: [HKCategorySample] = []

        for session in sessions {
            // session.totalFocusTime is already platform-specific:
            // - For visionOS, it's actualPlayedDuration.
            // - For iOS, it's the eye-gaze totalFocusTime.
            guard session.totalFocusTime > 0 else {
                print("HealthKit Sync: Skipping session with zero duration: \(session.date)")
                continue
            }

            let endDate = session.date // This is the completion date of the session
            let startDate = endDate.addingTimeInterval(-session.totalFocusTime)
            
            let sample = HKCategorySample(
                type: mindfulType,
                value: HKCategoryValue.notApplicable.rawValue,
                start: startDate,
                end: endDate
            )
            samplesToSave.append(sample)
        }

        guard !samplesToSave.isEmpty else {
            print("HealthKit Sync: No valid historical sessions with positive duration to save.")
            completion(true) // No valid samples to save, consider it success for flow
            return
        }
        
        healthStore.save(samplesToSave) { success, error in
            if let error = error {
                print("HealthKit Sync: Error saving batch of \(samplesToSave.count) historical mindful minutes: \(error.localizedDescription)")
                completion(false)
            } else if success {
                print("HealthKit Sync: Successfully saved batch of \(samplesToSave.count) historical mindful sessions.")
                completion(true)
            } else {
                // This case should ideally not happen if error is nil and success is false,
                // but as a fallback:
                print("HealthKit Sync: Saving batch of historical mindful minutes failed for an unknown reason.")
                completion(false)
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
            #if os(visionOS)
            .buttonStyle(.plain)
            #endif
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
