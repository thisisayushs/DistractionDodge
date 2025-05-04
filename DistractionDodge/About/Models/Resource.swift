import Foundation

/// Represents different types of educational resources available in the app.
enum ResourceType: String, CaseIterable {
    /// Scientific research papers and academic studies
    case research
    /// Documentary films and video content
    case documentary
    /// Published books and literature
    case book
    
    /// Returns a formatted header title for each resource type
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

/// A model representing an educational resource about attention and focus.
///
/// Each resource includes:
/// - A unique identifier
/// - Title of the work
/// - Author or creator
/// - URL for accessing the resource
/// - Type classification (research, documentary, or book)
struct Resource: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let url: URL
    let type: ResourceType
}
