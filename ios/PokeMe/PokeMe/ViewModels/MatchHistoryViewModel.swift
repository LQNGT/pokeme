import Foundation
import SwiftUI

@MainActor
class MatchHistoryViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchHistory(token: String?) async {
        guard let token = token else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await MatchService.shared.getMatchHistory(token: token)
            matches = response.matches
        } catch let error as NetworkError {
            errorMessage = error.errorDescription ?? "Unknown error"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
