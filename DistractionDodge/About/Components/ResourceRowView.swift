import SwiftUI

struct ResourceRowView: View {
    let resource: Resource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
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
        .listRowBackground(Color.black)
    }
}
