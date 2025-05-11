
import SwiftUI
import HealthKit

/// Manages HealthKit interactions, including authorization, saving mindful minutes, and syncing historical data.
@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

    /// HealthKit sync status for historical data.
    @Published var isSynced: Bool = false
    /// Indicates if HealthKit authorization is currently in progress.
    @Published var isAuthorizing: Bool = false
    /// Controls presentation of a generic error alert related to HealthKit operations.
    @Published var showError: Bool = false
    /// Controls presentation of an alert prompting the user to open Health settings.
    @Published var showSettingsAlert: Bool = false

    init() {
        // Check initial authorization status to set isSynced appropriately
        // This is a simplified check; a more robust check might involve querying
        // HealthKit for previously synced data if possible or using UserDefaults.
        if HKHealthStore.isHealthDataAvailable() {
            self.isSynced = healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized
        }
    }

    // MARK: - Authorization

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            showError = true
            completion(false)
            return
        }

        isAuthorizing = true
        healthStore.requestAuthorization(toShare: [mindfulType], read: []) { success, error in
            DispatchQueue.main.async {
                self.isAuthorizing = false
                if success {
                    completion(true)
                } else {
                    self.showError = true
                    print("HealthKit Authorization Error: \(String(describing: error?.localizedDescription))")
                    completion(false)
                }
            }
        }
    }

    // MARK: - Saving Data

    /// Saves a mindful session to HealthKit.
    /// - Parameters:
    ///   - duration: The duration of the mindful session in seconds.
    ///   - date: The end date of the session.
    ///   - isVisionOSMode: A boolean indicating if the session was on visionOS (for logging purposes).
    func saveMindfulMinutes(duration: TimeInterval, endDate: Date, isVisionOSMode: Bool) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit: Data is not available on this device.")
            // Optionally set showError = true if immediate feedback is desired
            return
        }

        guard duration > 0 else {
            print("HealthKit: Mindful session duration is zero or negative, not saving.")
            return
        }
        
        let currentStatus = healthStore.authorizationStatus(for: mindfulType)

        switch currentStatus {
        case .notDetermined:
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.performSave(duration: duration, endDate: endDate, isVisionOSMode: isVisionOSMode)
                }
            }
        case .sharingAuthorized:
            performSave(duration: duration, endDate: endDate, isVisionOSMode: isVisionOSMode)
        case .sharingDenied:
            print("HealthKit: Sharing denied. Cannot save mindful minutes.")
            // Optionally set showSettingsAlert = true if you want to prompt them to change settings.
            // For a single save operation like in ConclusionView, direct user to settings might be too intrusive.
            // This is better handled by a dedicated sync button.
            return
        @unknown default:
            fatalError("HealthKit: Unknown authorization status.")
        }
    }

    private func performSave(duration: TimeInterval, endDate: Date, isVisionOSMode: Bool) {
        let startDate = endDate.addingTimeInterval(-duration)
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit: Error saving mindful minutes: \(error.localizedDescription)")
                    // self.showError = true // Consider if an error here should show UI
                } else if success {
                    let platform = isVisionOSMode ? "visionOS" : "iOS"
                    print("HealthKit: Mindful minutes saved successfully for \(duration) seconds on \(platform).")
                }
            }
        }
    }

    // MARK: - Syncing Historical Data

    /// Initiates HealthKit authorization and sync process for historical sessions.
    func syncHistoricalSessions(_ sessions: [GameSession]) {
        guard HKHealthStore.isHealthDataAvailable() else {
            showError = true
            return
        }

        let currentStatus = healthStore.authorizationStatus(for: mindfulType)

        if currentStatus == .notDetermined {
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.writeHistoricalDataToHealthKit(sessions) { writeSuccess in
                        if writeSuccess {
                            withAnimation { self?.isSynced = true }
                        } else {
                            self?.showError = true
                        }
                    }
                }
                // isAuthorizing is handled by requestAuthorization
            }
        } else if currentStatus == .sharingAuthorized {
            isAuthorizing = true // Show progress indicator for the write operation
            writeHistoricalDataToHealthKit(sessions) { [weak self] writeSuccess in
                DispatchQueue.main.async {
                    if writeSuccess {
                        withAnimation { self?.isSynced = true }
                    } else {
                        self?.showError = true
                    }
                    self?.isAuthorizing = false // Hide progress indicator
                }
            }
        } else { // currentStatus is .sharingDenied
            showSettingsAlert = true // Prompt user to go to settings
        }
    }

    private func writeHistoricalDataToHealthKit(_ sessions: [GameSession], completion: @escaping (Bool) -> Void) {
        guard !sessions.isEmpty else {
            print("HealthKit Sync: No historical sessions to write.")
            completion(true) // Nothing to sync, consider it a success
            return
        }

        var samplesToSave: [HKCategorySample] = []

        for session in sessions {
            guard session.totalFocusTime > 0 else {
                print("HealthKit Sync: Skipping session with zero duration: \(session.date)")
                continue
            }

            let endDate = session.date
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
            completion(true)
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
                print("HealthKit Sync: Saving batch of historical mindful minutes failed for an unknown reason.")
                completion(false)
            }
        }
    }
}
