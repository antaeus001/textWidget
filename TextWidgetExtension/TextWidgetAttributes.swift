import ActivityKit
import WidgetKit
//import SharedModels

struct TextWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let text: String
        let model: TextModel
        let currentIndex: Int
        
        enum CodingKeys: String, CodingKey {
            case text
            case model
            case currentIndex
        }
        
        // 添加 Decodable 实现
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try container.decode(String.self, forKey: .text)
            model = try container.decode(TextModel.self, forKey: .model)
            currentIndex = try container.decode(Int.self, forKey: .currentIndex)
        }
        
        // 添加 Encodable 实现
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(text, forKey: .text)
            try container.encode(model, forKey: .model)
            try container.encode(currentIndex, forKey: .currentIndex)
        }
        
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
    
    // 添加 Codable 支持
    enum CodingKeys: String, CodingKey {
        case id
    }
    
    init(id: String) {
        self.id = id
    }
} 
