import Foundation
import SwiftUI

enum Quadrant: String, CaseIterable, Codable {
    case schedule
    case doIt
    case delegate
    case delete

    var title: String {
        switch self {
        case .schedule: "Schedule"
        case .doIt:     "Do"
        case .delegate: "Delegate"
        case .delete:   "Delete"
        }
    }

    var subtitle: String {
        switch self {
        case .schedule: "important · not urgent"
        case .doIt:     "important · urgent"
        case .delegate: "not important · urgent"
        case .delete:   "not important · not urgent"
        }
    }

    var tint: Color {
        switch self {
        case .schedule: Color(red: 0.30, green: 0.55, blue: 0.95)
        case .doIt:     Color(red: 0.98, green: 0.55, blue: 0.20)
        case .delegate: Color(red: 0.65, green: 0.40, blue: 0.85)
        case .delete:   Color(red: 0.55, green: 0.55, blue: 0.60)
        }
    }

    var symbol: String {
        switch self {
        case .schedule: "calendar"
        case .doIt:     "bolt.fill"
        case .delegate: "person.2.fill"
        case .delete:   "tray.fill"
        }
    }

    static func from(urgency: Double, importance: Double) -> Quadrant {
        switch (urgency >= 0.5, importance >= 0.5) {
        case (false, true):  return .schedule
        case (true,  true):  return .doIt
        case (false, false): return .delete
        case (true,  false): return .delegate
        }
    }
}
