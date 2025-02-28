import ActivityKit
import WidgetKit

struct TextWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let text: String
        let model: TextModel
        let currentIndex: Int
        
        // 实现 Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
            hasher.combine(currentIndex)
            // 由于 TextModel 可能不是 Hashable，我们只使用它的 text 属性
            hasher.combine(model.text)
        }
        
        // 实现 Equatable
        static func == (lhs: ContentState, rhs: ContentState) -> Bool {
            return lhs.text == rhs.text &&
                   lhs.currentIndex == rhs.currentIndex &&
                   lhs.model == rhs.model
        }
    }
} 