import Foundation

class MatchService {
    static let shared = MatchService()

    private init() {}

    func getTodayMatch(token: String) async throws -> MatchResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.todayMatch,
            method: .GET,
            token: token
        )
    }

    func disconnect(token: String) async throws -> DisconnectResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.disconnect,
            method: .POST,
            token: token
        )
    }

    func poke(token: String) async throws -> PokeResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.poke,
            method: .POST,
            token: token
        )
    }

    func getMatchHistory(token: String) async throws -> MatchHistoryResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.matchHistory,
            method: .GET,
            token: token
        )
    }

    func blockUser(token: String, userId: String) async throws -> BlockResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.block,
            method: .POST,
            body: BlockRequest(userId: userId),
            token: token
        )
    }

    func reportUser(token: String, userId: String, reason: String) async throws -> ReportResponse {
        return try await NetworkService.shared.request(
            endpoint: Constants.Endpoints.report,
            method: .POST,
            body: ReportRequest(userId: userId, reason: reason),
            token: token
        )
    }
}
