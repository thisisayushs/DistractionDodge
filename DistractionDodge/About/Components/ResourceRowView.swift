//
//  ResourceRowView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
import SwiftUI

/// A row view for displaying educational resources.
/// - Supports both documentary and text-based resources
/// - Provides consistent styling and tap interaction
/// - Shows author information based on resource type
struct ResourceRowView: View {
    /// Resource item to display
    let resource: Resource
    /// Action to perform when row is tapped
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.headline)
                        #if os(iOS)
                        .foregroundStyle(.white)
                        #else
                        #endif
                    
                    Text(resource.type == ResourceType.documentary ? "Director: \(resource.author)" : "Author: \(resource.author)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
                    .font(.system(size: 14))
            }
        }
        #if os(iOS)
        .listRowBackground(Color.black)
        #else
        .listRowBackground(Color.clear)
        #endif
    }
}
