//
//  TextWidgetExtension.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
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
        let entry = TextEntry(date: Date(), model: model)
        let timeline = Timeline(entries: [entry], policy: .never)
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
