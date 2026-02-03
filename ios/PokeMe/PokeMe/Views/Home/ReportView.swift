import SwiftUI

struct ReportView: View {
    let partnerName: String
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?

    private let reasons = [
        "Inappropriate behavior",
        "Spam",
        "Harassment",
        "Other"
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Why are you reporting \(partnerName)?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section {
                    ForEach(reasons, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Submit Report") {
                        if let reason = selectedReason {
                            onSubmit(reason)
                            dismiss()
                        }
                    }
                    .disabled(selectedReason == nil)
                }
            }
            .navigationTitle("Report User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
