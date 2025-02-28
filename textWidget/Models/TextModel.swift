import SwiftUI

// 创建一个可编码的颜色类型
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(color: Color) {
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
    
    var color: Color {
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

struct TextModel: Codable, Equatable {
    var text: String
    var fontSize: CGFloat
    private var _textColor: CodableColor
    private var _backgroundColor: CodableColor
    private var _alignment: CodableAlignment
    var hasShadow: Bool
    var shadowRadius: CGFloat
    var borderWidth: CGFloat
    private var _borderColor: CodableColor
    
    var textColor: Color {
        get { _textColor.color }
        set { _textColor = CodableColor(color: newValue) }
    }
    
    var backgroundColor: Color {
        get { _backgroundColor.color }
        set { _backgroundColor = CodableColor(color: newValue) }
    }
    
    var borderColor: Color {
        get { _borderColor.color }
        set { _borderColor = CodableColor(color: newValue) }
    }
    
    var alignment: TextAlignment {
        get { _alignment.alignment }
        set { _alignment = CodableAlignment(alignment: newValue) }
    }
    
    init() {
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
    init(
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
    static func == (lhs: TextModel, rhs: TextModel) -> Bool {
        return lhs.text == rhs.text &&
            lhs.fontSize == rhs.fontSize &&
            lhs._textColor == rhs._textColor &&
            lhs._backgroundColor == rhs._backgroundColor &&
            lhs._alignment == rhs._alignment &&
            lhs.hasShadow == rhs.hasShadow &&
            lhs.shadowRadius == rhs.shadowRadius &&
            lhs.borderWidth == rhs.borderWidth &&
            lhs._borderColor == rhs._borderColor
    }
    
    // 实现Codable
    enum CodingKeys: String, CodingKey {
        case text, fontSize, textColor, backgroundColor
        case alignment = "_alignment", hasShadow, shadowRadius
        case borderWidth, borderColor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        _textColor = try container.decode(CodableColor.self, forKey: .textColor)
        _backgroundColor = try container.decode(CodableColor.self, forKey: .backgroundColor)
        _alignment = try container.decode(CodableAlignment.self, forKey: .alignment)
        hasShadow = try container.decode(Bool.self, forKey: .hasShadow)
        shadowRadius = try container.decode(CGFloat.self, forKey: .shadowRadius)
        borderWidth = try container.decode(CGFloat.self, forKey: .borderWidth)
        _borderColor = try container.decode(CodableColor.self, forKey: .borderColor)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(_textColor, forKey: .textColor)
        try container.encode(_backgroundColor, forKey: .backgroundColor)
        try container.encode(_alignment, forKey: .alignment)
        try container.encode(hasShadow, forKey: .hasShadow)
        try container.encode(shadowRadius, forKey: .shadowRadius)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(_borderColor, forKey: .borderColor)
    }
} 