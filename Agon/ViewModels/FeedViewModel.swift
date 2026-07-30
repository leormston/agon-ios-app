import Foundation

// MARK: - Feed Post Model

struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let avatarUrl: String?
    let content: String
    let timestamp: String
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool

    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: timestamp)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: timestamp)
        }
        guard let parsedDate = date else { return "" }
        let interval = Date().timeIntervalSince(parsedDate)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Comment Model

struct FeedComment: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let text: String
    let timestamp: String

    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: timestamp)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: timestamp)
        }
        guard let parsedDate = date else { return "" }
        let interval = Date().timeIntervalSince(parsedDate)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Feed ViewModel

@MainActor
final class FeedViewModel: ObservableObject {

    @Published var posts: [FeedPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    // MARK: - Load Feed

    func loadFeed() async {
        isLoading = true
        errorMessage = nil

        do {
            let raw = try await apiService.getFeed()
            posts = raw.compactMap { dict -> FeedPost? in
                guard let id = dict["postId"] as? String ?? dict["id"] as? String,
                      let userId = dict["userId"] as? String,
                      let content = dict["content"] as? String else { return nil }

                return FeedPost(
                    id: id,
                    userId: userId,
                    displayName: dict["displayName"] as? String ?? "User",
                    avatarUrl: dict["avatarUrl"] as? String,
                    content: content,
                    timestamp: dict["timestamp"] as? String ?? dict["createdAt"] as? String ?? "",
                    likeCount: dict["likeCount"] as? Int ?? (dict["likes"] as? [Any])?.count ?? 0,
                    commentCount: dict["commentCount"] as? Int ?? (dict["comments"] as? [Any])?.count ?? 0,
                    isLiked: dict["isLiked"] as? Bool ?? false
                )
            }
        } catch is CancellationError {
            // Ignore
        } catch {
            if posts.isEmpty {
                errorMessage = "Failed to load feed"
            }
            print("Feed error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Like Post

    func likePost(_ post: FeedPost) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        // Optimistic update
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1

        do {
            try await apiService.likePost(id: post.id)
        } catch {
            // Revert on failure
            posts[index].isLiked.toggle()
            posts[index].likeCount += posts[index].isLiked ? 1 : -1
            print("Like error: \(error)")
        }
    }

    // MARK: - Comment

    func addComment(postId: String, text: String) async {
        do {
            try await apiService.commentOnPost(id: postId, text: text)
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].commentCount += 1
            }
        } catch {
            print("Comment error: \(error)")
        }
    }

    // MARK: - Get Comments

    func getComments(postId: String) async -> [FeedComment] {
        do {
            let raw = try await apiService.getComments(postId: postId)
            return raw.compactMap { dict -> FeedComment? in
                let id = dict["commentId"] as? String ?? dict["id"] as? String ?? UUID().uuidString
                let userId = dict["userId"] as? String ?? ""
                let name = dict["displayName"] as? String ?? "User"
                let text = dict["text"] as? String ?? ""
                let timestamp = dict["timestamp"] as? String ?? dict["createdAt"] as? String ?? ""

                return FeedComment(id: id, userId: userId, displayName: name, text: text, timestamp: timestamp)
            }
        } catch {
            print("Get comments error: \(error)")
            return []
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await loadFeed()
    }
}
