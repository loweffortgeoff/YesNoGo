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
                Text(WidgetL10n.format("live_activity.hello_format", fallback: "Hello %@", context.state.emoji))
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text(WidgetL10n.string("live_activity.region.leading", fallback: "Leading"))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(WidgetL10n.string("live_activity.region.trailing", fallback: "Trailing"))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(WidgetL10n.format("live_activity.region.bottom_format", fallback: "Bottom %@", context.state.emoji))
                    // more content
                }
            } compactLeading: {
                Text(WidgetL10n.string("live_activity.compact.leading", fallback: "L"))
            } compactTrailing: {
                Text(WidgetL10n.format("live_activity.compact.trailing_format", fallback: "T %@", context.state.emoji))
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

#Preview(WidgetL10n.string("live_activity.preview.notification", fallback: "Notification"), as: .content, using: YesNoGoWidgetAttributes.preview) {
   YesNoGoWidgetLiveActivity()
} contentStates: {
    YesNoGoWidgetAttributes.ContentState.smiley
    YesNoGoWidgetAttributes.ContentState.starEyes
}
