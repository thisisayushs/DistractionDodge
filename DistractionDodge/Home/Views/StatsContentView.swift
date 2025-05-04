import SwiftUI
import Charts

struct StatsContentView: View {
    let sessions: [GameSession]
    @Binding var timeRange: StatsView.TimeRange
    @Binding var isSynced: Bool
    @Binding var isAuthorizing: Bool
    @Binding var showError: Bool
    @Binding var showSettings: Bool
    @Environment(\.healthStore) private var healthStore
    
    private var focusTimeData: [(date: Date, minutes: Double)] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        .map { date, sessions in
            (date, sessions.reduce(0) { $0 + $1.totalFocusTime } / 60)
        }
        .sorted { $0.date < $1.date }
    }
    
    private var streakData: [(date: Date, streak: TimeInterval)] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        .map { date, sessions in
            (date, sessions.map { $0.bestStreak }.max() ?? 0)
        }
        .sorted { $0.date < $1.date }
    }
    
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
                isSynced: $isSynced,
                isAuthorizing: $isAuthorizing,
                showError: $showError,
                showSettings: $showSettings
            )
        }
        .padding(.horizontal, 30)
    }
}