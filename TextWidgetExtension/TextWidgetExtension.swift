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
    typealias Entry = TextEntry
    let userDefaults = UserDefaults(suiteName: Constants.appGroupId)
    
    func placeholder(in context: Context) -> TextEntry {
        TextEntry(date: Date(), model: TextModel())
    }

    func getSnapshot(in context: Context, completion: @escaping (TextEntry) -> ()) {
        let model = loadSavedModel()
        let entry = TextEntry(date: Date(), model: model)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TextEntry>) -> ()) {
        let model = loadSavedModel()
        
        // 如果没有轮播文本，返回单个条目
        if model.texts.isEmpty {
            let entry = TextEntry(date: Date(), model: model)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        
        // 创建轮播条目
        var entries: [TextEntry] = []
        let currentDate = Date()
        let endDate = currentDate.addingTimeInterval(5 * 60) // 5分钟的时间线
        var entryDate = currentDate
        var index = 0
        
        while entryDate < endDate {
            var newModel = model
            newModel.text = model.texts[index]
            let entry = TextEntry(date: entryDate, model: newModel)
            entries.append(entry)
            
            // 使用设置的轮播间隔
            entryDate = entryDate.addingTimeInterval(model.rotationInterval)
            index = (index + 1) % model.texts.count
        }
        
        let timeline = Timeline(entries: entries, policy: .after(endDate))
        completion(timeline)
    }
    
    private func loadSavedModel() -> TextModel {
        guard let data = userDefaults?.data(forKey: Constants.widgetUserDefaultsKey),
              let model = try? JSONDecoder().decode(TextModel.self, from: data)
        else {
            return TextModel()
        }
        return model
    }
}

struct TextEntry: TimelineEntry {
    let date: Date
    let model: TextModel
}

struct TextWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text(entry.model.text)
                .font(.system(size: entry.model.fontSize))
                .foregroundColor(entry.model.textColor)
                .multilineTextAlignment(entry.model.alignment)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(radius: entry.model.hasShadow ? entry.model.shadowRadius : 0)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(entry.model.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: entry.model.borderWidth > 0 ? 8 : 0)
                .stroke(entry.model.borderColor, lineWidth: entry.model.borderWidth)
        )
        .containerBackground(for: .widget) {
            entry.model.backgroundColor
        }
        .animation(.easeInOut, value: entry.model.text)
    }
}

struct TextWidgetExtension: Widget {
    let kind: String = "TextWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("文本小组件")
        .description("显示自定义文本的小组件")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct TextWidgetBundle: WidgetBundle {
    var body: some Widget {
        TextWidgetExtension()
    }
}
