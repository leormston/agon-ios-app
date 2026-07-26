import SwiftUI

struct CreateChallengeView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMetric: ChallengeMetric = .steps
    @State private var selectedDuration: ChallengeDuration = .oneWeek
    @State private var friendSearch = ""
    @State private var invitedFriends: [FriendEntry] = []
    @State private var showOtherMetrics = false

    var filteredFriends: [FriendEntry] {
        let friends = viewModel.friends
        if friendSearch.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(friendSearch) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Metric Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popular Metrics")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        VStack(spacing: 0) {
                            ForEach(ChallengeMetric.popular) { metric in
                                MetricRow(metric: metric, isSelected: selectedMetric == metric) {
                                    selectedMetric = metric
                                    showOtherMetrics = false
                                }

                                if metric != ChallengeMetric.popular.last {
                                    Divider()
                                        .background(Color.agonBorder)
                                }
                            }
                        }
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Other Metrics
                        Button {
                            withAnimation {
                                showOtherMetrics.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Other Metrics")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.agonTextPrimary)
                                Spacer()
                                Image(systemName: showOtherMetrics ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if showOtherMetrics {
                            VStack(spacing: 0) {
                                ForEach(ChallengeMetric.other) { metric in
                                    MetricRow(metric: metric, isSelected: selectedMetric == metric) {
                                        selectedMetric = metric
                                    }

                                    if metric != ChallengeMetric.other.last {
                                        Divider()
                                            .background(Color.agonBorder)
                                    }
                                }
                            }
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Duration Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        VStack(spacing: 0) {
                            ForEach(ChallengeDuration.allCases) { duration in
                                Button {
                                    selectedDuration = duration
                                } label: {
                                    HStack {
                                        Text(duration.title)
                                            .foregroundStyle(Color.agonTextPrimary)
                                        Spacer()
                                        if selectedDuration == duration {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.agonAccent)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }

                                if duration != ChallengeDuration.allCases.last {
                                    Divider()
                                        .background(Color.agonBorder)
                                }
                            }
                        }
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Invite Friends
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Friends")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        // Search field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.agonTextSecondary)
                            TextField("Search friends...", text: $friendSearch)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(12)
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Friends list (filtered)
                        if !filteredFriends.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredFriends, id: \.id) { friend in
                                    let isInvited = invitedFriends.contains(where: { $0.id == friend.id })
                                    Button {
                                        if isInvited {
                                            invitedFriends.removeAll { $0.id == friend.id }
                                        } else {
                                            invitedFriends.append(friend)
                                        }
                                    } label: {
                                        HStack {
                                            Circle()
                                                .fill(Color.agonBorder)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Text(String(friend.name.prefix(1)))
                                                        .font(.caption.bold())
                                                        .foregroundStyle(Color.agonTextPrimary)
                                                }
                                            Text(friend.name)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.agonTextPrimary)
                                            Spacer()
                                            Image(systemName: isInvited ? "checkmark.circle.fill" : "plus.circle")
                                                .foregroundStyle(isInvited ? Color.agonAccent : Color.agonTextSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    }

                                    if friend.id != filteredFriends.last?.id {
                                        Divider()
                                            .background(Color.agonBorder)
                                    }
                                }
                            }
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if !friendSearch.isEmpty {
                            Text("No friends found")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                                .padding(.top, 4)
                        }

                        // Selected friends
                        if !invitedFriends.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected (\(invitedFriends.count))")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(invitedFriends, id: \.id) { friend in
                                        HStack(spacing: 4) {
                                            Text(friend.name)
                                                .font(.caption)
                                            Button {
                                                invitedFriends.removeAll { $0.id == friend.id }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundStyle(Color.agonTextPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.agonAccentTint)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Create Button
                    Button {
                        Task {
                            let success = await viewModel.createChallenge(
                                metric: selectedMetric,
                                duration: selectedDuration,
                                invitedUserIds: invitedFriends.map { $0.id }
                            )
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Challenge")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.agonAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isCreating)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.agonAccent)
                }
            }
        }
    }

}

// MARK: - Metric Row

struct MetricRow: View {
    let metric: ChallengeMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: metric.icon)
                    .frame(width: 24)
                    .foregroundStyle(Color.agonAccent)
                Text(metric.title)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.agonAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Friend Entry

struct FriendEntry: Identifiable {
    let id: String
    let name: String
}

// MARK: - Flow Layout (for selected friend chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

#Preview {
    CreateChallengeView(viewModel: ChallengesViewModel())
}
