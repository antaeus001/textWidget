//
//  TextWidgetExtension.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import WidgetKit
import SwiftUI
//import textWidget

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), model: getDefaultModel())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), model: getModel())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let model = getModel()
        
        // 创建时间线条目
        var entries: [SimpleEntry] = []
        
        // 如果有轮播文本，则为每个文本创建一个条目
        if !model.texts.isEmpty {
            let rotationInterval = model.rotationInterval
            
            // 为每个轮播文本创建一个条目
            for i in 0..<(model.texts.count + 1) {
                let entryDate = currentDate.addingTimeInterval(Double(i) * rotationInterval)
                var entryModel = model
                entryModel.currentTextIndex = i % (model.texts.count + 1)
                let entry = SimpleEntry(date: entryDate, model: entryModel)
                entries.append(entry)
            }
        } else {
            // 如果没有轮播文本，只创建一个条目
            let entry = SimpleEntry(date: currentDate, model: model)
            entries.append(entry)
        }
        
        // 创建时间线
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    // 获取模型数据
    private func getModel() -> TextModel {
        let userDefaults = UserDefaults(suiteName: Constants.appGroupId)
        
        if let data = userDefaults?.data(forKey: Constants.configKey),
           let model = try? JSONDecoder().decode(TextModel.self, from: data) {
            return model
        }
        
        return getDefaultModel()
    }
    
    // 获取默认模型
    private func getDefaultModel() -> TextModel {
        // 使用与应用相同的默认样式
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
        model.textColor = Color(red: 0.31, green: 0.54, blue: 0.38)
        model.backgroundColor = Color(red: 0.95, green: 0.98, blue: 0.96)
        model.alignment = .center
        model.borderWidth = 2
        model.borderColor = Color(red: 0.31, green: 0.54, blue: 0.38).opacity(0.5)
        model.rotationInterval = 3.0
        
        return model
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let model: TextModel
}

struct TextWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let model = entry.model
        let displayText: String
        
        // 确定显示的文本
        if model.currentTextIndex == 0 || model.texts.isEmpty {
            displayText = model.text
        } else {
            let index = model.currentTextIndex - 1
            displayText = index < model.texts.count ? model.texts[index] : model.text
        }
        
        // 文本内容
        let content = Text(displayText)
            .font(.system(size: CGFloat(model.fontSize)))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing))
        
        // 使用 containerBackground 提供背景和边框
        return content.containerBackground(for: .widget) {
            ZStack {
                // 背景
                model.backgroundColor
                
                // 边框
                if model.borderWidth > 0 {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(model.borderColor, lineWidth: CGFloat(model.borderWidth))
                            .frame(
                                width: geo.size.width - CGFloat(model.borderWidth),
                                height: geo.size.height - CGFloat(model.borderWidth)
                            )
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
            }
        }
    }
}

struct TextWidget: Widget {
    let kind: String = "TextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("文本小组件")
        .description("显示自定义文本的小组件")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TextWidget_Previews: PreviewProvider {
    static var previews: some View {
        let model = TextModel()
        TextWidgetEntryView(entry: SimpleEntry(date: Date(), model: model))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
