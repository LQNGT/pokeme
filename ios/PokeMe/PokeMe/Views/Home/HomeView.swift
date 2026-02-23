import SwiftUI

enum NewUserFlowEvaluator {
    static func needsQuickSetup(_ user: User?) -> Bool {
        guard let user else { return false }
        return !hasConfiguredSports(user) || !hasConfiguredAvailability(user)
    }

    static func hasConfiguredSports(_ user: User?) -> Bool {
        guard let sports = user?.sports else { return false }
        return sports.contains { entry in
            !entry.sport.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    static func hasConfiguredAvailability(_ user: User?) -> Bool {
        guard let availability = user?.availability, !availability.isEmpty else { return false }
        return availability.values.contains { slots in
            slots.contains { slot in
                !slot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var pokesViewModel = PokesViewModel()
    @StateObject private var matchViewModel = MatchViewModel()
    @StateObject private var messageNotificationPoller = MessageNotificationPoller()
    @State private var selectedTab = 0
    @State private var showQuickSetup = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "sportscourt.fill" : "sportscourt")
                        .accessibilityLabel("Discover tab")
                    Text("Discover")
                }
                .tag(0)

            MeetupsListView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.3.fill" : "person.3")
                        .accessibilityLabel("Events tab")
                    Text("Events")
                }
                .tag(1)

            MatchesListView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "message.fill" : "message")
                        .accessibilityLabel("Matches tab")
                    Text("Matches")
                }
                .tag(2)

            IncomingPokesView(viewModel: pokesViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.2.fill" : "person.2")
                        .accessibilityLabel("Pokes tab")
                    Text("Pokes")
                }
                .tag(3)
                .badge(pokesViewModel.pokeCount)

            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        .accessibilityLabel("Profile tab")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(UCDavisPalette.gold)
        .toolbarBackground(UCDavisPalette.navy, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await matchViewModel.fetchMatches(token: authViewModel.getToken())
        }
        .onAppear {
            matchViewModel.startPolling(token: authViewModel.getToken())
            evaluateQuickSetup()
        }
        .onChange(of: authViewModel.user?.id) { _ in
            evaluateQuickSetup()
        }
        .onChange(of: authViewModel.user?.sports?.count ?? 0) { _ in
            evaluateQuickSetup()
        }
        .onChange(of: authViewModel.user?.availability?.count ?? 0) { _ in
            evaluateQuickSetup()
        }
        .onDisappear {
            matchViewModel.stopPolling()
            messageNotificationPoller.stopPolling()
        }
        .sheet(isPresented: $showQuickSetup) {
            QuickSetupView()
                .environmentObject(authViewModel)
        }
    }

    private func evaluateQuickSetup() {
        showQuickSetup = NewUserFlowEvaluator.needsQuickSetup(authViewModel.user)
    }
}

private struct QuickSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss
    @AppStorage("nearbyAlertsEnabled") private var nearbyAlertsEnabled = true

    @State private var selectedSports: Set<String> = []
    @State private var availability: [String: [String]] = [:]

    private let timeSlots = ["Morning", "Afternoon", "Evening"]
    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let dayAbbreviations = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var canSave: Bool {
        !selectedSports.isEmpty && !availability.isEmpty && !profileViewModel.isLoading
    }

    var body: some View {
        NavigationView {
            ZStack {
                UCDavisBackground()

                Form {
                    Section {
                        Text("Set your sports and availability for UC Davis pickup games and faster nearby event matching.")
                            .font(.subheadline)
                            .foregroundColor(UCDavisPalette.gold.opacity(0.78))
                    }

                    Section("Sports You Play") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Sport.allCases, id: \.self) { sport in
                                let isSelected = selectedSports.contains(sport.rawValue)
                                Button(action: { toggleSport(sport.rawValue) }) {
                                    HStack {
                                        Text(sport.rawValue)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                        Spacer(minLength: 4)
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(isSelected ? UCDavisPalette.deepBlue : UCDavisPalette.surfaceMuted)
                                    .foregroundColor(isSelected ? .white : UCDavisPalette.textPrimary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Section("Availability") {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text("")
                                    .frame(width: 70, alignment: .leading)
                                ForEach(dayAbbreviations, id: \.self) { day in
                                    Text(day)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))
                                }
                            }
                            .padding(.bottom, 6)

                            ForEach(timeSlots, id: \.self) { slot in
                                HStack(spacing: 0) {
                                    Text(slot)
                                        .font(.caption)
                                        .frame(width: 70, alignment: .leading)
                                        .foregroundColor(UCDavisPalette.gold.opacity(0.72))

                                    ForEach(Array(zip(days, dayAbbreviations)), id: \.0) { day, _ in
                                        let isSelected = availability[day]?.contains(slot) ?? false
                                        Button(action: { toggleAvailability(day: day, slot: slot) }) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(isSelected ? UCDavisPalette.deepBlue : UCDavisPalette.surfaceMuted)
                                                .frame(height: 36)
                                                .overlay(
                                                    isSelected
                                                        ? Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                        : nil
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .padding(2)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Nearby Alerts") {
                        Toggle("Notify me about walkable events", isOn: $nearbyAlertsEnabled)
                            .tint(UCDavisPalette.deepBlue)
                    }

                    if let error = profileViewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(UCDavisPalette.danger)
                                .font(.caption)
                        }
                    }
                }
                .foregroundColor(UCDavisPalette.gold)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Quick Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Later") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveSetup() }
                    }
                    .tint(UCDavisPalette.gold)
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadCurrentValues)
        }
    }

    private func toggleSport(_ sport: String) {
        if selectedSports.contains(sport) {
            selectedSports.remove(sport)
        } else {
            selectedSports.insert(sport)
        }
    }

    private func toggleAvailability(day: String, slot: String) {
        var daySlots = availability[day] ?? []
        if daySlots.contains(slot) {
            daySlots.removeAll { $0 == slot }
        } else {
            daySlots.append(slot)
        }
        availability[day] = daySlots.isEmpty ? nil : daySlots
    }

    private func loadCurrentValues() {
        guard let user = authViewModel.user else { return }
        selectedSports = Set((user.sports ?? []).map(\.sport))
        availability = user.availability ?? [:]
    }

    private func saveSetup() async {
        guard let user = authViewModel.user else { return }

        let sportsPayload = selectedSports.sorted().map {
            SportEntry(sport: $0, skillLevel: SkillLevel.beginner.rawValue)
        }

        if let updatedUser = await profileViewModel.updateProfile(
            token: authViewModel.getToken(),
            displayName: user.displayName,
            major: user.major,
            bio: user.bio,
            socials: user.socials,
            sports: sportsPayload,
            collegeYear: user.collegeYear,
            availability: availability
        ) {
            authViewModel.user = updatedUser
            dismiss()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
