import SwiftUI

struct MeetupDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: MeetupViewModel
    let meetup: Meetup
    @Environment(\.dismiss) var dismiss

    @State private var selectedRating: EventTurnoutRating?

    private var currentUserId: String { authViewModel.user?.id ?? "" }
    private var isHost: Bool { meetup.hostId == currentUserId }
    private var isJoined: Bool { meetup.participants?.contains(currentUserId) ?? false }
    private var metadata: SpontaneousEventMetadata { meetup.spontaneousMetadata }
    private var showWalkableHint: Bool {
        (metadata.notifyNearbyPlayers ?? false) || CampusSpotCatalog.isWalkableSpot(meetup.location)
    }

    var body: some View {
        ZStack {
            UCDavisBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(meetup.sport)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(UCDavisPalette.softGold)
                                .foregroundColor(UCDavisPalette.gold)
                                .cornerRadius(8)

                            if let format = metadata.format, !format.isEmpty {
                                Text(format)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(UCDavisPalette.surfaceMuted)
                                    .foregroundColor(UCDavisPalette.gold)
                                    .cornerRadius(8)
                            }
                        }

                        Text(meetup.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UCDavisPalette.gold)

                        Text("Hosted by \(meetup.hostName)")
                            .font(.subheadline)
                            .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                    }

                    Divider()
                        .overlay(UCDavisPalette.border)

                    VStack(alignment: .leading, spacing: 12) {
                        if let desc = meetup.cleanDescription, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundColor(UCDavisPalette.gold)
                        }

                        Label(meetup.date, systemImage: "calendar")
                        Label(meetup.time, systemImage: "clock")

                        if let location = meetup.location, !location.isEmpty {
                            Label(location, systemImage: "mappin.and.ellipse")
                        }

                        if showWalkableHint {
                            Label("Walking-distance alerts enabled", systemImage: "figure.walk")
                                .foregroundColor(UCDavisPalette.success)
                                .font(.subheadline)
                        }

                        if let note = metadata.transportationNote, !note.isEmpty {
                            Label(note, systemImage: "car.fill")
                                .font(.subheadline)
                                .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                        }
                    }
                    .foregroundColor(UCDavisPalette.gold)

                    if let levels = meetup.skillLevels, !levels.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Skill Levels")
                                .font(.headline)
                            HStack(spacing: 6) {
                                ForEach(levels, id: \.self) { level in
                                    Text(level)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(UCDavisPalette.surfaceMuted)
                                        .foregroundColor(UCDavisPalette.gold)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Players (\(meetup.participantCount)/\(meetup.playerLimit ?? 10))")
                            .font(.headline)
                            .foregroundColor(UCDavisPalette.gold)
                        ProgressView(value: Double(meetup.participantCount), total: Double(meetup.playerLimit ?? 10))
                            .tint(meetup.isFull ? UCDavisPalette.danger : UCDavisPalette.deepBlue)

                        let needed = max(metadata.playersNeeded ?? meetup.openSpots, 0)
                        Text(needed == 0 ? "Roster is full" : "Looking for \(needed) more player\(needed == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(needed == 0 ? UCDavisPalette.textMuted : UCDavisPalette.gold)
                    }

                    Divider()
                        .overlay(UCDavisPalette.border)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Turnout Rating")
                            .font(.headline)
                            .foregroundColor(UCDavisPalette.gold)
                        Text("Rate this event after it happens.")
                            .font(.caption)
                            .foregroundColor(UCDavisPalette.gold.opacity(0.72))

                        HStack(spacing: 10) {
                            ForEach(EventTurnoutRating.allCases, id: \.self) { rating in
                                Button(action: {
                                    selectedRating = rating
                                    EventRatingStore.shared.setRating(rating, for: meetup.id)
                                    AttendanceReputationStore.shared.recordHostEventSuccess(
                                        hostId: meetup.hostId,
                                        displayName: meetup.hostName,
                                        meetupId: meetup.id,
                                        rating: rating
                                    )
                                    if let currentUser = authViewModel.user {
                                        AttendanceReputationStore.shared.recordAttendance(
                                            userId: currentUser.id,
                                            displayName: currentUser.displayName,
                                            meetupId: meetup.id
                                        )
                                    }
                                }) {
                                    Image(systemName: (selectedRating?.rawValue ?? 0) >= rating.rawValue ? "star.fill" : "star")
                                        .font(.title3)
                                        .foregroundColor(UCDavisPalette.gold)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Rate \(rating.rawValue) star\(rating.rawValue == 1 ? "" : "s")")
                            }
                        }

                        if let selectedRating {
                            Text(selectedRating.label)
                                .font(.subheadline)
                                .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                        }
                    }

                    Divider()
                        .overlay(UCDavisPalette.border)

                    if isHost {
                        Button(action: {
                            Task {
                                await viewModel.cancelMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                dismiss()
                            }
                        }) {
                            Text("Cancel Event")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(UCDavisPalette.danger)
                                .cornerRadius(Radius.button)
                        }
                        .accessibilityLabel("Cancel this event")
                    } else if isJoined {
                        Button(action: {
                            Task {
                                await viewModel.leaveMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                dismiss()
                            }
                        }) {
                            Text("Leave Event")
                                .font(.headline)
                                .foregroundColor(UCDavisPalette.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(UCDavisPalette.gold.opacity(0.20))
                                .cornerRadius(Radius.button)
                        }
                        .accessibilityLabel("Leave \(meetup.title)")
                    } else if !meetup.isFull {
                        Button(action: {
                            Task {
                                await viewModel.joinMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                dismiss()
                            }
                        }) {
                            Text("Join Event")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [UCDavisPalette.deepBlue, UCDavisPalette.navy],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(Radius.button)
                        }
                        .accessibilityLabel("Join \(meetup.title)")
                    } else {
                        Text("This event is full")
                            .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                .ucDavisCardSurface(cornerRadius: 18)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .foregroundColor(UCDavisPalette.gold)
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .tint(UCDavisPalette.gold)
        .onAppear {
            selectedRating = EventRatingStore.shared.rating(for: meetup.id)
        }
    }
}
