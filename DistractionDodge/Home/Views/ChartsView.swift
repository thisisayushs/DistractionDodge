import SwiftUI
import Charts

struct ChartsView: View {
    @Binding var timeRange: StatsView.TimeRange
    let focusTimeData: [(date: Date, minutes: Double)]
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