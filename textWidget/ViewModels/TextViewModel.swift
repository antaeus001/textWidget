import SwiftUI
import WidgetKit

class TextViewModel: ObservableObject {
    @Published var model: TextModel {
        didSet {
            saveText()
        }
    }
    
    private let userDefaults = UserDefaults(suiteName: Constants.appGroupId)
    
    init() {
        // 尝试从UserDefaults加载数据
        if let data = userDefaults?.data(forKey: Constants.widgetUserDefaultsKey),
           let savedModel = try? JSONDecoder().decode(TextModel.self, from: data) {
            self.model = savedModel
        } else {
            self.model = TextModel()
        }
    }
    
    func saveText() {
        guard let data = try? JSONEncoder().encode(model) else { return }
        userDefaults?.set(data, forKey: Constants.widgetUserDefaultsKey)
        userDefaults?.synchronize() // 强制同步
        
        // 通知Widget更新
        WidgetCenter.shared.reloadAllTimelines()
    }
} 