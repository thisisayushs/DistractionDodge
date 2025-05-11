//
//  StreakChart.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//
import SwiftUI
import Charts

/// A chart component that visualizes daily focus streaks over time.
/// - Displays streak duration in minutes using point marks
/// - Supports weekly and monthly time ranges
/// - Uses gradient styling for data points
struct StreakChart: View {
    /// Data points containing dates and streak durations
    let streakData: [(date: Date, streak: TimeInterval)]
    /// Selected time range (week/month) affecting x-axis display
    let timeRange: StatsView.TimeRange
    
    var body: some View {
        ChartContainer(title: "Best Daily Streaks") {
            Chart(streakData, id: \.date) { item in
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Minutes", item.streak)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 4)
            }
            .chartYScale(domain: 30...300)
            .chartXAxis {
                AxisMarks(preset: .aligned) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            if timeRange == .week {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            } else {
                                Text("\(Calendar.current.component(.day, from: date))")
                            }
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [30, 120, 180, 240, 300]) { value in
                    AxisValueLabel {
                        let seconds = Double(value.index * 60 + 30)
                        Text(String(format: "%.1fm", seconds / 60))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
}
