//
//  AboutView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/3/25.
//
import SwiftUI
import HealthKit

/// Manages HealthKit interactions, including authorization, saving mindful minutes, and syncing historical data.
///
/// This class provides a centralized way to interact with HealthKit for storing mindful sessions.
/// It handles requesting authorization, saving individual sessions, and batch-saving historical data.
/// It also publishes properties to reflect the current state of HealthKit operations, such as authorization status and errors.
@MainActor
class HealthKitManager: ObservableObject {
    /// The shared HealthKit store instance.
    private let healthStore = HKHealthStore()
    /// The HealthKit type for mindful sessions.
    private let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

    /// Indicates whether historical data has been successfully synced with HealthKit.
    ///
    /// This property is updated after a successful call to `syncHistoricalSessions`.
    /// It reflects the authorization status for writing mindful session data.
    @Published var isSynced: Bool = false
    /// Indicates if a HealthKit authorization request is currently in progress.
    ///
    /// This is `true` while the system dialog for HealthKit permissions is active or while historical data is being written.
    @Published var isAuthorizing: Bool = false
    /// Controls the presentation of a generic error alert related to HealthKit operations.
    ///
    /// Set to `true` when an unexpected error occurs during HealthKit interactions, such as authorization failure or saving data.
    @Published var showError: Bool = false
    /// Controls the presentation of an alert prompting the user to open Health settings.
    ///
    /// Set to `true` when an operation cannot be performed due to denied HealthKit permissions,
    /// suggesting the user might need to change these in the Settings app.
    @Published var showSettingsAlert: Bool = false

    /// Initializes a new `HealthKitManager`.
    ///
    /// Checks the initial HealthKit authorization status for mindful sessions and updates `isSynced` accordingly.
    init() {
        // Check initial authorization status to set isSynced appropriately
        // This is a simplified check; a more robust check might involve querying
        // HealthKit for previously synced data if possible or using UserDefaults.
        if HKHealthStore.isHealthDataAvailable() {
            self.isSynced = healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized
        }
    }

    /// Re-checks HealthKit authorization status and updates `isSynced` property.
    /// Call this when the app becomes active to reflect any permission changes made outside the app.
    func updateAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            // If HealthKit is not available, reflect this in isSynced (or a new state variable if needed)
            // For now, assuming !isHealthDataAvailable means not synced.
            if self.isSynced { // Only update if there's a change to avoid unnecessary UI redraws
                self.isSynced = false
            }
            return
        }

        let currentStatus = healthStore.authorizationStatus(for: mindfulType)
        let newSyncedStatus = (currentStatus == .sharingAuthorized)
        
        if self.isSynced != newSyncedStatus { // Only update if there's a change
            self.isSynced = newSyncedStatus
        }
    }

    // MARK: - Authorization

    /// Requests authorization from the user to share mindful session data with HealthKit.
    ///
    /// This method presents the standard HealthKit permission dialog to the user if permissions have not yet been determined.
    /// It updates the `isAuthorizing` state during the request.
    /// If HealthKit data is unavailable on the device, `showError` is set to `true`.
    ///
    /// - Parameter completion: A closure that is called with `true` if authorization was granted, and `false` otherwise.
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

    /// Saves a mindful session (e.g., a completed game) to HealthKit.
    ///
    /// This method checks the current HealthKit authorization status.
    /// If authorization is `.notDetermined`, it requests permission first.
    /// If authorization is `.sharingAuthorized`, it proceeds to save the session.
    /// If authorization is `.sharingDenied` or HealthKit is unavailable, the session is not saved.
    ///
    /// - Parameters:
    ///   - duration: The duration of the mindful session in seconds. Must be greater than 0.
    ///   - endDate: The date and time when the mindful session ended.
    ///   - isVisionOSMode: A boolean indicating if the session was conducted in visionOS mode. This is used for logging purposes.
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

    /// Performs the actual save operation for a mindful session to HealthKit.
    ///
    /// This private helper is called after ensuring HealthKit is available and authorization has been granted.
    ///
    /// - Parameters:
    ///   - duration: The duration of the mindful session in seconds.
    ///   - endDate: The date and time when the mindful session ended.
    ///   - isVisionOSMode: A boolean indicating if the session was on visionOS, used for logging.
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

    /// Initiates the process of syncing a list of historical game sessions to HealthKit as mindful minutes.
    ///
    /// This method checks HealthKit availability and authorization status:
    /// - If status is `.notDetermined`, it requests authorization and then writes data if granted.
    /// - If status is `.sharingAuthorized`, it proceeds to write the historical data.
    /// - If status is `.sharingDenied`, it sets `showSettingsAlert` to `true` to prompt the user.
    /// Updates `isAuthorizing` during the write operation and `isSynced` upon success.
    ///
    /// - Parameter sessions: An array of `GameSession` objects representing historical data to be synced.
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

    /// Writes an array of `GameSession` objects to HealthKit as mindful session samples.
    ///
    /// This private helper filters out sessions with zero duration and then attempts to save
    /// the valid sessions as a batch.
    ///
    /// - Parameters:
    ///   - sessions: An array of `GameSession` objects.
    ///   - completion: A closure called with `true` if all valid sessions were saved successfully or if there were no valid sessions to save, `false` otherwise.
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
