//
//  Page.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 10/02/25.
//

import Foundation

struct Page: Identifiable {
    let id = UUID()
    let title: String
    let content: [String]
    let sfSymbol: String
    let emoji: String
    let buttonText: String
}
