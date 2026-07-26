import Foundation

// MARK: - Friend Model

struct Friend: Identifiable {
    let id: String
    let displayName: String
    let status: String
    let createdAt: String
}

// MARK: - Activity Item

struct ActivityItem: Identifiable {
    let id = UUID()
    let userId: String
    let displayName: String?
    let type: String
    let message: String
    let timestamp: String

    var timeAgo: String {
        guard let date = ISO8601DateFormatter().date(from: timestamp) else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - ViewModel

@MainActor
final class FriendsViewModel: ObservableObject {

    @Published var friends: [Friend] = []
    @Published var pendingReceived: [Friend] = []
    @Published var pendingSent: [Friend] = []
    @Published var activityFeed: [ActivityItem] = []
    @Published var searchResults: [FriendEntry] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let apiService = APIService.shared

    // MARK: - Load Friends

    func loadFriends() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await apiService.getFriends()

            friends = parseFriends(from: data["accepted"] as? [[String: Any]] ?? [])
            pendingReceived = parseFriends(from: data["pendingReceived"] as? [[String: Any]] ?? [])
            pendingSent = parseFriends(from: data["pendingSent"] as? [[String: Any]] ?? [])
        } catch {
            errorMessage = "Failed to load friends"
            print("Load friends error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Load Activity

    func loadActivity() async {
        do {
            let items = try await apiService.getActivityFeed()
            activityFeed = items.compactMap { dict in
                guard let userId = dict["userId"] as? String,
                      let type = dict["type"] as? String,
                      let message = dict["message"] as? String,
                      let timestamp = dict["timestamp"] as? String else { return nil }
                return ActivityItem(
                    userId: userId,
                    displayName: dict["displayName"] as? String,
                    type: type,
                    message: message,
                    timestamp: timestamp
                )
            }
        } catch {
            print("Load activity error: \(error)")
        }
    }

    // MARK: - Search Users

    func searchUsers() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        do {
            let users = try await apiService.getAllUsers()
            let currentId = AuthService.shared.currentUser?.id ?? ""
            let friendIds = Set(friends.map { $0.id } + pendingSent.map { $0.id } + pendingReceived.map { $0.id })

            searchResults = users
                .filter { dict in
                    let uid = dict["userId"] as? String ?? ""
                    let name = dict["displayName"] as? String ?? ""
                    let email = dict["email"] as? String ?? ""
                    return uid != currentId
                        && !friendIds.contains(uid)
                        && (name.localizedCaseInsensitiveContains(searchQuery) || email.localizedCaseInsensitiveContains(searchQuery))
                }
                .compactMap { dict in
                    guard let id = dict["userId"] as? String else { return nil }
                    let name = dict["displayName"] as? String ?? dict["email"] as? String ?? "User"
                    return FriendEntry(id: id, name: name)
                }
        } catch {
            print("Search error: \(error)")
        }
    }

    // MARK: - Actions

    func sendRequest(to userId: String) async {
        do {
            try await apiService.sendFriendRequest(friendId: userId)
            successMessage = "Friend request sent!"
            searchResults.removeAll { $0.id == userId }
            await loadFriends()

            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to send friend request"
        }
    }

    func acceptRequest(from friendId: String) async {
        do {
            try await apiService.acceptFriendRequest(friendId: friendId)
            await loadFriends()
            await loadActivity()
        } catch {
            errorMessage = "Failed to accept request"
        }
    }

    func rejectRequest(from friendId: String) async {
        do {
            try await apiService.rejectFriendRequest(friendId: friendId)
            await loadFriends()
        } catch {
            errorMessage = "Failed to reject request"
        }
    }

    func removeFriend(_ friendId: String) async {
        do {
            try await apiService.removeFriend(friendId: friendId)
            await loadFriends()
        } catch {
            errorMessage = "Failed to remove friend"
        }
    }

    func refresh() async {
        await loadFriends()
        await loadActivity()
    }

    // MARK: - Helpers

    private func parseFriends(from array: [[String: Any]]) -> [Friend] {
        array.compactMap { dict in
            guard let id = dict["friendId"] as? String else { return nil }
            return Friend(
                id: id,
                displayName: dict["displayName"] as? String ?? "User",
                status: dict["status"] as? String ?? "",
                createdAt: dict["createdAt"] as? String ?? ""
            )
        }
    }
}
