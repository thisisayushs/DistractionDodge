//
//  ChartsView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI
import Charts

/// Container view for focus and streak charts.
/// - Manages time range selection
/// - Layouts charts vertically
/// - Provides consistent spacing
struct ChartsView: View {
    /// Currently selected time range
    @Binding var timeRange: StatsView.TimeRange
    /// Focus time data points for chart
    let focusTimeData: [(date: Date, minutes: Double)]
    /// Streak data points for chart
    let streakData: [(date: Date, streak: TimeInterval)]
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 15) {
                TimeRangeButton(
                    title: "Week",
                    isSelected: timeRange == .week,
                    action: { timeRange = .week }
                )
                
                TimeRangeButton(
                    title: "Month",
                    isSelected: timeRange == .month,
                    action: { timeRange = .month }
                )
            }
            .padding(.top, 60)
            
            VStack(spacing: 25) {
                FocusTimeChart(
                    focusTimeData: focusTimeData,
                    timeRange: timeRange
                )
                
                StreakChart(
                    streakData: streakData,
                    timeRange: timeRange
                )
            }
        }
        .frame(width: 500)
    }
}
