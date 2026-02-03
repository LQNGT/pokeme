import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var matchViewModel = MatchViewModel()
    @State private var showProfile = false
    @State private var showChat = false
    @State private var showMatchHistory = false
    @State private var showDisconnectAlert = false
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var currentPartnerName = ""
    @State private var currentPartnerId = ""

    var body: some View {
        NavigationView {
            VStack {
                switch matchViewModel.matchState {
                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Finding your match...")
                            .foregroundColor(.secondary)
                    }

                case .matched(let match):
                    VStack(spacing: 24) {
                        Text("Today's Match")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        MatchCardView(match: match, onPoke: {
                            Task {
                                await matchViewModel.poke(token: authViewModel.getToken())
                            }
                        }, onChat: {
                            currentPartnerName = match.partnerName
                            showChat = true
                        }, onBlock: {
                            currentPartnerId = match.partnerId
                            currentPartnerName = match.partnerName
                            showBlockAlert = true
                        }, onReport: {
                            currentPartnerId = match.partnerId
                            currentPartnerName = match.partnerName
                            showReportSheet = true
                        })

                        Button(action: {
                            showDisconnectAlert = true
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }

                        Spacer()
                    }
                    .padding(.top, 40)

                case .waiting:
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("You're in the pool!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("We're looking for your perfect match.\nCheck back soon!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button(action: {
                            Task {
                                await matchViewModel.fetchTodayMatch(token: authViewModel.getToken())
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()

                case .disconnected(let nextMatchAt):
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("See you tomorrow!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("You disconnected from today's match.\nA new match will be available at midnight.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                case .error(let message):
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("Oops!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(message)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button(action: {
                            Task {
                                await matchViewModel.fetchTodayMatch(token: authViewModel.getToken())
                            }
                        }) {
                            Text("Try Again")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("PokeMe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showMatchHistory = true
                        }) {
                            Label("Match History", systemImage: "clock.arrow.circlepath")
                        }
                        Button(action: {
                            showProfile = true
                        }) {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showChat) {
                ChatView(partnerName: currentPartnerName)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showMatchHistory) {
                MatchHistoryView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showReportSheet) {
                ReportView(partnerName: currentPartnerName) { reason in
                    Task {
                        _ = await matchViewModel.reportUser(
                            token: authViewModel.getToken(),
                            userId: currentPartnerId,
                            reason: reason
                        )
                    }
                }
            }
            .alert("Are you sure?", isPresented: $showDisconnectAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Disconnect", role: .destructive) {
                    Task {
                        await matchViewModel.disconnect(token: authViewModel.getToken())
                    }
                }
            } message: {
                Text("You won't be able to match with anyone else until tomorrow. Only disconnect if necessary.")
            }
            .alert("Block \(currentPartnerName)?", isPresented: $showBlockAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Block", role: .destructive) {
                    Task {
                        _ = await matchViewModel.blockUser(
                            token: authViewModel.getToken(),
                            userId: currentPartnerId
                        )
                    }
                }
            } message: {
                Text("You will be disconnected and never matched with this person again.")
            }
            .task {
                await matchViewModel.fetchTodayMatch(token: authViewModel.getToken())
            }
            .onAppear {
                matchViewModel.startPolling(token: authViewModel.getToken())
            }
            .onDisappear {
                matchViewModel.stopPolling()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
