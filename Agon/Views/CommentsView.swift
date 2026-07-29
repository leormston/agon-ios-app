import SwiftUI

struct CommentsView: View {
    let postId: String
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [FeedComment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comments list
                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if comments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.right")
                                    .font(.title2)
                                    .foregroundStyle(Color.agonTextSecondary)
                                Text("No comments yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.agonTextSecondary)
                                Text("Be the first to comment!")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(comments) { comment in
                                commentRow(comment)
                            }
                        }
                    }
                    .padding()
                }

                Divider()
                    .foregroundStyle(Color.agonBorder)

                // Input field
                HStack(spacing: 10) {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        Task { await sendComment() }
                    } label: {
                        if isSending {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(newComment.trimmingCharacters(in: .whitespaces).isEmpty ? Color.agonBorder : Color.agonAccent)
                        }
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.agonBackground)
            }
            .background(Color.agonBackground)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.agonAccent)
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    // MARK: - Comment Row

    private func commentRow(_ comment: FeedComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.agonAccent.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(String(comment.displayName.prefix(1)).uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(Color.agonAccent)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text(comment.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.agonTextPrimary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoading = true
        comments = await viewModel.getComments(postId: postId)
        isLoading = false
    }

    private func sendComment() async {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        isSending = true
        newComment = ""
        await viewModel.addComment(postId: postId, text: text)
        await loadComments()
        isSending = false
    }
}

#Preview {
    CommentsView(postId: "test", viewModel: FeedViewModel())
}
