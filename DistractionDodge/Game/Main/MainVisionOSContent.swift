//
//  MainVisionOSContent.swift
//  DistractionDodge
//
//  Created by Ayush Singh on 5/6/25.
//

import SwiftUI
import RealityKit

struct MainVisionOSContent: View {
    @State private var scale: Bool = false
    var body: some View {
        RealityView { content in
                    let model = ModelEntity(
                        mesh: .generateSphere(radius: 0.1),
                        materials: [SimpleMaterial(color: .white, isMetallic: true)])


                    // Enable interactions on the entity.
                    model.components.set(InputTargetComponent())
                    model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
                    content.add(model)
                } update: { content in
                    if let model = content.entities.first {
                        model.transform.scale = scale ? [1.2, 1.2, 1.2] : [1.0, 1.0, 1.0]
                    }
                }
                .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
                    scale.toggle()
                })
    }
}

#Preview {
    MainVisionOSContent()
}
