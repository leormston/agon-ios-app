import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showAddFriend = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add Friends Button
                Button {
                    showAddFriend = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add Friend")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.agonAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Pending Requests
                if !viewModel.pendingReceived.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(Color.agonAccent)
                            Text("Friend Requests")
                                .font(.headline)
                                .foregroundStyle(Color.agonTextPrimary)
                            Spacer()
                            Text("\(viewModel.pendingReceived.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.agonAccent)
                                .clipShape(Capsule())
                        }

                        ForEach(viewModel.pendingReceived) { friend in
                            HStack {
                                Circle()
                                    .fill(Color.agonBorder)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text(String(friend.displayName.prefix(1)))
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.agonTextPrimary)
                                    }

                                Text(friend.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.agonTextPrimary)

                                Spacer()

                                Button {
                                    Task { await viewModel.acceptRequest(from: friend.id) }
                                } label: {
                                    Text("Accept")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.agonAccent)
                                        .clipShape(Capsule())
                                }

                                Button {
                                    Task { await viewModel.rejectRequest(from: friend.id) }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .foregroundStyle(Color.agonTextSecondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Friends List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Friends")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }

                    if viewModel.friends.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 8) {
                            Image(systemName: "person.3")
                                .font(.title)
                                .foregroundStyle(Color.agonTextSecondary)
                            Text("No friends yet")
                                .font(.subheadline)
                                .foregroundStyle(Color.agonTextSecondary)
                            Text("Add friends to compete in challenges together")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.friends) { friend in
                            HStack {
                                NavigationLink(destination: FriendProfileView(userId: friend.id, displayName: friend.displayName)) {
                                    HStack {
                                        Circle()
                                            .fill(Color.agonAccent.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                Text(String(friend.displayName.prefix(1)))
                                                    .font(.caption.bold())
                                                    .foregroundStyle(Color.agonAccent)
                                            }

                                        Text(friend.displayName)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.agonTextPrimary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Menu {
                                    Button(role: .destructive) {
                                        Task { await viewModel.removeFriend(friend.id) }
                                    } label: {
                                        Label("Remove Friend", systemImage: "person.badge.minus")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(Color.agonTextSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Activity Feed
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Activity")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }

                    if viewModel.activityFeed.isEmpty {
                        Text("Activity from friends will show here")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(viewModel.activityFeed) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color.agonBorder)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        activityIcon(for: item.type)
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.message)
                                        .font(.caption)
                                        .foregroundStyle(Color.agonTextPrimary)
                                    Text(item.timeAgo)
                                        .font(.caption2)
                                        .foregroundStyle(Color.agonTextSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadFriends()
            await viewModel.loadActivity()
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendView(viewModel: viewModel)
        }
    }

    private func activityIcon(for type: String) -> some View {
        Group {
            switch type {
            case "friend_request":
                Image(systemName: "person.badge.plus")
                    .font(.caption2)
                    .foregroundStyle(Color.agonAccent)
            case "friend_accepted":
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.agonAccent)
            default:
                Image(systemName: "bell.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.agonTextSecondary)
            }
        }
    }
}

#Preview {
    CommunityView()
}
