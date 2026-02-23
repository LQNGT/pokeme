import SwiftUI

func sportEmoji(_ sport: String) -> String {
    switch sport.lowercased() {
    case "basketball": return "🏀"
    case "tennis": return "🎾"
    case "soccer": return "⚽"
    case "volleyball": return "🏐"
    case "badminton": return "🏸"
    case "running": return "🏃"
    case "swimming": return "🏊"
    case "cycling": return "🚴"
    case "table tennis": return "🏓"
    case "football": return "🏈"
    case "baseball": return "⚾"
    case "golf": return "⛳"
    case "hiking": return "🥾"
    case "yoga": return "🧘"
    case "rock climbing": return "🧗"
    default: return "🏅"
    }
}

func sportGradient(_ sport: String) -> [Color] {
    switch sport.lowercased() {
    case "basketball": return [.orange, .red]
    case "tennis": return [.green, .yellow]
    case "soccer": return [.green, .mint]
    case "volleyball": return [.yellow, .orange]
    case "badminton": return [.blue, .cyan]
    case "running": return [.red, .pink]
    case "swimming": return [.blue, .cyan]
    case "cycling": return [.purple, .pink]
    case "table tennis": return [.red, .orange]
    case "football": return [.brown, .orange]
    case "baseball": return [.red, .blue]
    case "golf": return [.green, .teal]
    case "hiking": return [.brown, .green]
    case "yoga": return [.purple, .indigo]
    case "rock climbing": return [.gray, .orange]
    default: return [UCDavisPalette.deepBlue, UCDavisPalette.navy]
    }
}

func formatMessageTime(_ isoString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    var date: Date?
    date = formatter.date(from: isoString)

    if date == nil {
        formatter.formatOptions = [.withInternetDateTime]
        date = formatter.date(from: isoString)
    }

    guard let date = date else { return "" }

    let displayFormatter = DateFormatter()
    if Calendar.current.isDateInToday(date) {
        displayFormatter.timeStyle = .short
    } else {
        displayFormatter.dateStyle = .short
    }
    return displayFormatter.string(from: date)
}
