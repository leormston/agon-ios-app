import SwiftUI

struct CreateChallengeView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMetric: ChallengeMetric = .steps
    @State private var selectedDuration: ChallengeDuration = .oneWeek
    @State private var friendUserId = ""
    @State private var invitedUserIds: [String] = []
    @State private var showOtherMetrics = false

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

                        HStack {
                            TextField("Enter user ID", text: $friendUserId)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.agonSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            Button {
                                addFriend()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.agonAccent)
                            }
                            .disabled(friendUserId.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        if !invitedUserIds.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(invitedUserIds, id: \.self) { userId in
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(Color.agonTextSecondary)
                                        Text(userId)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.agonTextPrimary)
                                        Spacer()
                                        Button {
                                            invitedUserIds.removeAll { $0 == userId }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(Color.agonTextSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                    if userId != invitedUserIds.last {
                                        Divider()
                                            .background(Color.agonBorder)
                                    }
                                }
                            }
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Create Button
                    Button {
                        Task {
                            let success = await viewModel.createChallenge(
                                metric: selectedMetric,
                                duration: selectedDuration,
                                invitedUserIds: invitedUserIds
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

    private func addFriend() {
        let trimmed = friendUserId.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !invitedUserIds.contains(trimmed) else { return }
        invitedUserIds.append(trimmed)
        friendUserId = ""
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

#Preview {
    CreateChallengeView(viewModel: ChallengesViewModel())
}
