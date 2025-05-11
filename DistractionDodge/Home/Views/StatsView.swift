//
//  StatsView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI
import Charts

/// Root view for statistics and progress tracking.
/// - Manages time range selection
/// - Handles HealthKit authorization state
/// - Provides empty state handling
struct StatsView: View {
    /// Array of completed game sessions
    let sessions: [GameSession]
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Time range options for data filtering
    enum TimeRange {
        case week, month
    }
    
    // State properties
    @State private var timeRange: TimeRange = .week
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) var dismiss
    
    private let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .blue.opacity(0.2)),    // Index 0
        (.black.opacity(0.8), .purple.opacity(0.2)), // Index 1
        (.black.opacity(0.8), .indigo.opacity(0.2))  // Index 2
    ]
    
    /// Updates HealthKit authorization status
    private func checkAuthorizationStatus() {
        /*
        let status = healthStore.authorizationStatus(for: mindfulType)
        withAnimation {
            // isSynced = status == .sharingAuthorized // healthKitManager.isSynced
            // isAuthenticated = status == .sharingAuthorized // Potentially map to healthKitManager.isSynced
        }
        */
    }
    
    var body: some View {
        ZStack { 
            #if os(iOS)
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
                            healthKitManager: healthKitManager
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity) 
                    }
                }
                
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
        
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // checkAuthorizationStatus() // Rely on HealthKitManager's state
                // HealthKitManager could also observe scenePhase if needed.
            }
        }
    }
}

