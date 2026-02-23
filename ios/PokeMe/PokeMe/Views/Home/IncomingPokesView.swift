import SwiftUI

struct IncomingPokesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: PokesViewModel
    @State private var animateEmpty = false

    var body: some View {
        NavigationView {
            ZStack {
                UCDavisBackground()

                Group {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(UCDavisPalette.gold)
                            Text("Loading pokes...")
                                .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                        }
                    } else if viewModel.incomingPokes.isEmpty {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [UCDavisPalette.gold.opacity(0.15), UCDavisPalette.deepBlue.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(animateEmpty ? 1.1 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                        value: animateEmpty
                                    )

                                Image(systemName: "hand.point.right.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            Text("No pokes yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(UCDavisPalette.cream.opacity(0.92))

                            Text("When someone pokes you, they'll show up here!")
                                .foregroundColor(UCDavisPalette.cream.opacity(0.84))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .onAppear { animateEmpty = true }
                    } else {
                        List(viewModel.incomingPokes) { poke in
                            IncomingPokeRow(
                                poke: poke,
                                onPokeBack: {
                                    Task {
                                        await viewModel.pokeBack(
                                            token: authViewModel.getToken(),
                                            userId: poke.fromUserId
                                        )
                                    }
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .foregroundColor(UCDavisPalette.gold)
            }
            .navigationTitle("Pokes")
            .tint(UCDavisPalette.gold)
            .task {
                await viewModel.fetchIncomingPokes(token: authViewModel.getToken())
            }
            .onAppear {
                viewModel.startPolling(token: authViewModel.getToken())
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .alert("It's a Match!", isPresented: $viewModel.showMatchAlert) {
                Button("OK") {}
            } message: {
                if let user = viewModel.matchedUser {
                    Text("You and \(user.displayName) both want to play! Head to Matches to start chatting.")
                }
            }
        }
    }
}

struct IncomingPokeRow: View {
    let poke: IncomingPoke
    let onPokeBack: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(base64Picture: poke.fromUser.profilePicture, displayName: poke.fromUser.displayName)

            VStack(alignment: .leading, spacing: 4) {
                Text(poke.fromUser.displayName)
                    .font(.headline)
                    .foregroundColor(UCDavisPalette.gold)

                if let sports = poke.fromUser.sports, !sports.isEmpty {
                    Text(sports.map { $0.sport }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Poke Back button
            Button(action: onPokeBack) {
                Text("Poke Back")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(UCDavisPalette.deepBlue)
                    .cornerRadius(20)
            }
            .accessibilityLabel("Poke back \(poke.fromUser.displayName)")
        }
        .padding(12)
        .ucDavisCardSurface()
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
