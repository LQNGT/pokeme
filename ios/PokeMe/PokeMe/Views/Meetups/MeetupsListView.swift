import SwiftUI

struct MeetupsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MeetupViewModel()
    @State private var showCreateSheet = false
    @State private var selectedMeetup: Meetup?

    private let sports = ["All"] + Sport.allCases.map { $0.rawValue }
    private let locationFilters = ["All Spots", "ARC", "Outdoor Court", "Rec Field", "Other"]
    @State private var selectedSport = "All"
    @State private var selectedLocation = "All Spots"

    private var filteredMeetups: [Meetup] {
        viewModel.meetups.filter { meetup in
            guard selectedLocation != "All Spots" else { return true }
            let location = meetup.location?.lowercased() ?? ""
            switch selectedLocation {
            case "ARC":
                return location.contains("arc")
            case "Outdoor Court":
                return location.contains("outdoor")
            case "Rec Field":
                return location.contains("field")
            case "Other":
                return !location.contains("arc") && !location.contains("outdoor") && !location.contains("field")
            default:
                return true
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                UCDavisBackground()

                VStack(spacing: 0) {
                    // Sport filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sports, id: \.self) { sport in
                                Button(action: {
                                    selectedSport = sport
                                    viewModel.sportFilter = sport == "All" ? nil : sport
                                    Task {
                                        await viewModel.fetchMeetups(token: authViewModel.getToken())
                                    }
                                }) {
                                    Text(sport)
                                        .font(.subheadline)
                                        .fontWeight(selectedSport == sport ? .semibold : .regular)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedSport == sport
                                                ? LinearGradient(colors: [UCDavisPalette.deepBlue, UCDavisPalette.navy], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(
                                                    colors: [UCDavisPalette.surface.opacity(0.96), UCDavisPalette.surface.opacity(0.96)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                        )
                                        .foregroundColor(selectedSport == sport ? .white : UCDavisPalette.textPrimary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(locationFilters, id: \.self) { location in
                                Button(action: { selectedLocation = location }) {
                                    Text(location)
                                        .font(.caption)
                                        .fontWeight(selectedLocation == location ? .semibold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedLocation == location
                                                ? UCDavisPalette.gold.opacity(0.20)
                                                : UCDavisPalette.surface.opacity(0.96)
                                        )
                                        .foregroundColor(selectedLocation == location ? UCDavisPalette.navy : UCDavisPalette.textMuted)
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                    // Meetups list
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading events...")
                            .tint(UCDavisPalette.gold)
                        Spacer()
                    } else if filteredMeetups.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "sportscourt")
                                .font(.system(size: 48))
                                .foregroundColor(UCDavisPalette.cream.opacity(0.86))
                            Text("No spontaneous events")
                                .font(.headline)
                                .foregroundColor(UCDavisPalette.cream.opacity(0.92))
                            Text("Create one to start matching players.")
                                .font(.subheadline)
                                .foregroundColor(UCDavisPalette.cream.opacity(0.82))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredMeetups) { meetup in
                                    MeetupCardView(
                                        meetup: meetup,
                                        currentUserId: authViewModel.user?.id ?? "",
                                        onJoin: {
                                            Task {
                                                await viewModel.joinMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                            }
                                        },
                                        onLeave: {
                                            Task {
                                                await viewModel.leaveMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                            }
                                        },
                                        onCancel: {
                                            Task {
                                                await viewModel.cancelMeetup(token: authViewModel.getToken(), meetupId: meetup.id)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        selectedMeetup = meetup
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .foregroundColor(UCDavisPalette.gold)
            }
            .navigationTitle("Spontaneous")
            .tint(UCDavisPalette.gold)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .font(.title3)
                    }
                    .accessibilityLabel("Create new event")
                }
            }
            .task {
                await viewModel.fetchMeetups(token: authViewModel.getToken())
            }
            .refreshable {
                await viewModel.fetchMeetups(token: authViewModel.getToken())
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateMeetupView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedMeetup) { meetup in
                NavigationView {
                    MeetupDetailView(viewModel: viewModel, meetup: meetup)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
