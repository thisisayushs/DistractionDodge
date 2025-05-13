
// VisionOSStreakChart.swift
// DistractionDodge
//
// Created by Alex (AI Assistant) on 5/6/25.
//
#if os(visionOS)
import SwiftUI
import Charts

/// A chart component that visualizes daily best catch streaks over time for visionOS.
/// - Displays streak count using point marks
/// - Supports weekly and monthly time ranges (similar to iOS streak chart)
/// - Uses gradient styling for data points
struct VisionOSStreakChart: View {
    /// Data points containing dates and streak counts
    let streakData: [(date: Date, streakCount: Int)]
    /// Selected time range (week/month) affecting x-axis display
    let timeRange: StatsView.TimeRange // Assuming StatsView.TimeRange is available for visionOS

    /// Computed property to find the maximum streak count for Y-axis scaling.
    private var maxStreak: Int {
        streakData.map { $0.streakCount }.max() ?? 10 // Default to 10 if no data
    }

    /// Generates Y-axis tick values.
    private var yAxisValues: [Int] {
        guard maxStreak > 0 else { return [0, 2, 4, 6, 8, 10] }
        let step = max(1, Int(ceil(Double(maxStreak) / 5.0))) // Aim for about 5 ticks
        return stride(from: 0, to: maxStreak + step, by: step).map { $0 }
    }

    var body: some View {
        ChartContainer(title: "Best Daily Catch Streaks") { // Assuming ChartContainer is available for visionOS
            Chart(streakData, id: \.date) { item in
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Catches", item.streakCount)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.cyan, .blue], // Different color scheme for visionOS chart
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 4)
                .symbolSize(item.streakCount > 0 ? 100 : 0) // Optional: make points more prominent if streak > 0
            }
            .chartYScale(domain: 0...(maxStreak > 0 ? maxStreak + (yAxisValues.last ?? 10) / 5 : 10)) // Dynamic Y-axis
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
                AxisMarks(position: .leading, values: yAxisValues) { value in
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(count)")
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

#endif
