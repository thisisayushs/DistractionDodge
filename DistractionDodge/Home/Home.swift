//
//  Home.swift
//  DistractionDodge
//
//  Created by Ayush Singh on 5/4/25.
//

import SwiftUI
import Charts
import SwiftData

struct Home: View {
    @State private var currentPage = 0
    @State private var selectedDuration: Double = 60
    @State private var isDragging = false
    @State private var startButtonScale: CGFloat = 1.0
    @State private var hasInteractedWithSlider = false
    
    private let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .blue.opacity(0.2)),
        (.black.opacity(0.8), .purple.opacity(0.2)),
        (.black.opacity(0.8), .indigo.opacity(0.2))
    ]
    
    private let motivationalMessages = [
        "Ready to sharpen your focus?",
        "Train your mind!",
        "Strengthen your attention span today",
        "Your focus is your superpower",
        "Small steps, big improvements",
        "Excellence comes with practice",
        "Build your focus muscle",
        "Every second of focus counts",
        "Transform your attention span",
        "Level up your concentration"
    ]
    
    private var randomMotivationalMessage: String {
        motivationalMessages.randomElement() ?? motivationalMessages[0]
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return remainingSeconds == 0 ? "\(minutes)m" : "\(minutes)m \(remainingSeconds)s"
    }
    
    private func angleForDuration(_ duration: Double) -> Double {
        (duration / 300) * 360 - 90
    }
    
    private func updateDurationFromLocation(_ location: CGPoint, in frame: CGSize) {
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let vector = CGPoint(x: location.x - center.x, y: location.y - center.y)
        let angle = atan2(vector.y, vector.x) + .pi/2
        var normalized = angle / (.pi * 2)
        if normalized < 0 { normalized += 1 }
        
        selectedDuration = normalized * 300
        selectedDuration = (round(selectedDuration / 30) * 30)
        if selectedDuration < 30 { selectedDuration = 30 }
        if selectedDuration > 300 { selectedDuration = 300 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundView(currentPage: currentPage, colors: gradientColors)
                
                TabView(selection: $currentPage) {
                    ForEach(0...1, id: \.self) { index in
                        if index == 0 {
                            FirstPageView(
                                selectedDuration: $selectedDuration,
                                isDragging: $isDragging,
                                startButtonScale: $startButtonScale,
                                hasInteractedWithSlider: $hasInteractedWithSlider,
                                message: randomMotivationalMessage,
                                formatDuration: formatDuration,
                                angleForDuration: angleForDuration,
                                updateDuration: updateDurationFromLocation
                            )
                            .tag(0)
                        } else {
                            StatsView()
                                .tag(1)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - Subviews
private struct BackgroundView: View {
    let currentPage: Int
    let colors: [(start: Color, end: Color)]
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colors[currentPage].start,
                colors[currentPage].end
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: currentPage)
    }
}

private struct FirstPageView: View {
    @Binding var selectedDuration: Double
    @Binding var isDragging: Bool
    @Binding var startButtonScale: CGFloat
    @Binding var hasInteractedWithSlider: Bool
    let message: String
    let formatDuration: (Double) -> String
    let angleForDuration: (Double) -> Double
    let updateDuration: (CGPoint, CGSize) -> Void
    
    @State private var showGame = false
    
    var body: some View {
        VStack {
            Spacer()
            
            MessageView(text: message)
            
            DurationSelectionView(
                selectedDuration: $selectedDuration,
                isDragging: $isDragging,
                startButtonScale: $startButtonScale,
                hasInteractedWithSlider: $hasInteractedWithSlider,
                formatDuration: formatDuration,
                angleForDuration: angleForDuration,
                updateDuration: updateDuration
            )
            
            Spacer()
            
            StartButton(
                scale: startButtonScale,
                duration: selectedDuration,
                showGame: $showGame,
                hasInteracted: $hasInteractedWithSlider
            )
            
            Spacer()
        }
    }
}

private struct MessageView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 42, weight: .bold, design: .rounded))
            
            .foregroundStyle(
                .linearGradient(
                    colors: [.white, .white.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
    }
}

private struct DurationSelectionView: View {
    @Binding var selectedDuration: Double
    @Binding var isDragging: Bool
    @Binding var startButtonScale: CGFloat
    @Binding var hasInteractedWithSlider: Bool
    let formatDuration: (Double) -> String
    let angleForDuration: (Double) -> Double
    let updateDuration: (CGPoint, CGSize) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text(formatDuration(selectedDuration))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .cyan.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            CircularSliderView(
                selectedDuration: $selectedDuration,
                isDragging: $isDragging,
                startButtonScale: $startButtonScale,
                hasInteractedWithSlider: $hasInteractedWithSlider,
                angleForDuration: angleForDuration,
                updateDuration: updateDuration
            )
            .frame(width: 280, height: 280)
            .padding(.bottom, 60)
        }
    }
}

private struct CircularSliderView: View {
    @Binding var selectedDuration: Double
    @Binding var isDragging: Bool
    @Binding var startButtonScale: CGFloat
    @Binding var hasInteractedWithSlider: Bool
    let angleForDuration: (Double) -> Double
    let updateDuration: (CGPoint, CGSize) -> Void
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MainCircle(
                    isGazingAtTarget: isDragging,
                    position: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                )
                .scaleEffect((selectedDuration/300) * 0.5 + 0.3)
                .animation(.easeInOut(duration: 0.3), value: selectedDuration)
                
                BackgroundCircle()
                
                ProgressCircle(selectedDuration: selectedDuration)
                
                GlowingSliderThumb(
                    isDragging: isDragging,
                    selectedDuration: selectedDuration,
                    proxy: proxy,
                    angleForDuration: angleForDuration
                )
                
                DragGestureArea(
                    proxy: proxy,
                    isDragging: $isDragging,
                    startButtonScale: $startButtonScale,
                    hasInteractedWithSlider: $hasInteractedWithSlider,
                    updateDuration: updateDuration
                )
            }
            .animation(.easeInOut(duration: 0.3), value: isDragging)
        }
    }
}

private struct BackgroundCircle: View {
    var body: some View {
        Circle()
            .stroke(
                .linearGradient(
                    colors: [.white.opacity(0.1), .white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .blur(radius: 0.5)
    }
}

private struct ProgressCircle: View {
    let selectedDuration: Double
    
    var body: some View {
        Circle()
            .trim(from: 0, to: selectedDuration / 300)
            .stroke(
                .linearGradient(
                    colors: [
                        .white.opacity(0.8),
                        .cyan.opacity(0.4),
                        .white.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: .white.opacity(0.4), radius: 6)
            .animation(.easeInOut, value: selectedDuration)
    }
}

private struct GlowingSliderThumb: View {
    let isDragging: Bool
    let selectedDuration: Double
    let proxy: GeometryProxy
    let angleForDuration: (Double) -> Double
    
    var thumbPosition: CGPoint {
        CGPoint(
            x: proxy.size.width/2 + cos(angleForDuration(selectedDuration) * .pi/180) * proxy.size.width/2,
            y: proxy.size.height/2 + sin(angleForDuration(selectedDuration) * .pi/180) * proxy.size.height/2
        )
    }
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 20, height: 20)
            .shadow(color: .white.opacity(0.7), radius: isDragging ? 12 : 8)
            .position(thumbPosition)
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
            .animation(.easeInOut(duration: 0.1), value: selectedDuration)
    }
}

private struct DragGestureArea: View {
    let proxy: GeometryProxy
    @Binding var isDragging: Bool
    @Binding var startButtonScale: CGFloat
    @Binding var hasInteractedWithSlider: Bool
    let updateDuration: (CGPoint, CGSize) -> Void
    
    var body: some View {
        Circle()
            .fill(.clear)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        updateDuration(value.location, proxy.size)
                        
                        if !hasInteractedWithSlider {
                            hasInteractedWithSlider = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                             isDragging = false
                        }
                        if hasInteractedWithSlider {
                            withAnimation(
                                .easeInOut(duration: 1)
                                .repeatForever(autoreverses: true)
                            ) {
                                startButtonScale = 1.05
                            }
                        }
                    }
            )
    }
}

private struct StartButton: View {
    let scale: CGFloat
    let duration: Double
    @Binding var showGame: Bool
    @Binding var hasInteracted: Bool
    
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            showGame = true
        }) {
            Text("Begin Training")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 280, height: 60)
                .background(.ultraThinMaterial)
               
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.2), radius: 15)
        }
       
        .scaleEffect(hasInteracted ? buttonScale : 1.0)
        .onChange(of: hasInteracted) { _, newValue in
            if newValue {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    buttonScale = 1.1
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
        .fullScreenCover(isPresented: $showGame) {
            ContentView(duration: duration)
        }
    }
}

private struct StatsView: View {
    @Query private var sessions: [GameSession]
    @State private var timeRange: TimeRange = .week
    
    enum TimeRange {
        case week, month
    }
    
    private var filteredSessions: [GameSession] {
        let calendar = Calendar.current
        let filterDate = timeRange == .week ?
            calendar.date(byAdding: .day, value: -7, to: Date())! :
            calendar.date(byAdding: .month, value: -1, to: Date())!
        
        return sessions.filter { $0.date >= filterDate }
    }
    
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
    
    var body: some View {
        ZStack {
            if sessions.isEmpty {
                EmptyStateView()
            } else {
                HStack(alignment: .top, spacing: 30) {
                    // Left Column - Charts
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
                    .frame(width: 500)
                    
                    // Right Column - Stats Cards
                    VStack(alignment: .center, spacing: 20) {
                        Spacer()
                            .frame(height: 100)
                            
                        StatCard(
                            title: "Games Played",
                            value: "\(sessions.count)",
                            icon: "gamecontroller.fill"
                        )
                        
                        StatCard(
                            title: "Best Score",
                            value: "\(sessions.map { $0.score }.max() ?? 0)",
                            icon: "trophy.fill"
                        )
                        
                        StatCard(
                            title: "Best Streak",
                            value: formatTime(sessions.map { $0.bestStreak }.max() ?? 0),
                            icon: "bolt.fill"
                        )
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        
        .animation(.easeInOut, value: timeRange)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return seconds < 60 ? "\(Int(seconds))s" :
               "\(minutes)m \(remainingSeconds)s"
    }
}

private struct TimeRangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isSelected ? .white : .white.opacity(0.15))
                        .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 5)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
    }
}

private struct ChartContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            content
                .frame(height: 180)
                .padding(.horizontal, 5)
        }
        .padding(20)
        .frame(maxWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 15)
        )
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 70))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 10)
            
            Text("No Stats Yet")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Complete your first focus training session\nto see your progress here!")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview
struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
