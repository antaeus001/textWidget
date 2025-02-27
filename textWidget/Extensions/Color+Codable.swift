import SwiftUI

extension Color: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // 将颜色转换为UIColor，然后获取RGBA值
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // 将RGBA值编码为字符串
        let colorString = "\(r);\(g);\(b);\(a)"
        try container.encode(colorString)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorString = try container.decode(String.self)
        
        // 从字符串解析RGBA值
        let components = colorString.split(separator: ";").compactMap { Double($0) }
        guard components.count == 4 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid color format")
        }
        
        self.init(red: components[0], 
                 green: components[1], 
                 blue: components[2], 
                 opacity: components[3])
    }
} 