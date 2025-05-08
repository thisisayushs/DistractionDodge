//
//  AboutView.swift
//  DistractionDodge
//
//  Created by Ayush Singh on 5/4/25.
//

import SwiftUI

/// A view that provides educational resources and app information.
///
/// Features:
/// - Curated list of research papers, documentaries, and books
/// - Grouped resources by type for easy navigation
/// - Interactive links to external content
/// - Options to replay tutorial or introduction
/// - Custom styling with blur effects and gradients
///
/// The view serves as an educational hub, helping users understand
/// the science behind attention and focus training.
struct AboutView: View {
    /// Controls visibility of the tutorial replay
    @State private var replayTutorial = false
    
    /// Controls visibility of the introduction replay
    @State private var replayIntroduction = false
    
    @Environment(\.dismiss) var dismiss
    
    /// Collection of educational resources
    private let resources: [Resource] = [
        Resource(title: "Myth and Mystery of Shrinking Attention Span",
                author: "Dr. K.R. Sundaramanian, Credait",
                url: URL(string: "https://www.researchgate.net/publication/327367023_Myth_and_Mystery_of_Shrinking_Attention_Span")!,
                type: ResourceType.research),
        Resource(title: "Examining the Influence of Short Videos on Attention Span and its relationship with Academic Performance",
                author: "Mohd. Asif & Saniya Kazi, University of Mumbai",
                url: URL(string: "https://www.researchgate.net/publication/380348721_Examining_the_Influence_of_Short_Videos_on_Attention_Span_and_its_Relationship_with_Academic_Performance")!,
                type: ResourceType.research),
        Resource(title: "Screen Time and the Brain",
                author: "Debra Bradley Ruder, Harvard Medical School",
                url: URL(string: "https://hms.harvard.edu/news/screen-time-brain")!,
                type: ResourceType.research),
        Resource(title: "Handbook of Children and Screens",
                author: "Dimitry A. Chrsitakis, University of Washington",
                url: URL(string: "https://link.springer.com/book/10.1007/978-3-031-69362-5")!,
                type: ResourceType.research),
        Resource(title: "Digital Distraction, Attention Regulation, and Inequality",
                author: "Kaisa Kärki, University of Helsinki",
                url: URL(string: "https://link.springer.com/article/10.1007/s13347-024-00698-z")!,
                type: ResourceType.research),
        Resource(title: "The Social Dilemma",
                author: "Jeff Orlowski",
                url: URL(string: "https://www.netflix.com/title/81254224")!,
                type: ResourceType.documentary),
        Resource(title: "Screened Out",
                author: "Jon Hyatt",
                url: URL(string: "https://www.imdb.com/title/tt6809010/")!,
                type: ResourceType.documentary),
        Resource(title: "In the Age of AI",
                author: "Neil Docherty & David Fanning",
                url: URL(string: "https://www.pbs.org/wgbh/frontline/documentary/in-the-age-of-ai/")!,
                type: ResourceType.documentary),
        Resource(title: "Attention Span",
                author: "Gloria Mark",
                url: URL(string: "https://books.apple.com/us/book/attention-span/id1618004493")!,
                type: ResourceType.book),
        Resource(title: "Deep Work",
                author: "Cal Newport",
                url: URL(string: "https://books.apple.com/us/book/deep-work/id991831052")!,
                type: ResourceType.book)
    ]
    
    /// Resources grouped by their type for sectioned display
    private var groupedResources: [ResourceType: [Resource]] {
        Dictionary(grouping: resources) { $0.type }
    }
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.black.opacity(0.7).ignoresSafeArea()
            #endif
            
            VStack(spacing: 20) {
                #if os(visionOS)
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .background(.thinMaterial, in: Capsule())
                    .buttonStyle(.plain)
                }
                .padding() // Adjust spacing as needed
                #endif
                
                HeaderView() 
                
                List {
                    ForEach(ResourceType.allCases, id: \.self) { type in
                        if let resources = groupedResources[type] {
                            Section {
                                ForEach(resources) { resource in
                                    ResourceRowView(resource: resource) {
                                        UIApplication.shared.open(resource.url)
                                    }
                                }
                            } header: {
                                #if os(iOS)
                                Text(type.headerTitle).padding(.vertical).foregroundStyle(.white)
                                #else // visionOS
                                Text(type.headerTitle) 
                                #endif
                            }
                            #if os(visionOS)
                            .listRowSeparator(.hidden) 
                            #endif
                        }
                    }
                    
                    Section {
                        Button {
                            replayTutorial = true
                        } label: {
                            HStack {
                                Text("Replay Tutorial")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                    #if os(visionOS)
                                    .foregroundStyle(.secondary) 
                                    #else
                                    .foregroundStyle(.gray)
                                    #endif
                            }
                            .padding(.vertical, 8)
                            #if os(visionOS)
                            .foregroundStyle(.link) 
                            #else // iOS
                            .foregroundStyle(.white)
                            #endif
                        }
                        #if os(iOS)
                        .listRowBackground(Color.black)
                        #else // visionOS
                        .buttonStyle(.plain)
                        #endif
                        
                        Button {
                            replayIntroduction = true
                        } label: {
                            HStack {
                                Text("Re-watch Introduction")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "play.circle")
                                    #if os(visionOS)
                                    .foregroundStyle(.secondary) 
                                    #else
                                    .foregroundStyle(.gray)
                                    #endif
                            }
                            .padding(.vertical, 8)
                            #if os(visionOS)
                            .foregroundStyle(.link) 
                            #else // iOS
                            .foregroundStyle(.white)
                            #endif
                        }
                        #if os(iOS)
                        .listRowBackground(Color.black)
                        #else // visionOS
                        .buttonStyle(.plain)
                        #endif
                    } header: {
                        #if os(iOS)
                        Text("More Options").padding(.vertical).foregroundStyle(.white)
                        #else // visionOS
                        Text("More Options") 
                        #endif
                    }
                    #if os(visionOS)
                    .listRowSeparator(.hidden) 
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
            #if os(visionOS)
            .frame(width: 600, height: 700) 
            .glassBackgroundEffect(in: .rect(cornerRadius: 20)) 
            .padding(30) 
            #endif
        }
        .fullScreenCover(isPresented: $replayTutorial) {
            TutorialView()
        }
        .fullScreenCover(isPresented: $replayIntroduction) {
            OnboardingView()
        }
    }
}
