import SwiftUI
import Charts
import HealthKit
import HealthKitUI

struct StatsView: View {
    let sessions: [GameSession]
    @State private var timeRange: TimeRange = .week
    @State private var isSynced = false
    @State private var isAuthorizing = false
    @State private var showError = false
    @State private var showSettings = false
    @State private var authTrigger = false
    @State private var isAuthenticated = false
    @Environment(\.healthStore) private var healthStore
    @Environment(\.scenePhase) private var scenePhase
    
    enum TimeRange {
        case week, month
    }
    
    private let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    
    var body: some View {
        ZStack {
            if sessions.isEmpty {
                EmptyStateView()
            } else {
                StatsContentView(
                    sessions: sessions,
                    timeRange: $timeRange,
                    isSynced: $isSynced,
                    isAuthorizing: $isAuthorizing,
                    showError: $showError,
                    showSettings: $showSettings
                )
            }
        }
        .animation(.easeInOut, value: timeRange)
        .onAppear {
            checkAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: mindfulType)
        withAnimation {
            isSynced = status == .sharingAuthorized
            isAuthenticated = status == .sharingAuthorized
        }
    }
}
