import SwiftUI
import Charts

/// A chart component that visualizes daily focus time.
/// - Displays focus duration in minutes using point marks
/// - Supports weekly and monthly time ranges
/// - Uses gradient styling for data points
struct FocusTimeChart: View {
    /// Data points containing dates and focus durations in minutes
    let focusTimeData: [(date: Date, minutes: Double)]
    /// Selected time range (week/month) affecting x-axis display
    let timeRange: StatsView.TimeRange
    
    var body: some View {
        ChartContainer(title: "Daily Focus Time") {
            Chart(focusTimeData, id: \.date) { item in
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .cyan],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 4)
            }
            .chartYScale(domain: 0...30)
            .chartXAxis {
                AxisMarks(values: .stride(
                    by: timeRange == .week ? .day : .day,
                    count: timeRange == .week ? 1 : 7
                )) { value in
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
                AxisMarks(position: .leading, values: [0, 10, 20, 30]) { value in
                    AxisValueLabel {
                        Text("\(value.index * 10)m")
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
}
