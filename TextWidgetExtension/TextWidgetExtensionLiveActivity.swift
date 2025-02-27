//
//  TextWidgetExtensionLiveActivity.swift
//  TextWidgetExtension
//
//  Created by antaeus on 2025/2/27.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TextWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TextWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TextWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TextWidgetExtensionAttributes {
    fileprivate static var preview: TextWidgetExtensionAttributes {
        TextWidgetExtensionAttributes(name: "World")
    }
}

extension TextWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: TextWidgetExtensionAttributes.ContentState {
        TextWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TextWidgetExtensionAttributes.ContentState {
         TextWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TextWidgetExtensionAttributes.preview) {
   TextWidgetExtensionLiveActivity()
} contentStates: {
    TextWidgetExtensionAttributes.ContentState.smiley
    TextWidgetExtensionAttributes.ContentState.starEyes
}
