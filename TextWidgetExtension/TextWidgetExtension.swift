//
//  TextWidgetExtension.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import WidgetKit
import SwiftUI
import textWidget

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
        let currentConfig = ConfigManager.shared.currentConfig
        let baseModel = loadSavedModel()
        let currentDate = Date()
        
        // 如果没有配置或没有轮播内容，使用普通模式
        guard let config = currentConfig, !config.contents.isEmpty else {
            let entry = TextEntry(date: currentDate, model: baseModel)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        
        // 如果只有一条内容，不需要轮播
        guard config.contents.count > 1 else {
            var model = baseModel
            model.text = config.contents[0].text
            let entry = TextEntry(date: currentDate, model: model)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        
        // 创建多个轮播条目
        var entries: [TextEntry] = []
        
        // 创建接下来5分钟的轮播条目
        let endDate = currentDate.addingTimeInterval(5 * 60) // 5分钟
        var entryDate = currentDate
        var index = getCurrentIndex()
        
        while entryDate < endDate {
            var model = baseModel
            model.text = config.contents[index].text
            let entry = TextEntry(date: entryDate, model: model)
            entries.append(entry)
            
            // 更新下一个条目的时间和索引
            entryDate = entryDate.addingTimeInterval(config.rotationInterval)
            index = (index + 1) % config.contents.count
        }
        
        // 保存最后的索引
        saveCurrentIndex(index)
        
        // 创建时间线，5分钟后重新加载
        let timeline = Timeline(entries: entries, policy: .after(endDate))
        completion(timeline)
    }
    
    private func getCurrentIndex() -> Int {
        return userDefaults?.integer(forKey: "currentRotationIndex") ?? 0
    }
    
    private func saveCurrentIndex(_ index: Int) {
        userDefaults?.set(index, forKey: "currentRotationIndex")
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

struct TextWidgetEntryView : View {
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
