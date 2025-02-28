import Foundation
import SwiftUI

public class ConfigManager {
    public static let shared = ConfigManager()
    private let userDefaults = UserDefaults(suiteName: Constants.appGroupId)
    
    private init() {}
    
    public var currentConfig: ConfigInfo? {
        guard let data = userDefaults?.data(forKey: Constants.configKey),
              let config = try? JSONDecoder().decode(ConfigInfo.self, from: data) else {
            return nil
        }
        return config
    }
    
    public func saveConfig(_ config: ConfigInfo) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        userDefaults?.set(data, forKey: Constants.configKey)
    }
}

public struct ConfigInfo: Codable {
    public var name: String
    public var id: Int
    public var contents: [ContentItem]
    public var rotationInterval: TimeInterval
    
    public init(name: String = "新配置", id: Int, contents: [ContentItem] = [], rotationInterval: TimeInterval = 5) {
        self.name = name
        self.id = id
        self.contents = contents
        self.rotationInterval = rotationInterval
    }
}

public struct ContentItem: Codable, Identifiable {
    public let id: UUID
    public var text: String
    
    public init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
} 