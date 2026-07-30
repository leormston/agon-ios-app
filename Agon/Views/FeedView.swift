import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedPost: FeedPost?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if viewModel.posts.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No posts yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Posts from you and your friends will appear here")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    ForEach(viewModel.posts) { post in
                        FeedPostCard(post: post, onLike: {
                            Task { await viewModel.likePost(post) }
                        }, onComment: {
                            selectedPost = post
                        })
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadFeed()
        }
        .sheet(item: $selectedPost) { post in
            CommentsView(postId: post.id, viewModel: viewModel)
        }
    }
}

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post: FeedPost
    let onLike: () -> Void
    let onComment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                if let avatarUrl = post.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        userInitialCircle
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    userInitialCircle
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text(post.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
            }

            // Content
            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLiked ? Color.agonAccent : Color.agonTextSecondary)
                        Text("\(post.likeCount)")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("\(post.commentCount)")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var userInitialCircle: some View {
        Circle()
            .fill(Color.agonAccent.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay {
                Text(String(post.displayName.prefix(1)).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(Color.agonAccent)
            }
    }
}

#Preview {
    FeedView()
}
