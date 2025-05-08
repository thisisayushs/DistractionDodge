import SwiftUI
import Charts
import HealthKit
import HealthKitUI

/// Root view for statistics and progress tracking.
/// - Manages time range selection
/// - Handles HealthKit authorization state
/// - Provides empty state handling
struct StatsView: View {
    /// Array of completed game sessions
    let sessions: [GameSession]
    
    /// Time range options for data filtering
    enum TimeRange {
        case week, month
    }
    
    // State properties
    @State private var timeRange: TimeRange = .week
    @State private var isSynced = false
    @State private var isAuthorizing = false
    @State private var showError = false
    @State private var showSettings = false
    @State private var authTrigger = false
    @State private var isAuthenticated = false
    @Environment(\.healthStore) private var healthStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) var dismiss
    
    private let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .blue.opacity(0.2)),    // Index 0
        (.black.opacity(0.8), .purple.opacity(0.2)), // Index 1
        (.black.opacity(0.8), .indigo.opacity(0.2))  // Index 2
    ]
    
    private let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    
    /// Updates HealthKit authorization status
    private func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: mindfulType)
        withAnimation {
            isSynced = status == .sharingAuthorized
            isAuthenticated = status == .sharingAuthorized
        }
    }
    
    var body: some View {
        ZStack { // Outer ZStack for background and content
            // We can pick a specific gradient, e.g., index 1 (purple) for StatsView
            // or make it dynamic if needed. For now, using index 1.
            #if os(iOS) // BackgroundView might be iOS specific based on Home.swift
            BackgroundView(currentPage: 1, colors: gradientColors)
            #endif

            ZStack(alignment: .topTrailing) { 
                // Main content
                Group { 
                    if sessions.isEmpty {
                        EmptyStateView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity) 
                    } else {
                        StatsContentView(
                            sessions: sessions,
                            timeRange: $timeRange,
                            isSynced: $isSynced,
                            isAuthorizing: $isAuthorizing,
                            showError: $showError,
                            showSettings: $showSettings
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity) 
                    }
                }
                // The BackgroundView now handles the full background.
                .animation(.easeInOut, value: timeRange)
                
                Button {
                    dismiss()
                } label: {
                    Text("Dismiss")
                        .font(.system(size: 18, weight: .bold, design: .rounded)) 
                        .foregroundColor(.white) 
                        .padding(.horizontal, 20) 
                        .padding(.vertical, 10)
                        #if os(iOS)
                        .background(.ultraThinMaterial) 
                        .clipShape(Capsule()) 
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 1) 
                        )
                        #elseif os(visionOS)
                        .background(Color.gray.opacity(0.3)) 
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        #endif
                }
                .padding() 
                #if os(visionOS)
                .buttonStyle(.plain) 
                .padding(.top) 
                #endif
            }
        }
        .onAppear {
            checkAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkAuthorizationStatus()
            }
        }
    }
}
