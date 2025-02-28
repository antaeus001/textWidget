import ActivityKit
import WidgetKit
import SharedModels

struct TextWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let text: String
        let model: TextModel
        let currentIndex: Int
        
        // 实现 Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(text)
            hasher.combine(currentIndex)
            hasher.combine(model.text)
            hasher.combine(model.fontSize)
        }
        
        // 实现 Equatable
        public static func == (lhs: ContentState, rhs: ContentState) -> Bool {
            return lhs.text == rhs.text &&
                   lhs.currentIndex == rhs.currentIndex &&
                   lhs.model == rhs.model
        }
        
        // 添加初始化器
        public init(text: String, model: TextModel, currentIndex: Int) {
            self.text = text
            self.model = model
            self.currentIndex = currentIndex
        }
    }
    
    // ActivityAttributes 需要至少一个属性
    let id: String
} 