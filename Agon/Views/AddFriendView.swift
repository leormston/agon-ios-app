import SwiftUI

struct AddFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.agonTextSecondary)
                    TextField("Search by name or email...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: viewModel.searchQuery) {
                            Task { await viewModel.searchUsers() }
                        }
                }
                .padding(12)
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Success message
                if let message = viewModel.successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(Color.agonAccent)
                    }
                    .padding(.horizontal)
                }

                // Results
                if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.slash")
                            .font(.title)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No users found")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if viewModel.searchQuery.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Search for friends by name or email")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.searchResults) { user in
                                HStack {
                                    Circle()
                                        .fill(Color.agonBorder)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Text(String(user.name.prefix(1)))
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.agonTextPrimary)
                                        }

                                    Text(user.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.agonTextPrimary)

                                    Spacer()

                                    Button {
                                        Task { await viewModel.sendRequest(to: user.id) }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "person.badge.plus")
                                            Text("Add")
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.agonAccent)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)

                                if user.id != viewModel.searchResults.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
            .background(Color.agonBackground)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.agonAccent)
                }
            }
        }
    }
}

#Preview {
    AddFriendView(viewModel: FriendsViewModel())
}
