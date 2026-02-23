import SwiftUI

struct MatchesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MatchViewModel()
    @State private var selectedMatch: Match?
    @State private var pendingEventMessage: String?
    @State private var animateEmpty = false
    @State private var friends: [FriendProfile] = FriendStore.shared.allFriends()

    private var friendIDs: Set<String> {
        Set(friends.map(\.id))
    }

    var body: some View {
        NavigationView {
            ZStack {
                UCDavisBackground()

                Group {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(UCDavisPalette.gold)
                            Text("Loading matches...")
                                .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                        }
                    } else if viewModel.matches.isEmpty {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [UCDavisPalette.gold.opacity(0.18), UCDavisPalette.deepBlue.opacity(0.18)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(animateEmpty ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateEmpty)

                                Image(systemName: "message.badge.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            Text("No matches yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(UCDavisPalette.cream.opacity(0.92))

                            Text("Poke people in Discover to get matched!")
                                .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .onAppear { animateEmpty = true }
                    } else {
                        List(viewModel.matches) { match in
                            Button(action: {
                                if match.status == "event_joiner" {
                                    pendingEventMessage = "This player joined your event and is now visible in Matches. Chat unlocks once you become a full match."
                                } else {
                                    selectedMatch = match
                                }
                            }) {
                                MatchRow(
                                    match: match,
                                    currentUserId: authViewModel.user?.id ?? "",
                                    isFriend: friendIDs.contains(match.partnerId)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if friendIDs.contains(match.partnerId) {
                                    Button("Unfriend", role: .destructive) {
                                        FriendStore.shared.removeFriend(userId: match.partnerId)
                                        refreshFriends()
                                    }
                                    .accessibilityLabel("Unfriend \(match.partnerName)")
                                } else {
                                    Button("Add Friend") {
                                        FriendStore.shared.addFriend(userId: match.partnerId, displayName: match.partnerName)
                                        refreshFriends()
                                    }
                                    .tint(.green)
                                    .accessibilityLabel("Add \(match.partnerName) as friend")
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .foregroundColor(UCDavisPalette.gold)
            }
            .navigationTitle("Matches")
            .tint(UCDavisPalette.gold)
            .task {
                await viewModel.fetchMatches(
                    token: authViewModel.getToken(),
                    currentUser: authViewModel.user
                )
            }
            .onAppear {
                viewModel.startPolling(
                    token: authViewModel.getToken(),
                    currentUserProvider: { authViewModel.user }
                )
                refreshFriends()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .sheet(item: $selectedMatch) { match in
                ChatView(matchId: match.id, partnerName: match.partnerName)
                    .environmentObject(authViewModel)
            }
            .alert(
                "Pending Match",
                isPresented: Binding(
                    get: { pendingEventMessage != nil },
                    set: { if !$0 { pendingEventMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pendingEventMessage ?? "")
            }
        }
    }

    private func refreshFriends() {
        friends = FriendStore.shared.allFriends()
    }
}

struct MatchRow: View {
    let match: Match
    let currentUserId: String
    let isFriend: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(base64Picture: match.partnerProfilePicture, displayName: match.partnerName)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(match.partnerName)
                        .font(.headline)
                        .foregroundColor(UCDavisPalette.gold)

                    if match.status == "event_joiner" {
                        Text("Joined Event")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(UCDavisPalette.gold.opacity(0.90))
                            .foregroundColor(UCDavisPalette.navy)
                            .clipShape(Capsule())
                    }

                    if isFriend {
                        Image(systemName: "person.fill.checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if let sports = match.partnerSports, !sports.isEmpty {
                        Text(sportEmoji(sports.first?.sport ?? ""))
                            .font(.caption)
                    }
                }

                if let lastMessage = match.lastMessage {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                        .lineLimit(1)
                } else {
                    Text("Start chatting!")
                        .font(.subheadline)
                        .foregroundStyle(
                            .linearGradient(colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue], startPoint: .leading, endPoint: .trailing)
                        )
                        .italic()
                }
            }

            Spacer()

            if let lastMessage = match.lastMessage {
                Text(formatMessageTime(lastMessage.createdAt))
                    .font(.caption2)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.72))
            }
        }
        .padding(12)
        .ucDavisCardSurface()
    }

}
