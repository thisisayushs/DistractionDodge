//
//  AboutView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/4/25.
//

import SwiftUI

/// A view that provides educational resources and information about the DistractionDodge app.
///
/// `AboutView` serves as an educational hub, offering users curated content to understand
/// the science behind attention, focus training, and the impact of digital distractions.
/// It also provides options to revisit introductory parts of the app.
///
/// ## Features
/// - Displays a list of educational resources, including research papers, documentaries, and books.
/// - Groups resources by type (e.g., ``ResourceType/research``, ``ResourceType/documentary``, ``ResourceType/book``) for organized browsing.
/// - Allows users to open external links to these resources.
/// - Offers options to replay the app's tutorial (``TutorialView`` or ``visionOSTutorialView``) and introduction (``OnboardingView``).
/// - Adapts its layout and styling for both iOS and visionOS platforms.
///
/// ## Usage
/// This view is typically presented modally or within a navigation context where users can
/// explore supplementary information about the app and the concepts it's built upon.
///
/// ```swift
/// // Example of presenting AboutView
/// .sheet(isPresented: $showAboutView) {
///     AboutView()
/// }
/// ```
struct AboutView: View {
    /// Controls the presentation of the tutorial view as a full-screen cover.
    /// When `true`, the tutorial is presented.
    @State private var replayTutorial = false
    
    /// Controls the presentation of the onboarding view as a full-screen cover.
    /// When `true`, the onboarding introduction is presented.
    @State private var replayIntroduction = false
    
    /// An environment property used to dismiss the current view.
    @Environment(\.dismiss) var dismiss
    
    /// A collection of ``Resource`` objects, each representing an educational item
    /// such as an article, documentary, or book related to attention and focus.
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
    
    /// A computed property that groups the ``resources`` array by their ``ResourceType``.
    ///
    /// This dictionary is used to display resources in sections within the `List`.
    /// - Returns: A dictionary where keys are ``ResourceType`` cases and values are arrays of ``Resource`` objects.
    private var groupedResources: [ResourceType: [Resource]] {
        Dictionary(grouping: resources) { $0.type }
    }
    
    /// The body of the `AboutView`, defining its content and layout.
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.black.opacity(0.7).ignoresSafeArea()
            #endif
            
            VStack(spacing: 20) {
                #if os(visionOS)
                // Dismiss button specific to visionOS for better platform integration.
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
                .padding()
                #endif
                
                HeaderView()
                
                // List displaying resources grouped by type and additional options.
                List {
                    ForEach(ResourceType.allCases, id: \.self) { type in
                        if let resources = groupedResources[type] {
                            Section {
                                ForEach(resources) { resource in
                                    ResourceRowView(resource: resource) {
                                        // Opens the URL associated with the resource in an external browser.
                                        UIApplication.shared.open(resource.url)
                                    }
                                }
                            } header: {
                                #if os(iOS)
                                Text(type.headerTitle).padding(.vertical).foregroundStyle(.white)
                                #else
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
                                #if os(visionOS)
                                    .padding()
                                #endif
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                    #if os(visionOS)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    #else
                                    .foregroundStyle(.gray)
                                    #endif
                            }
                            .padding(.vertical, 8)
                            #if os(iOS)
                            .foregroundStyle(.white)
                            #endif
                        }
                        #if os(iOS)
                        .listRowBackground(Color.black)
                        #else
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        #endif
                        
                        Button {
                            replayIntroduction = true
                        } label: {
                            HStack {
                                Text("Re-watch Introduction")
                                    .font(.headline)
                                    #if os(visionOS)
                                        .padding()
                                    #endif
                                Spacer()
                                Image(systemName: "play.circle")
                                    #if os(visionOS)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    #else
                                    .foregroundStyle(.gray)
                                    #endif
                            }
                            .padding(.vertical, 8)
                            #if os(iOS)
                            .foregroundStyle(.white)
                            #endif
                        }
                        #if os(iOS)
                        .listRowBackground(Color.black)
                        #else
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        #endif
                    } header: {
                        #if os(iOS)
                        Text("More Options").padding(.vertical).foregroundStyle(.white)
                        #else
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
            // Specific visionOS styling for the view container.
            .frame(width: 600, height: 700)
            .glassBackgroundEffect(in: .rect(cornerRadius: 20))
            .padding(30)
            #endif
        }
        // Presents the TutorialView when replayTutorial is true.
        .fullScreenCover(isPresented: $replayTutorial) {
            #if os(iOS)
            TutorialView()
            #elseif os(visionOS)
            visionOSTutorialView()
            #endif
        }
        // Presents the OnboardingView when replayIntroduction is true.
        .fullScreenCover(isPresented: $replayIntroduction) {
            OnboardingView()
        }
    }
}
