//
//  TextWidgetExtensionBundle.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import WidgetKit
import SwiftUI

struct TextWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TextWidgetExtension()
        TextWidgetExtensionControl()
        TextWidgetExtensionLiveActivity()
    }
}
