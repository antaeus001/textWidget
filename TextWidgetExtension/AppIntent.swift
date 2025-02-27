//
//  AppIntent.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "配置小组件"
    static var description = IntentDescription("配置文本小组件的显示方式")

    @Parameter(title: "刷新间隔", default: 60)
    var refreshInterval: Int
}
