import SwiftUI
//import SharedModels
import WidgetKit
import Combine

class TextViewModel: ObservableObject {
    @Published var currentConfig: ConfigInfo
    private let configManager = ConfigManager.shared
    
    @Published var model: TextModel {
        didSet {
            saveModel()
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
        // 从 UserDefaults 加载或使用默认值
        if let data = userDefaults?.data(forKey: Constants.configKey),
           let savedModel = try? JSONDecoder().decode(TextModel.self, from: data) {
            self.model = savedModel
        } else {
            // 创建默认样式的模型
            self.model = TextViewModel.createDefaultModel()
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
    
    private func saveModel() {
        if let encoded = try? JSONEncoder().encode(model) {
            userDefaults?.set(encoded, forKey: Constants.configKey)
            // 通知小组件更新
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // 创建默认样式的模型
    static func createDefaultModel() -> TextModel {
        var model = TextModel()
        
        // 设置默认文本
        model.text = "欢迎使用 AI Widget Text"
        
        // 添加默认轮播文本
        model.texts = [
            "轻松创建精美文本小组件",
            "支持多种样式和颜色自定义",
            "AI 智能生成多条轮播内容"
        ]
        
        // 设置默认样式
        model.fontSize = 24
        model.textColor = Color(red: 0.31, green: 0.54, blue: 0.38) // 与图标颜色匹配的绿色
        model.backgroundColor = Color(red: 0.95, green: 0.98, blue: 0.96) // 淡绿色背景
        model.alignment = .center
        model.borderWidth = 2
        model.borderColor = Color(red: 0.31, green: 0.54, blue: 0.38).opacity(0.5)
        model.rotationInterval = 10.0  // 修改为10秒
        
        return model
    }
} 
