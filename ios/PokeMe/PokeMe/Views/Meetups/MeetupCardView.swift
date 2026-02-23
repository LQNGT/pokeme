import SwiftUI

struct MeetupCardView: View {
    let meetup: Meetup
    let currentUserId: String
    let onJoin: () -> Void
    let onLeave: () -> Void
    let onCancel: () -> Void

    private var isHost: Bool { meetup.hostId == currentUserId }
    private var isJoined: Bool { meetup.participants?.contains(currentUserId) ?? false }
    private var metadata: SpontaneousEventMetadata { meetup.spontaneousMetadata }
    private var playersNeededLabel: String {
        let needed = max(metadata.playersNeeded ?? meetup.openSpots, 0)
        let suffix = needed == 1 ? "" : "s"
        return needed == 0 ? "Roster full" : "Need \(needed) more player\(suffix)"
    }
    private var showWalkableBadge: Bool {
        (metadata.notifyNearbyPlayers ?? false) || CampusSpotCatalog.isWalkableSpot(meetup.location)
    }

    private var sportIcon: String {
        switch meetup.sport.lowercased() {
        case "basketball": return "basketball"
        case "tennis": return "tennis.racket"
        case "soccer": return "soccerball"
        case "volleyball": return "volleyball"
        case "badminton": return "bird"
        case "football": return "football"
        case "running": return "figure.run"
        case "swimming": return "figure.pool.swim"
        case "cycling": return "bicycle"
        case "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        default: return "sportscourt"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: sportIcon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(meetup.title)
                        .font(.headline)
                        .foregroundColor(UCDavisPalette.gold)
                    Text("by \(meetup.hostName)")
                        .font(.caption)
                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                }

                Spacer()
            }

            HStack(spacing: 6) {
                Text(meetup.sport)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UCDavisPalette.softGold)
                    .foregroundColor(UCDavisPalette.gold)
                    .cornerRadius(8)

                if let format = metadata.format, !format.isEmpty {
                    Text(format)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(UCDavisPalette.surfaceMuted)
                        .foregroundColor(UCDavisPalette.gold)
                        .cornerRadius(8)
                }

                if showWalkableBadge {
                    Label("Walkable", systemImage: "figure.walk")
                        .font(.caption2)
                        .foregroundColor(UCDavisPalette.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(UCDavisPalette.success.opacity(0.14))
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 16) {
                Label(meetup.date, systemImage: "calendar")
                    .font(.caption)
                Label(meetup.time, systemImage: "clock")
                    .font(.caption)
            }
            .foregroundColor(UCDavisPalette.gold.opacity(0.72))

            if let location = meetup.location, !location.isEmpty {
                Label(location, systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.72))
            }

            if let cleanDescription = meetup.cleanDescription, !cleanDescription.isEmpty {
                Text(cleanDescription)
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                    .lineLimit(2)
            }

            if let levels = meetup.skillLevels, !levels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(levels, id: \.self) { level in
                        Text(level)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(UCDavisPalette.surfaceMuted)
                            .foregroundColor(UCDavisPalette.gold)
                            .cornerRadius(4)
                    }
                }
            }

            HStack {
                let count = meetup.participantCount
                let limit = meetup.playerLimit ?? 10
                ProgressView(value: Double(count), total: Double(limit))
                    .tint(count >= limit ? UCDavisPalette.danger : UCDavisPalette.deepBlue)
                Text("\(count)/\(limit) joined")
                    .font(.caption)
                    .foregroundColor(UCDavisPalette.gold.opacity(0.72))
            }

            Text(playersNeededLabel)
                .font(.caption)
                .foregroundColor(meetup.openSpots == 0 ? UCDavisPalette.textMuted : UCDavisPalette.gold)

            HStack {
                Spacer()
                if isHost {
                    Button(action: onCancel) {
                        Text("Cancel Event")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(UCDavisPalette.danger)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(UCDavisPalette.danger.opacity(0.12))
                            .cornerRadius(Radius.button)
                    }
                    .accessibilityLabel("Cancel this event")
                } else if isJoined {
                    Button(action: onLeave) {
                        Text("Leave")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(UCDavisPalette.gold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(UCDavisPalette.surfaceMuted)
                            .cornerRadius(Radius.button)
                    }
                    .accessibilityLabel("Leave \(meetup.title)")
                } else if !meetup.isFull {
                    Button(action: onJoin) {
                        Text("Join")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
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
                    Text("Full")
                        .font(.subheadline)
                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                }
            }
        }
        .padding()
        .foregroundColor(UCDavisPalette.gold)
        .ucDavisCardSurface()
    }
}
