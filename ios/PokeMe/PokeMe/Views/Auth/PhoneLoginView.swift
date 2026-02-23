import SwiftUI

struct PhoneLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showVerification = false
    @State private var normalizedPhone = ""
    @State private var animateIcons = false

    private let sportEmojis = ["🏀", "⚽", "🎾", "🏐", "🏸"]

    private var canSend: Bool {
        phoneNumber.filter(\.isNumber).count >= 10 && !isLoading
    }

    var body: some View {
        ZStack {
            UCDavisBackground(animated: true)

            VStack(spacing: 28) {
                hero
                    .padding(.top, 20)

                phoneCard

                Spacer(minLength: 14)

                Text("Phone verification only")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 22)
        }
        .sheet(isPresented: $showVerification) {
            VerifyCodeView(phone: normalizedPhone)
                .environmentObject(authViewModel)
        }
        .onAppear {
            animateIcons = true
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(Array(sportEmojis.enumerated()), id: \.offset) { index, emoji in
                    Text(emoji)
                        .font(.system(size: 24))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(UCDavisPalette.surface.opacity(0.5))
                        )
                        .offset(y: animateIcons ? (index.isMultiple(of: 2) ? -5 : 5) : 0)
                        .animation(
                            .easeInOut(duration: 1.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                            value: animateIcons
                        )
                }
            }

            VStack(spacing: 6) {
                Text("PokeMe")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)

                Text("Find your UC Davis sports partner")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.84))
            }
        }
    }

    private var phoneCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Get Started")
                .font(.title3.weight(.bold))
                .foregroundColor(UCDavisPalette.navy)

            Text("Enter your phone number and we’ll send a one-time code.")
                .font(.subheadline)
                .foregroundColor(UCDavisPalette.textMuted)

            HStack(spacing: 12) {
                Text("+1")
                    .font(.title3.weight(.bold))
                    .foregroundColor(UCDavisPalette.textPrimary)
                    .padding(.leading, 6)

                TextField("(530) 555-0000", text: $phoneNumber)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(UCDavisPalette.textPrimary)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(UCDavisPalette.surfaceMuted.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(UCDavisPalette.border.opacity(0.7), lineWidth: 1)
            )

            Text("For testing: 530-555-0000")
                .font(.caption.weight(.medium))
                .foregroundColor(UCDavisPalette.textMuted)

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(UCDavisPalette.danger)
            }

            Button(action: sendCode) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send Code")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            canSend
                                ? LinearGradient(
                                    colors: [UCDavisPalette.deepBlue, UCDavisPalette.navy],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.16)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                )
                .foregroundColor(canSend ? .white : UCDavisPalette.textMuted)
                .shadow(color: canSend ? UCDavisPalette.gold.opacity(0.34) : .clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!canSend)
        }
        .padding(22)
        .ucDavisCardSurface(cornerRadius: 24)
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil

        let digits = phoneNumber.filter(\.isNumber)
        normalizedPhone = "+1" + digits

        Task {
            do {
                _ = try await PhoneAuthService.shared.sendCode(phone: normalizedPhone)
                await MainActor.run {
                    isLoading = false
                    showVerification = true
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.errorDescription
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    PhoneLoginView()
        .environmentObject(AuthViewModel())
}
