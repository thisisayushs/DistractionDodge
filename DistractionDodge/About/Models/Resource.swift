import Foundation

enum ResourceType: String, CaseIterable {
    case research
    case documentary
    case book
    
    var headerTitle: String {
        switch self {
        case .research: return "Research Papers"
        case .documentary: return "Documentaries"
        case .book: return "Books"
        }
    }
    static var allCases: [ResourceType] {
        [.research, .documentary, .book]
    }
}

struct Resource: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let url: URL
    let type: ResourceType
}
