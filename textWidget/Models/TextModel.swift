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
    public var text: String
    public var texts: [String] = []  // 存储轮播文本
    public var fontSize: CGFloat
    public var rotationInterval: TimeInterval = 3.0  // 添加轮播间隔时间，默认3秒
    private var _textColor: CodableColor
    private var _backgroundColor: CodableColor
    private var _alignment: CodableAlignment
    public var hasShadow: Bool
    public var shadowRadius: CGFloat
    public var borderWidth: CGFloat
    private var _borderColor: CodableColor
    
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
    
    public init() {
        self.text = "点击编辑文本"
        self.fontSize = 16
        self._textColor = CodableColor(color: .black)
        self._backgroundColor = CodableColor(color: .white)
        self._alignment = .center
        self.hasShadow = false
        self.shadowRadius = 0
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
        hasShadow: Bool,
        shadowRadius: CGFloat,
        borderWidth: CGFloat,
        borderColor: Color
    ) {
        self.text = text
        self.fontSize = fontSize
        self._textColor = CodableColor(color: textColor)
        self._backgroundColor = CodableColor(color: backgroundColor)
        self._alignment = CodableAlignment(alignment: alignment)
        self.hasShadow = hasShadow
        self.shadowRadius = shadowRadius
        self.borderWidth = borderWidth
        self._borderColor = CodableColor(color: borderColor)
    }
    
    // 实现Equatable协议
    public static func == (lhs: TextModel, rhs: TextModel) -> Bool {
        return lhs.text == rhs.text &&
            lhs.texts == rhs.texts &&
            lhs.fontSize == rhs.fontSize &&
            lhs.rotationInterval == rhs.rotationInterval &&
            lhs._textColor == rhs._textColor &&
            lhs._backgroundColor == rhs._backgroundColor &&
            lhs._alignment == rhs._alignment &&
            lhs.hasShadow == rhs.hasShadow &&
            lhs.shadowRadius == rhs.shadowRadius &&
            lhs.borderWidth == rhs.borderWidth &&
            lhs._borderColor == rhs._borderColor
    }
    
    // 实现Codable
    public enum CodingKeys: String, CodingKey {
        case text, texts, fontSize, rotationInterval, textColor, backgroundColor
        case alignment = "_alignment", hasShadow, shadowRadius
        case borderWidth, borderColor
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        texts = try container.decode([String].self, forKey: .texts)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        rotationInterval = try container.decode(TimeInterval.self, forKey: .rotationInterval)
        _textColor = try container.decode(CodableColor.self, forKey: .textColor)
        _backgroundColor = try container.decode(CodableColor.self, forKey: .backgroundColor)
        _alignment = try container.decode(CodableAlignment.self, forKey: .alignment)
        hasShadow = try container.decode(Bool.self, forKey: .hasShadow)
        shadowRadius = try container.decode(CGFloat.self, forKey: .shadowRadius)
        borderWidth = try container.decode(CGFloat.self, forKey: .borderWidth)
        _borderColor = try container.decode(CodableColor.self, forKey: .borderColor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(texts, forKey: .texts)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(rotationInterval, forKey: .rotationInterval)
        try container.encode(_textColor, forKey: .textColor)
        try container.encode(_backgroundColor, forKey: .backgroundColor)
        try container.encode(_alignment, forKey: .alignment)
        try container.encode(hasShadow, forKey: .hasShadow)
        try container.encode(shadowRadius, forKey: .shadowRadius)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(_borderColor, forKey: .borderColor)
    }
} 