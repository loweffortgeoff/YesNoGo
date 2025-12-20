//
//  YesNoGoWidgetLiveActivity.swift
//  YesNoGoWidget
//
//  Created by Geoffrey Silva on 12/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YesNoGoWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YesNoGoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YesNoGoWidgetAttributes.self) { context in
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

extension YesNoGoWidgetAttributes {
    fileprivate static var preview: YesNoGoWidgetAttributes {
        YesNoGoWidgetAttributes(name: "World")
    }
}

extension YesNoGoWidgetAttributes.ContentState {
    fileprivate static var smiley: YesNoGoWidgetAttributes.ContentState {
        YesNoGoWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YesNoGoWidgetAttributes.ContentState {
         YesNoGoWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YesNoGoWidgetAttributes.preview) {
   YesNoGoWidgetLiveActivity()
} contentStates: {
    YesNoGoWidgetAttributes.ContentState.smiley
    YesNoGoWidgetAttributes.ContentState.starEyes
}
