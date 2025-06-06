//
//  Home.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//

import SwiftUI
import Charts
import SwiftData

/// A view that serves as the main landing page of DistractionDodge, featuring focus duration selection and stats.
///
/// The Home view consists of two main pages:
/// 1. A duration selection page with an interactive circular slider
/// 2. A statistics page showing the user's progress and performance (now accessible via a button)
///
/// The view uses SwiftData for persistent storage and provides a fluid,
/// engaging interface for starting focus training sessions.
struct Home: View {
    @Query private var sessions: [GameSession]
    @State private var currentPage = 0 // Remains for BackgroundView, effectively always 0 for TabView
    @State private var selectedDuration: Double = 60
    @State private var isDragging = false
    @State private var startButtonScale: CGFloat = 1.0
    @State private var hasInteractedWithSlider = false
    @State private var showAbout = false
    @State private var showStatsPage = false
    
    @StateObject private var healthKitManager = HealthKitManager()

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
                #if os(iOS)
                BackgroundView(currentPage: currentPage, colors: gradientColors)
                #endif
                TabView(selection: $currentPage) {
                    FirstPageView(
                        selectedDuration: $selectedDuration,
                        isDragging: $isDragging,
                        startButtonScale: $startButtonScale,
                        hasInteractedWithSlider: $hasInteractedWithSlider,
                        message: randomMotivationalMessage,
                        formatDuration: formatDuration,
                        angleForDuration: angleForDuration,
                        updateDuration: updateDurationFromLocation,
                        healthKitManager: healthKitManager
                    )
                    .tag(0)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 16) {
                Button(action: {
                    showStatsPage = true
                }) {
                    Image(systemName: "chart.dots.scatter")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }.padding(.horizontal)
               

                Button(action: {
                    showAbout = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
               
            }
            .padding(20)
            #if os(visionOS)
            .padding()
            #endif
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $showStatsPage) {
            StatsView(sessions: sessions, healthKitManager: healthKitManager)
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        #endif
    }
}

// MARK: - Subviews
private struct FirstPageView: View {
    @Binding var selectedDuration: Double
    @Binding var isDragging: Bool
    @Binding var startButtonScale: CGFloat
    @Binding var hasInteractedWithSlider: Bool
    let message: String
    let formatDuration: (Double) -> String
    let angleForDuration: (Double) -> Double
    let updateDuration: (CGPoint, CGSize) -> Void
    @ObservedObject var healthKitManager: HealthKitManager
    
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
                hasInteracted: $hasInteractedWithSlider,
                healthKitManager: healthKitManager
            )
            
            Spacer()
        }
    }
}

/// Displays an animated motivational message with gradient styling.
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

/// A custom duration selection interface with a circular slider and time display.
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

/// An interactive circular slider for selecting focus session duration.
///
/// Features:
/// - Smooth drag gesture handling
/// - Visual feedback during interaction
/// - Animated progress indicator
/// - Glowing thumb control
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
                .hoverEffect()
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
                .hoverEffect()
                
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

/// A decorative circle providing the base layer for the circular slider.
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

/// A circular progress indicator showing the selected duration.
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

/// An interactive thumb control for the circular slider with glow effects.
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
            #if os(visionOS)
            .hoverEffect()
            #endif
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
            .animation(.easeInOut(duration: 0.1), value: selectedDuration)
    }
}

/// A transparent touch area for handling drag gestures on the circular slider.
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

/// An animated start button that begins the focus training session.
private struct StartButton: View {
    let scale: CGFloat
    let duration: Double
    @Binding var showGame: Bool
    @Binding var hasInteracted: Bool
    @ObservedObject var healthKitManager: HealthKitManager
    
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            showGame = true
        }) {
            Text("Begin Training")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 280, height: 60)
                #if os(iOS) // Conditional background styling for iOS
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.2), radius: 15)
                #endif
        }
        #if os(visionOS)
        .buttonStyle(.plain)
        #endif
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
            #if os(visionOS)
            VisionOSGameHostView(duration: duration, healthKitManager: healthKitManager)
            #else
            ContentView(duration: duration, healthKitManager: healthKitManager)
            #endif
        }
    }
}
