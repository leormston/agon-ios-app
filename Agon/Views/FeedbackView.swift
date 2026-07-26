import SwiftUI

enum FeedbackType: String, CaseIterable {
    case bug = "Bug Report"
    case feature = "Feature Request"
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .bug
    @State private var title = ""
    @State private var description = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        Picker("Type", selection: $feedbackType) {
                            ForEach(FeedbackType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        TextField(feedbackType == .bug ? "What went wrong?" : "What would you like?", text: $title)
                            .padding(12)
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        TextEditor(text: $description)
                            .frame(minHeight: 150)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.agonSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(feedbackType == .bug ? "Include steps to reproduce if possible" : "Describe how this feature would help you")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }

                    // Submit Button
                    Button {
                        Task { await submitFeedback() }
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: feedbackType == .bug ? "ladybug.fill" : "lightbulb.fill")
                                Text("Submit \(feedbackType.rawValue)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSubmit ? Color.agonAccent : Color.agonBorder)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canSubmit || isSending)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.agonAccent)
                }
            }
            .alert("Thanks!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your feedback has been submitted. We'll review it soon.")
            }
        }
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submitFeedback() async {
        isSending = true
        errorMessage = nil

        do {
            try await APIService.shared.submitFeedback(
                type: feedbackType.rawValue,
                title: title,
                description: description
            )
            showSuccess = true
        } catch {
            errorMessage = "Failed to submit. Please try again."
        }

        isSending = false
    }
}

#Preview {
    FeedbackView()
}
