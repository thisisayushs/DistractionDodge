//
//  TutorialStep.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 11/02/25.
//

import Foundation

struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: [String]
    let scoringType: ScoringType
}
