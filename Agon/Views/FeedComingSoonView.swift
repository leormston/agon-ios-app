import SwiftUI

struct FeedComingSoonView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.agonBorder)
            Text("Feed")
                .font(.title2.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text("Feature coming soon")
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FeedComingSoonView()
}
