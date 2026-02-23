import SwiftUI

struct DiscoverCardView: View {
    let user: User
    let onPoke: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @State private var pulsePrimaryAction = false

    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let dayAbbrs = ["M", "T", "W", "T", "F", "S", "S"]
    private let timeSlots = ["Morning", "Afternoon", "Evening"]

    var body: some View {
        VStack(spacing: 0) {
            heroSection

            VStack(alignment: .leading, spacing: 16) {
                if let topReason = user.recommendationReasons?.first, !topReason.isEmpty {
                    recommendationReason(topReason)
                }

                if let sports = user.sports, !sports.isEmpty {
                    sportsSection(sports)
                }

                if let availability = user.availability, !availability.isEmpty {
                    availabilitySection(availability)
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(UCDavisPalette.textMuted)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                actionRow
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [UCDavisPalette.surface.opacity(0.98), UCDavisPalette.surfaceMuted.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(UCDavisPalette.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .scaleEffect(appeared ? 1.0 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulsePrimaryAction.toggle()
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = decodedProfileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 330)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [UCDavisPalette.deepBlue, UCDavisPalette.navy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 330)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 100, weight: .black, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.18))
                    )
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55), Color.black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 170)
            .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(user.displayName)
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let year = user.collegeYear {
                        Text(year)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(UCDavisPalette.gold.opacity(0.9))
                            .foregroundColor(UCDavisPalette.navy)
                            .clipShape(Capsule())
                    }
                }

                if let major = user.major, !major.isEmpty {
                    Label(major, systemImage: "book.closed.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.9))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let score = user.recommendationScore {
                Text("\(Int(score.rounded()))% Match")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(UCDavisPalette.gold.opacity(0.94))
                    .foregroundColor(UCDavisPalette.navy)
                    .clipShape(Capsule())
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    private func recommendationReason(_ reason: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundColor(UCDavisPalette.gold)
                .font(.subheadline.weight(.bold))

            Text(reason)
                .font(.caption.weight(.semibold))
                .foregroundColor(UCDavisPalette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(UCDavisPalette.softBlue)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(UCDavisPalette.border.opacity(0.9), lineWidth: 1)
        )
    }

    private func sportsSection(_ sports: [SportEntry]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sports) { sport in
                    HStack(spacing: 6) {
                        Text(sportEmoji(sport.sport))
                        Text(sport.sport)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(sport.skillLevel)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    .foregroundColor(UCDavisPalette.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: sportGradient(sport.sport).map { $0.opacity(0.26) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(UCDavisPalette.border.opacity(0.45), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func availabilitySection(_ availability: [String: [String]]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Availability")
                .font(.caption.weight(.bold))
                .foregroundColor(UCDavisPalette.textPrimary)

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 56, alignment: .leading)
                    ForEach(Array(dayAbbrs.enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(UCDavisPalette.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(timeSlots, id: \.self) { slot in
                    HStack(spacing: 0) {
                        Text(slot)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(UCDavisPalette.textMuted)
                            .frame(width: 56, alignment: .leading)

                        ForEach(days, id: \.self) { day in
                            let isAvailable = availability[day]?.contains(slot) ?? false
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(
                                    isAvailable
                                        ? LinearGradient(
                                            colors: [UCDavisPalette.success, UCDavisPalette.deepBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(height: 21)
                                .padding(1)
                        }
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(UCDavisPalette.surfaceMuted.opacity(0.56))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(UCDavisPalette.border.opacity(0.55), lineWidth: 1)
            )
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: onSkip) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                    Text("Skip")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(UCDavisPalette.surfaceMuted.opacity(0.94))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(UCDavisPalette.danger.opacity(0.58), lineWidth: 1)
                )
                .foregroundColor(UCDavisPalette.textPrimary)
            }
            .accessibilityLabel("Skip \(user.displayName)")

            Button(action: onPoke) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Poke")
                        .fontWeight(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [UCDavisPalette.gold.opacity(0.95), UCDavisPalette.deepBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(pulsePrimaryAction ? 0.8 : 0.35), lineWidth: pulsePrimaryAction ? 2 : 1)
                        .scaleEffect(pulsePrimaryAction ? 1.01 : 1)
                )
                .foregroundColor(UCDavisPalette.navy)
                .shadow(color: UCDavisPalette.gold.opacity(0.22), radius: 10, x: 0, y: 5)
            }
            .accessibilityLabel("Poke \(user.displayName)")
        }
    }

    private var decodedProfileImage: UIImage? {
        guard let pictureData = user.profilePicture else { return nil }
        let stripped = pictureData.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
        guard let imageData = Data(base64Encoded: stripped) else { return nil }
        return UIImage(data: imageData)
    }
}
