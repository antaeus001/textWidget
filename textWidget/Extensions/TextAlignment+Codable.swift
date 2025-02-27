import SwiftUI

extension TextAlignment: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "leading": self = .leading
        case "center": self = .center
        case "trailing": self = .trailing
        default: self = .center
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let rawValue: String
        switch self {
        case .leading: rawValue = "leading"
        case .center: rawValue = "center"
        case .trailing: rawValue = "trailing"
        }
        try container.encode(rawValue)
    }
} 