import SwiftUI
import WidgetKit

class TextViewModel: ObservableObject {
    @Published var currentConfig: ConfigInfo
    private let configManager = ConfigManager.shared
    
    @Published var model: TextModel {
        didSet {
            saveText()
        }
    }
    
    private let userDefaults = UserDefaults(suiteName: Constants.appGroupId)
    
    init() {
        // 从 ConfigManager 加载配置，如果没有则创建新配置
        if let savedConfig = configManager.currentConfig {
            currentConfig = savedConfig
        } else {
            currentConfig = ConfigInfo(name: "默认配置", id: 1)
        }
        // 尝试从UserDefaults加载数据
        if let data = userDefaults?.data(forKey: Constants.widgetUserDefaultsKey),
           let savedModel = try? JSONDecoder().decode(TextModel.self, from: data) {
            self.model = savedModel
        } else {
            self.model = TextModel()
        }
    }
    
    // 添加轮播内容
    func addContent(_ text: String) {
        let newContent = ContentItem(text: text)
        currentConfig.contents.append(newContent)
        saveConfig()
    }
    
    // 删除轮播内容
    func removeContent(at index: Int) {
        currentConfig.contents.remove(at: index)
        saveConfig()
    }
    
    // 更新轮播间隔
    func updateRotationInterval(_ interval: TimeInterval) {
        currentConfig.rotationInterval = interval
        saveConfig()
    }
    
    // 保存配置
    private func saveConfig() {
        configManager.saveConfig(currentConfig)
    }
    
    func saveText() {
        guard let data = try? JSONEncoder().encode(model) else { return }
        userDefaults?.set(data, forKey: Constants.widgetUserDefaultsKey)
        userDefaults?.synchronize() // 强制同步
        
        // 通知Widget更新
        WidgetCenter.shared.reloadAllTimelines()
    }
} 