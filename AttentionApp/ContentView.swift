//
//  ContentView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI

// Add Distraction model
struct Distraction: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var shape: DistractionShape
}

// Add shape types for distractions
enum DistractionShape {
    case circle, square, triangle
    
    func view(color: Color) -> some View {
        Group {
            switch self {
            case .circle:
                Circle().fill(color)
            case .square:
                Rectangle().fill(color)
            case .triangle:
                Triangle().fill(color)
            }
        }
        .frame(width: 60, height: 60)
    }
}

// Add Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

// Add simple MainCircle view
struct MainCircle: View {
    let isGazingAtTarget: Bool
    let position: CGPoint
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: isGazingAtTarget ?
                                     [.green, .mint] : [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 200)
            .scaleEffect(isGazingAtTarget ? 1.2 : 1.0)
            .shadow(color: isGazingAtTarget ? .green.opacity(0.5) : .blue.opacity(0.5),
                    radius: isGazingAtTarget ? 15 : 10)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .position(x: position.x, y: position.y)
            .animation(.easeInOut(duration: 2), value: position)
            .animation(.easeInOut(duration: 0.3), value: isGazingAtTarget)
    }
}

struct ContentView: View {
    // Add state variables for position and gaze tracking
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2,
                                        y: UIScreen.main.bounds.height / 2)
    @State private var timer: Timer? = nil
    @State private var isGazingAtObject = false
    @State private var distractions: [Distraction] = []
    @State private var distractionTimer: Timer? = nil
    
    // Colors for distractions
    private let distractionColors: [Color] = [.red, .orange, .yellow, .pink, .cyan]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background remains white
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Update EyeTrackingView to pass distraction frames
                EyeTrackingView(onGazeUpdate: { isGazing in
                    isGazingAtObject = isGazing
                })
                .edgesIgnoringSafeArea(.all)
                
                // Distractions
                ForEach(distractions) { distraction in
                    distraction.shape.view(color: distraction.color)
                        .position(distraction.position)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Main circle with simplified properties
                MainCircle(
                    isGazingAtTarget: isGazingAtObject,
                    position: position
                )
            }
        }
        .onAppear {
            // Start timer when view appears
            startRandomMovement()
            startDistractions()
        }
        .onDisappear {
            // Stop timer when view disappears
            timer?.invalidate()
            distractionTimer?.invalidate()
            timer = nil
            distractionTimer = nil
        }
    }
    
    // Add function to start random movement
    private func startRandomMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            // Calculate safe areas to keep circle fully visible
            let safeX = (100...Int(screenWidth - 100))
            let safeY = (100...Int(screenHeight - 100))
            
            // Generate random position within safe areas
            withAnimation(.easeInOut(duration: 2)) {
                position = CGPoint(
                    x: CGFloat(safeX.randomElement() ?? Int(screenWidth/2)),
                    y: CGFloat(safeY.randomElement() ?? Int(screenHeight/2))
                )
            }
        }
    }
    
    // Distraction management function
    private func startDistractions() {
        distractionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                distractions.removeAll()
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let numberOfDistractions = Int.random(in: 1...3)
            
            withAnimation {
                for _ in 0..<numberOfDistractions {
                    let newDistraction = Distraction(
                        position: CGPoint(
                            x: CGFloat.random(in: 50...(screenWidth-50)),
                            y: CGFloat.random(in: 50...(screenHeight-50))
                        ),
                        color: distractionColors.randomElement() ?? .red,
                        shape: [DistractionShape.circle, .square, .triangle]
                            .randomElement() ?? .circle
                    )
                    distractions.append(newDistraction)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    distractions.removeAll()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
