//
//  StatsContentView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI
import Charts
import SwiftData

/// Main content view for statistics display.
/// - Manages data filtering and transformation
/// - Handles layout of charts and sidebar
/// - Processes HealthKit integration
struct StatsContentView: View {
    /// Array of completed game sessions
    let sessions: [GameSession]
    /// Currently selected time range
    @Binding var timeRange: StatsView.TimeRange
    /// HealthKit manager instance
    @ObservedObject var healthKitManager: HealthKitManager

    /// Query for UserProgress
    @Query private var userProgressList: [UserProgress]

    /// Computed property to safely access the first UserProgress object
    private var userProgress: UserProgress? {
        userProgressList.first
    }
    
    /// Filtered focus time data based on selected range
    private var focusTimeData: [(date: Date, minutes: Double)] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        .map { date, sessionsInDay in
            (date, sessionsInDay.reduce(0) { $0 + $1.totalFocusTime } / 60)
        }
        .sorted { $0.date < $1.date }
    }
    
    /// Filtered streak data based on selected range
    private var streakData: [(date: Date, streak: TimeInterval)] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        .map { date, sessionsInDay in
            (date, sessionsInDay.map { $0.bestStreak }.max() ?? 0)
        }
        .sorted { $0.date < $1.date }
    }
    
    /// Sessions filtered by current time range
    private var filteredSessions: [GameSession] {
        let calendar = Calendar.current
        let filterDate = timeRange == .week ?
            calendar.date(byAdding: .day, value: -7, to: Date())! :
            calendar.date(byAdding: .month, value: -1, to: Date())!
        
        return sessions.filter { $0.date >= filterDate }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            ChartsView(
                timeRange: $timeRange,
                focusTimeData: focusTimeData,
                streakData: streakData
            )
            
            StatsSidebarView(
                sessions: sessions,
                longestIOSStreak: userProgress?.longestStreak ?? 0,
                longestVisionOSStreak: userProgress?.longestVisionOSStreak ?? 0.0,
                healthKitManager: healthKitManager
            )
        }
        .padding(.horizontal, 30)
    }
}
