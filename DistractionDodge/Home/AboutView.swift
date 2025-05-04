//
//  AboutView.swift
//  DistractionDodge
//
//  Created by Ayush Singh on 5/4/25.
//

import SwiftUI


struct ResearchPaper {
    let author: String
    let url: URL
}

struct Documentary {
    let director: String
    let url: URL
}

struct Book {
    let author: String
    let url: URL
}

struct AboutView: View {
    @State private var showDismissButton = true
    
    let researchPapers: [String: ResearchPaper] = [
        "Myth and Mystery of Shrinking Attention Span":
            ResearchPaper(author: "Dr. K.R. Sundaramanian, Credait",
                         url: URL(string: "https://www.researchgate.net/publication/327367023_Myth_and_Mystery_of_Shrinking_Attention_Span")!),
        "Examining the Influence of Short Videos on Attention Span and its relationship with Academic Performance":
            ResearchPaper(author: "Mohd. Asif & Saniya Kazi, University of Mumbai",
                         url: URL(string: "https://www.researchgate.net/publication/380348721_Examining_the_Influence_of_Short_Videos_on_Attention_Span_and_its_Relationship_with_Academic_Performance")!),
        "Screen Time and the Brain":
            ResearchPaper(author: "Debra Bradley Ruder, Harvard Medical School",
                         url: URL(string: "https://hms.harvard.edu/news/screen-time-brain")!),
        "Handbook of Children and Screens":
            ResearchPaper(author: "Dimitry A. Chrsitakis, University of Washington",
                         url: URL(string: "https://link.springer.com/book/10.1007/978-3-031-69362-5")!),
        "Digital Distraction, Attention Regulation, and Inequality":
            ResearchPaper(author: "Kaisa Kärki, University of Helsinki",
                         url: URL(string: "https://link.springer.com/article/10.1007/s13347-024-00698-z")!)
    ]

    let documentaries: [String: Documentary] = [
        "The Social Dilemma":
            Documentary(director: "Jeff Orlowski",
                       url: URL(string: "https://www.netflix.com/title/81254224")!),
        "Screened Out":
            Documentary(director: "Jon Hyatt",
                       url: URL(string: "https://www.imdb.com/title/tt12258286/")!),
        "In the Age of AI":
            Documentary(director: "Neil Docherty & David Fanning",
                       url: URL(string: "https://www.pbs.org/wgbh/frontline/documentary/in-the-age-of-ai/")!)
    ]

    let books: [String: Book] = [
        "Attention Span":
            Book(author: "Gloria Mark",
                 url: URL(string: "https://books.apple.com/us/book/attention-span/id1618004493")!),
        "Deep Work":
            Book(author: "Cal Newport",
                 url: URL(string: "https://books.apple.com/us/book/deep-work/id991831052")!)
    ]
    
    private func handleURLOpen(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 20) {
                VStack {
                    Image("Icon")
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(width: 100, height: 100)
                        .shadow(color: .white.opacity(0.3), radius: 15, x: 0, y: 0)
                    
                    Text("Made with love in Naples, Italy 🇮🇹")
                        .italic()
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                }
                .padding(.top, 80)
                
                List {
                    Section(header: Text("Research Papers").padding(.vertical).foregroundStyle(.white)) {
                        ForEach(researchPapers.keys.sorted(), id: \.self) { title in
                            Button {
                                handleURLOpen(researchPapers[title]!.url)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(title)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text(researchPapers[title]!.author)
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
                            .listRowBackground(Color.black)
                        }
                    }
                    
                    Section(header: Text("Documentaries").padding(.vertical).foregroundStyle(.white)) {
                        ForEach(documentaries.keys.sorted(), id: \.self) { title in
                            Button {
                                handleURLOpen(documentaries[title]!.url)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(title)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("Director: \(documentaries[title]!.director)")
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
                            .listRowBackground(Color.black)
                        }
                    }
                    
                    Section(header: Text("Books").padding(.vertical).foregroundStyle(.white)) {
                        ForEach(books.keys.sorted(), id: \.self) { title in
                            Button {
                                handleURLOpen(books[title]!.url)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(title)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("Author: \(books[title]!.author)")
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
                            .listRowBackground(Color.black)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    AboutView()
        .preferredColorScheme(.dark)
}
