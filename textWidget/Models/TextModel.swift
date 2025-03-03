import SwiftUI

// 创建一个可编码的颜色类型
public struct CodableColor: Codable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(color: Color) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    public var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

// 创建一个可编码的对齐方式类型
private enum CodableAlignment: String, Codable {
    case leading, center, trailing
    
    init(alignment: TextAlignment) {
        switch alignment {
        case .leading: self = .leading
        case .center: self = .center
        case .trailing: self = .trailing
        }
    }
    
    var alignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

public struct TextModel: Codable, Equatable {
    public var text: String = ""
    public var texts: [String] = []
    public var fontSize: Double = 20
    public var rotationInterval: TimeInterval = 10.0
    public var currentTextIndex: Int = 0  // 添加当前文本索引
    public var borderWidth: Double = 0
    
    // 使用计算属性
    public var textColor: Color {
        get { _textColor.color }
        set { _textColor = CodableColor(color: newValue) }
    }
    
    public var backgroundColor: Color {
        get { _backgroundColor.color }
        set { _backgroundColor = CodableColor(color: newValue) }
    }
    
    public var borderColor: Color {
        get { _borderColor.color }
        set { _borderColor = CodableColor(color: newValue) }
    }
    
    public var alignment: TextAlignment {
        get { _alignment.alignment }
        set { _alignment = CodableAlignment(alignment: newValue) }
    }
    
    // 存储属性
    private var _textColor: CodableColor
    private var _backgroundColor: CodableColor
    private var _alignment: CodableAlignment
    private var _borderColor: CodableColor
    
    public init() {
        self.text = "点击编辑文本"
        self.fontSize = 16
        self._textColor = CodableColor(color: .black)
        self._backgroundColor = CodableColor(color: .white)
        self._alignment = .center
        self.borderWidth = 0
        self._borderColor = CodableColor(color: .clear)
    }
    
    // 添加新的初始化方法
    public init(
        text: String,
        fontSize: CGFloat,
        textColor: Color,
        backgroundColor: Color,
        alignment: TextAlignment,
        borderWidth: CGFloat,
        borderColor: Color
    ) {
        self.text = text
        self.fontSize = Double(fontSize)
        self._textColor = CodableColor(color: textColor)
        self._backgroundColor = CodableColor(color: backgroundColor)
        self._alignment = CodableAlignment(alignment: alignment)
        self.borderWidth = Double(borderWidth)
        self._borderColor = CodableColor(color: borderColor)
    }
    
    // 实现Equatable协议
    public static func == (lhs: TextModel, rhs: TextModel) -> Bool {
        return lhs.text == rhs.text &&
            lhs.texts == rhs.texts &&
            lhs.fontSize == rhs.fontSize &&
            lhs.rotationInterval == rhs.rotationInterval &&
            lhs.currentTextIndex == rhs.currentTextIndex &&
            lhs._textColor == rhs._textColor &&
            lhs._backgroundColor == rhs._backgroundColor &&
            lhs._alignment == rhs._alignment &&
            lhs.borderWidth == rhs.borderWidth &&
            lhs._borderColor == rhs._borderColor
    }
    
    // 实现Codable
    public enum CodingKeys: String, CodingKey {
        case text, texts, fontSize, rotationInterval, currentTextIndex
        case textColorRed, textColorGreen, textColorBlue, textColorOpacity
        case backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorOpacity
        case borderWidth, borderColorRed, borderColorGreen, borderColorBlue, borderColorOpacity
        case alignment
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        text = try container.decode(String.self, forKey: .text)
        texts = try container.decodeIfPresent([String].self, forKey: .texts) ?? []
        fontSize = try container.decode(Double.self, forKey: .fontSize)
        rotationInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .rotationInterval) ?? 5.0
        currentTextIndex = try container.decodeIfPresent(Int.self, forKey: .currentTextIndex) ?? 0
        borderWidth = try container.decode(Double.self, forKey: .borderWidth)
        
        // 解码文本颜色
        let textColorRed = try container.decode(Double.self, forKey: .textColorRed)
        let textColorGreen = try container.decode(Double.self, forKey: .textColorGreen)
        let textColorBlue = try container.decode(Double.self, forKey: .textColorBlue)
        let textColorOpacity = try container.decode(Double.self, forKey: .textColorOpacity)
        _textColor = CodableColor(color: Color(.sRGB, red: textColorRed, green: textColorGreen, blue: textColorBlue, opacity: textColorOpacity))
        
        // 解码背景颜色
        let backgroundColorRed = try container.decode(Double.self, forKey: .backgroundColorRed)
        let backgroundColorGreen = try container.decode(Double.self, forKey: .backgroundColorGreen)
        let backgroundColorBlue = try container.decode(Double.self, forKey: .backgroundColorBlue)
        let backgroundColorOpacity = try container.decode(Double.self, forKey: .backgroundColorOpacity)
        _backgroundColor = CodableColor(color: Color(.sRGB, red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, opacity: backgroundColorOpacity))
        
        // 解码边框颜色
        let borderColorRed = try container.decode(Double.self, forKey: .borderColorRed)
        let borderColorGreen = try container.decode(Double.self, forKey: .borderColorGreen)
        let borderColorBlue = try container.decode(Double.self, forKey: .borderColorBlue)
        let borderColorOpacity = try container.decode(Double.self, forKey: .borderColorOpacity)
        _borderColor = CodableColor(color: Color(.sRGB, red: borderColorRed, green: borderColorGreen, blue: borderColorBlue, opacity: borderColorOpacity))
        
        // 解码对齐方式
        let alignmentRaw = try container.decode(Int.self, forKey: .alignment)
        _alignment = CodableAlignment(alignment: TextAlignment.allCases[alignmentRaw])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(text, forKey: .text)
        try container.encode(texts, forKey: .texts)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(TextAlignment.allCases.firstIndex(of: alignment) ?? 0, forKey: .alignment)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(rotationInterval, forKey: .rotationInterval)
        try container.encode(currentTextIndex, forKey: .currentTextIndex)
        
        // 编码文本颜色
        var textColorComponents = UIColor(textColor).rgbaComponents
        try container.encode(textColorComponents.red, forKey: .textColorRed)
        try container.encode(textColorComponents.green, forKey: .textColorGreen)
        try container.encode(textColorComponents.blue, forKey: .textColorBlue)
        try container.encode(textColorComponents.alpha, forKey: .textColorOpacity)
        
        // 编码背景颜色
        var backgroundColorComponents = UIColor(backgroundColor).rgbaComponents
        try container.encode(backgroundColorComponents.red, forKey: .backgroundColorRed)
        try container.encode(backgroundColorComponents.green, forKey: .backgroundColorGreen)
        try container.encode(backgroundColorComponents.blue, forKey: .backgroundColorBlue)
        try container.encode(backgroundColorComponents.alpha, forKey: .backgroundColorOpacity)
        
        // 编码边框颜色
        var borderColorComponents = UIColor(borderColor).rgbaComponents
        try container.encode(borderColorComponents.red, forKey: .borderColorRed)
        try container.encode(borderColorComponents.green, forKey: .borderColorGreen)
        try container.encode(borderColorComponents.blue, forKey: .borderColorBlue)
        try container.encode(borderColorComponents.alpha, forKey: .borderColorOpacity)
    }
}

extension TextAlignment: CaseIterable {
    public static var allCases: [TextAlignment] {
        return [.leading, .center, .trailing]
    }
}

extension UIColor {
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
} 