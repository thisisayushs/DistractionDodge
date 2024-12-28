//
//  ContentView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import AVFoundation



struct ContentView: View {
    @StateObject private var viewModel = AttentionViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                EyeTrackingView { isGazing in
                    viewModel.updateGazeStatus(isGazing)
                }
                .edgesIgnoringSafeArea(.all)
                
                ForEach(Array(viewModel.distractions.enumerated()), id: \.element.id) { index, distraction in
                    NotificationView(distraction: distraction, index: index)
                        .position(
                            x: distraction.position.x,
                            y: distraction.position.y + 20
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                removal: .scale(scale: 0.9)
                                    .combined(with: .opacity)
                                    .animation(.easeOut(duration: 0.2))
                            )
                        )
                }
                
                MainCircle(
                    isGazingAtTarget: viewModel.isGazingAtObject,
                    position: viewModel.position
                )
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopGame()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
