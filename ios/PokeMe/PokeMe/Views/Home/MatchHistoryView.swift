import SwiftUI

struct MatchHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MatchHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text("Failed to load history")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.matches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No past matches yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.matches) { match in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(match.partnerName.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.partnerName)
                                    .font(.headline)
                                if let major = match.partnerMajor {
                                    Text(major)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(match.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(match.status == "active" ? "Completed" : "Disconnected")
                                    .font(.caption2)
                                    .foregroundColor(match.status == "active" ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Match History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.fetchHistory(token: authViewModel.getToken())
            }
        }
    }
}
