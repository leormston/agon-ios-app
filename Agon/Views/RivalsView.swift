import SwiftUI

// MARK: - Rival Model

struct Rival: Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let averages: [String: Double]

    func average(for metric: String) -> Double {
        averages[metric] ?? 0
    }
}

// MARK: - Rivals View

struct RivalsView: View {
    @State private var rivals: [Rival] = []
    @State private var isLoading = true
    @State private var showAddRival = false
    @State private var errorMessage: String?
    @State private var removingId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add rival button
                Button {
                    showAddRival = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add Rival")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.agonAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isLoading {
                    ProgressView("Loading rivals...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if rivals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.fencing")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No rivals yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Add friends as rivals to track how you stack up!")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(rivals) { rival in
                        rivalCard(rival)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle("Rivals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRivals()
        }
        .refreshable {
            await loadRivals()
        }
        .sheet(isPresented: $showAddRival) {
            AddRivalSheet(onAdded: {
                Task { await loadRivals() }
            })
        }
    }

    // MARK: - Rival Card

    private func rivalCard(_ rival: Rival) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let avatarUrl = rival.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        rivalInitial(rival)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    rivalInitial(rival)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(rival.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text("7-day averages")
                        .font(.caption2)
                        .foregroundStyle(Color.agonTextSecondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        Task { await removeRival(rival) }
                    } label: {
                        Label("Remove Rival", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.agonTextSecondary)
                }
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                rivalStat(icon: "figure.walk", value: "\(Int(rival.average(for: "steps")))", label: "Steps")
                rivalStat(icon: "flame.fill", value: "\(Int(rival.average(for: "exerciseMinutes")))", label: "Exercise")
                rivalStat(icon: "moon.fill", value: String(format: "%.1f", rival.average(for: "totalSleep")), label: "Sleep")
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rivalInitial(_ rival: Rival) -> some View {
        Circle()
            .fill(Color.agonAccent.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(rival.displayName.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.agonAccent)
            }
    }

    private func rivalStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.agonAccent)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.agonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - API

    private func loadRivals() async {
        isLoading = true
        errorMessage = nil

        do {
            let raw = try await APIService.shared.getRivals()
            rivals = raw.compactMap { dict -> Rival? in
                guard let id = dict["rivalId"] as? String ?? dict["userId"] as? String else { return nil }
                let name = dict["displayName"] as? String ?? "User"
                let avatar = dict["avatarUrl"] as? String
                var averages: [String: Double] = [:]
                if let avgs = dict["averages"] as? [String: Any] {
                    for (key, val) in avgs {
                        averages[key] = (val as? Double) ?? Double(val as? Int ?? 0)
                    }
                }
                return Rival(id: id, displayName: name, avatarUrl: avatar, averages: averages)
            }
        } catch {
            errorMessage = "Failed to load rivals"
            print("Rivals error: \(error)")
        }

        isLoading = false
    }

    private func removeRival(_ rival: Rival) async {
        removingId = rival.id
        do {
            try await APIService.shared.removeRival(id: rival.id)
            rivals.removeAll { $0.id == rival.id }
        } catch {
            errorMessage = "Failed to remove rival"
        }
        removingId = nil
    }
}

// MARK: - Add Rival Sheet

struct AddRivalSheet: View {
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var friends: [FriendEntry] = []
    @State private var isLoading = true
    @State private var addingId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if friends.isEmpty {
                        VStack(spacing: 8) {
                            Text("No friends available")
                                .font(.subheadline)
                                .foregroundStyle(Color.agonTextSecondary)
                            Text("Add friends first to set them as rivals")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(friends, id: \.id) { friend in
                            HStack {
                                Circle()
                                    .fill(Color.agonAccent.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text(String(friend.name.prefix(1)).uppercased())
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.agonAccent)
                                    }

                                Text(friend.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.agonTextPrimary)

                                Spacer()

                                Button {
                                    Task { await addRival(friend) }
                                } label: {
                                    if addingId == friend.id {
                                        ProgressView()
                                    } else {
                                        Text("Add")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.agonAccent)
                                            .clipShape(Capsule())
                                    }
                                }
                                .disabled(addingId != nil)
                            }
                            .padding()
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Add Rival")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.agonAccent)
                }
            }
            .task {
                await loadFriends()
            }
        }
    }

    private func loadFriends() async {
        isLoading = true
        do {
            let data = try await APIService.shared.getFriends()
            let accepted = data["accepted"] as? [[String: Any]] ?? []
            friends = accepted.compactMap { dict in
                guard let id = dict["friendId"] as? String else { return nil }
                let name = dict["displayName"] as? String ?? "User"
                return FriendEntry(id: id, name: name)
            }
        } catch {
            print("Load friends error: \(error)")
        }
        isLoading = false
    }

    private func addRival(_ friend: FriendEntry) async {
        addingId = friend.id
        do {
            try await APIService.shared.addRival(id: friend.id)
            friends.removeAll { $0.id == friend.id }
            onAdded()
        } catch {
            print("Add rival error: \(error)")
        }
        addingId = nil
    }
}

#Preview {
    NavigationStack {
        RivalsView()
    }
}
