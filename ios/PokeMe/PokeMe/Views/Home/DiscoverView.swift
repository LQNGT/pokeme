import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var noteDrafts: [String: String] = [:]
    @State private var commitInFlight: Set<String> = []
    @State private var noShowReportInFlight: Set<String> = []
    @State private var selectedDirectChat: DirectChatDestination?
    private let refreshTicker = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ZStack {
                UCDavisBackground()

                VStack(spacing: 12) {
                    Picker("Feed", selection: $viewModel.selectedSection) {
                        ForEach(DiscoverViewModel.FeedSection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(UCDavisPalette.surface.opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(UCDavisPalette.border, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if let featured = viewModel.mostActiveThread {
                        MostActiveThreadBanner(
                            thread: featured,
                            emoji: sportEmoji(featured.sport)
                        )
                        .padding(.horizontal)
                    }

                    content
                }
                .foregroundColor(UCDavisPalette.gold)
            }
            .navigationTitle("Discover")
            .tint(UCDavisPalette.gold)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await refreshFeed() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh feed")
                }
            }
            .task {
                await refreshFeed()
            }
            .onChange(of: authViewModel.user?.id) { _ in
                Task {
                    await refreshFeed()
                }
            }
            .onReceive(refreshTicker) { _ in
                Task {
                    await refreshFeed(showLoading: false)
                }
            }
            .sheet(item: $selectedDirectChat) { destination in
                ChatView(matchId: destination.matchId, partnerName: destination.partnerName)
                    .environmentObject(authViewModel)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(UCDavisPalette.gold)
                Text(error)
                    .foregroundColor(UCDavisPalette.cream.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Retry") {
                    Task { await refreshFeed() }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(UCDavisPalette.deepBlue)
                .foregroundColor(.white)
                .cornerRadius(16)
                Spacer()
            }
        } else if viewModel.isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.25)
                    .tint(UCDavisPalette.gold)
                Text("Loading active conversations...")
                    .font(.subheadline)
                    .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                Spacer()
            }
        } else if viewModel.visibleThreads.isEmpty {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "text.bubble")
                    .font(.system(size: 44))
                    .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                Text("No active conversations right now")
                    .font(.headline)
                    .foregroundColor(UCDavisPalette.cream.opacity(0.92))
                Text("Check back soon or create a meetup to start one.")
                    .font(.subheadline)
                    .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.visibleThreads) { thread in
                        PlaceConversationCard(
                            thread: thread,
                            emoji: sportEmoji(thread.sport),
                            hostSummary: hostReputation(for: thread),
                            currentUserId: authViewModel.user?.id,
                            draftText: noteBinding(for: thread.id),
                            isCommitting: commitInFlight.contains(thread.id),
                            isReportingNoShow: noShowReportInFlight.contains(thread.id),
                            onCommit: { commitToAttend(thread: thread) },
                            onReportNoShow: { reportNoShow(for: thread) },
                            onMessageContact: { openDirectMessage(contact: $0) },
                            onSend: { postNote(for: thread) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .refreshable {
                await refreshFeed()
            }
        }
    }

    private func refreshFeed(showLoading: Bool = true) async {
        await viewModel.fetchActivityFeed(
            token: authViewModel.getToken(),
            currentUser: authViewModel.user,
            showLoading: showLoading
        )
    }

    private func noteBinding(for threadId: String) -> Binding<String> {
        Binding(
            get: { noteDrafts[threadId, default: ""] },
            set: { noteDrafts[threadId] = $0 }
        )
    }

    private func postNote(for thread: DiscoverViewModel.PlaceThread) {
        let text = noteDrafts[thread.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let currentUser = authViewModel.user else { return }

        let didPost = viewModel.addNote(
            threadId: thread.id,
            text: text,
            authorId: currentUser.id,
            author: currentUser.displayName
        )
        if didPost {
            noteDrafts[thread.id] = ""
        }
    }

    private func commitToAttend(thread: DiscoverViewModel.PlaceThread) {
        guard !commitInFlight.contains(thread.id) else { return }
        commitInFlight.insert(thread.id)
        Task {
            _ = await viewModel.commitToAttend(
                token: authViewModel.getToken(),
                thread: thread
            )
            commitInFlight.remove(thread.id)
        }
    }

    private func reportNoShow(for thread: DiscoverViewModel.PlaceThread) {
        guard !noShowReportInFlight.contains(thread.id) else { return }
        noShowReportInFlight.insert(thread.id)
        _ = viewModel.reportNoShow(thread: thread, reporterId: authViewModel.user?.id)
        noShowReportInFlight.remove(thread.id)
    }

    private func openDirectMessage(contact: DiscoverViewModel.DirectContact) {
        selectedDirectChat = DirectChatDestination(
            matchId: contact.matchId,
            partnerName: contact.name
        )
    }

    private func hostReputation(for thread: DiscoverViewModel.PlaceThread) -> AttendanceReputationSummary? {
        guard !thread.primaryHostId.isEmpty else { return nil }
        return AttendanceReputationStore.shared.summary(
            for: thread.primaryHostId,
            fallbackDisplayName: thread.primaryHostName
        )
    }

}

private struct DirectChatDestination: Identifiable {
    let matchId: String
    let partnerName: String
    var id: String { matchId }
}

private struct MostActiveThreadBanner: View {
    let thread: DiscoverViewModel.PlaceThread
    let emoji: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Recent Attendee Notes")
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.78))
                Text("\(thread.sport) • \(thread.place)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(thread.posts.count) attendee notes")
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.78))
            }
            Spacer(minLength: 8)

            if thread.isForYou {
                Text("For You")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UCDavisPalette.deepBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(UCDavisPalette.surface.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(UCDavisPalette.border, lineWidth: 1)
        )
        .shadow(color: UCDavisPalette.navy.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

private struct PlaceConversationCard: View {
    let thread: DiscoverViewModel.PlaceThread
    let emoji: String
    let hostSummary: AttendanceReputationSummary?
    let currentUserId: String?
    @Binding var draftText: String
    let isCommitting: Bool
    let isReportingNoShow: Bool
    let onCommit: () -> Void
    let onReportNoShow: () -> Void
    let onMessageContact: (DiscoverViewModel.DirectContact) -> Void
    let onSend: () -> Void

    private let sectionSpacing: CGFloat = 10
    private let controlMinHeight: CGFloat = 44

    private var isPreCommit: Bool {
        !thread.isUserCommitted
    }

    private var isPostCommit: Bool {
        thread.isUserCommitted
    }

    private var hasPosts: Bool {
        !thread.posts.isEmpty
    }

    private var hasDirectContacts: Bool {
        !thread.directContacts.isEmpty
    }

    private var canCommitToThread: Bool {
        thread.joinableMeetupId != nil
    }

    private var canPost: Bool {
        thread.isUserCommitted && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canReportNoShow: Bool {
        guard thread.isUserCommitted else { return false }
        guard let currentUserId else { return false }
        return currentUserId != thread.primaryHostId && !thread.primaryHostId.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            PlaceThreadHeader(
                emoji: emoji,
                title: "\(thread.sport) • \(thread.place)",
                isForYou: thread.isForYou
            )

            PlaceThreadStatsRow(
                meetupCount: thread.meetupCount,
                participantCount: thread.participantCount,
                friendCount: thread.friendCount
            )

            if let hostSummary {
                HostTrustSignal(summary: hostSummary)
            }

            if isPreCommit {
                PreCommitActionSection(
                    canCommit: canCommitToThread,
                    isCommitting: isCommitting,
                    onCommit: onCommit,
                    controlMinHeight: controlMinHeight
                )
            }

            if isPostCommit {
                PostCommitStatusRow(
                    canReportNoShow: canReportNoShow,
                    isReportingNoShow: isReportingNoShow,
                    onReportNoShow: onReportNoShow,
                    controlMinHeight: controlMinHeight
                )

                if hasDirectContacts {
                    DirectMessageActionSection(
                        contacts: thread.directContacts,
                        onMessageContact: onMessageContact,
                        controlMinHeight: controlMinHeight
                    )
                }

                ConversationComposerSection(
                    posts: thread.posts,
                    draftText: $draftText,
                    canPost: canPost,
                    hasPosts: hasPosts,
                    onSend: onSend,
                    controlMinHeight: controlMinHeight
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(UCDavisPalette.surface.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(UCDavisPalette.border, lineWidth: 1)
        )
        .shadow(color: UCDavisPalette.navy.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

private struct PlaceThreadHeader: View {
    let emoji: String
    let title: String
    let isForYou: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji)
                .font(.title3)

            Text(title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if isForYou {
                Text("For You")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UCDavisPalette.deepBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

private struct PlaceThreadStatsRow: View {
    let meetupCount: Int
    let participantCount: Int
    let friendCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ThreadStatPill(
                    label: "\(meetupCount) events",
                    background: UCDavisPalette.softGold,
                    foreground: UCDavisPalette.textPrimary
                )
                ThreadStatPill(
                    label: "\(participantCount) players",
                    background: UCDavisPalette.softBlue,
                    foreground: UCDavisPalette.textPrimary
                )
                if friendCount > 0 {
                    ThreadStatPill(
                        label: "\(friendCount) friends",
                        background: UCDavisPalette.surfaceMuted,
                        foreground: UCDavisPalette.textPrimary
                    )
                }
            }
            .padding(.vertical, 1)
        }
    }
}

private struct HostTrustSignal: View {
    let summary: AttendanceReputationSummary

    private var noShowText: String {
        "\(summary.noShowCount) no-show report\(summary.noShowCount == 1 ? "" : "s")"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.caption)
                .foregroundColor(UCDavisPalette.deepBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Host Rating \(summary.reputationScore)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(summary.attendanceLabel) • \(summary.eventSuccessLabel)")
                    .font(.caption2)
                    .foregroundColor(UCDavisPalette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 8)

            if summary.noShowCount > 0 {
                Text(noShowText)
                    .font(.caption2)
                    .foregroundColor(UCDavisPalette.danger)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(UCDavisPalette.softGold.opacity(0.45))
        )
    }
}

private struct PreCommitActionSection: View {
    let canCommit: Bool
    let isCommitting: Bool
    let onCommit: () -> Void
    let controlMinHeight: CGFloat

    private var helperText: String {
        canCommit
        ? "Commit to attend to unlock attendee notes and player messaging."
        : "No open event in this thread is available to commit right now."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(helperText)
                .font(.caption)
                .foregroundColor(UCDavisPalette.textMuted)

            if canCommit {
                Button(action: onCommit) {
                    HStack(spacing: 8) {
                        if isCommitting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text("Commit to Attend")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: controlMinHeight)
                    .padding(.horizontal, 12)
                    .background(isCommitting ? Color.gray : UCDavisPalette.deepBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isCommitting)
            }
        }
    }
}

private struct PostCommitStatusRow: View {
    let canReportNoShow: Bool
    let isReportingNoShow: Bool
    let onReportNoShow: () -> Void
    let controlMinHeight: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Label("Committed to attend", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(UCDavisPalette.success)

            Spacer()

            if canReportNoShow {
                Button(action: onReportNoShow) {
                    HStack(spacing: 6) {
                        if isReportingNoShow {
                            ProgressView()
                                .controlSize(.small)
                                .tint(UCDavisPalette.danger)
                        }
                        Text(isReportingNoShow ? "Reporting..." : "Report Host No-show")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .frame(minHeight: controlMinHeight)
                    .padding(.horizontal, 10)
                    .background(UCDavisPalette.danger.opacity(0.12))
                    .foregroundColor(UCDavisPalette.danger)
                    .cornerRadius(10)
                }
                .disabled(isReportingNoShow)
            }
        }
    }
}

private struct DirectMessageActionSection: View {
    let contacts: [DiscoverViewModel.DirectContact]
    let onMessageContact: (DiscoverViewModel.DirectContact) -> Void
    let controlMinHeight: CGFloat

    var body: some View {
        if contacts.count == 1, let onlyContact = contacts.first {
            Button(action: { onMessageContact(onlyContact) }) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Message \(onlyContact.name)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, minHeight: controlMinHeight)
                .padding(.horizontal, 12)
                .background(UCDavisPalette.deepBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        } else {
            Menu {
                ForEach(contacts) { contact in
                    Button("Message \(contact.name)") {
                        onMessageContact(contact)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Message a Joined Player")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, minHeight: controlMinHeight)
                .padding(.horizontal, 12)
                .background(UCDavisPalette.deepBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

private struct ConversationComposerSection: View {
    let posts: [DiscoverViewModel.ConversationPost]
    @Binding var draftText: String
    let canPost: Bool
    let hasPosts: Bool
    let onSend: () -> Void
    let controlMinHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendee Notes")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(UCDavisPalette.gold.opacity(0.8))

            if hasPosts {
                RotatingConversationStrip(posts: posts)
            } else {
                Text("No attendee notes yet. Be the first to post.")
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.textMuted)
            }

            HStack(spacing: 8) {
                TextField("Add an attendee note", text: $draftText)
                    .padding(.horizontal, 12)
                    .frame(minHeight: controlMinHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(UCDavisPalette.surfaceMuted)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(UCDavisPalette.border.opacity(0.55), lineWidth: 1)
                    )

                Button("Post", action: onSend)
                    .fontWeight(.semibold)
                    .frame(minHeight: controlMinHeight)
                    .padding(.horizontal, 12)
                    .background(canPost ? UCDavisPalette.deepBlue : UCDavisPalette.deepBlue.opacity(0.35))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canPost)
            }
        }
    }
}

private struct RotatingConversationStrip: View {
    let posts: [DiscoverViewModel.ConversationPost]
    
    private var previewPosts: [DiscoverViewModel.ConversationPost] {
        Array(posts.prefix(2))
    }

    var body: some View {
        if previewPosts.isEmpty {
            Text("No attendee notes yet.")
                .font(.caption)
                .foregroundColor(UCDavisPalette.textMuted)
        } else {
            VStack(spacing: 8) {
                ForEach(previewPosts) { post in
                    ConversationBubble(
                        post: post
                    )
                }
                if posts.count > previewPosts.count {
                    Text("+\(posts.count - previewPosts.count) more messages")
                        .font(.caption2)
                        .foregroundColor(UCDavisPalette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct ThreadStatPill: View {
    let label: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background)
            .cornerRadius(10)
    }
}

private struct ConversationBubble: View {
    let post: DiscoverViewModel.ConversationPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(post.author)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(UCDavisPalette.textPrimary)
                Text(post.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(UCDavisPalette.textMuted)
            }

            Text(post.text)
                .font(.subheadline)
                .foregroundColor(UCDavisPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        switch post.kind {
        case .host:
            return UCDavisPalette.softGold
        case .update:
            return UCDavisPalette.softBlue
        case .note:
            return UCDavisPalette.surfaceMuted
        }
    }

    private var borderColor: Color {
        switch post.kind {
        case .host:
            return UCDavisPalette.gold.opacity(0.45)
        case .update:
            return UCDavisPalette.deepBlue.opacity(0.35)
        case .note:
            return UCDavisPalette.border.opacity(0.7)
        }
    }
}
