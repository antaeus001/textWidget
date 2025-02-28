import Foundation

struct PlaylistModel: Codable {
    var items: [Int]  // 存储文本ID的列表
    
    init(items: [Int] = []) {
        self.items = items
    }
} 