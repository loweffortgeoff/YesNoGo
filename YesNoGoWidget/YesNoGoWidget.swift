//
//  YesNoGoWidget.swift
//  YesNoGoWidget
//
//  Created by Geoffrey Silva on 12/20/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Mode Button Model

struct ModeButton {
    let icon: String
    let label: String
    let deepLink: String
    let colors: [Color]
}

private let allModes: [String: ModeButton] = [
    "flip": ModeButton(icon: "circle.circle", label: "Flip", deepLink: "yesnogo://coin",
                        colors: [Color(red: 1.0, green: 0.75, blue: 0.0), .orange]),
    "yesno": ModeButton(icon: "hand.thumbsup.fill", label: "Yes/No", deepLink: "yesnogo://yesno",
                         colors: [Color(red: 0.2, green: 0.6, blue: 1.0), .cyan]),
    "custom": ModeButton(icon: "list.bullet", label: "Custom", deepLink: "yesnogo://custom",
                          colors: [Color(red: 0.15, green: 0.8, blue: 0.55), .mint]),
    "rps": ModeButton(icon: "hand.raised.fill", label: "RPS", deepLink: "yesnogo://rps",
                       colors: [Color(red: 0.9, green: 0.2, blue: 0.5), .pink]),
    "orb": ModeButton(icon: "circle.hexagongrid.fill", label: "Orb", deepLink: "yesnogo://orb",
                       colors: [.indigo, Color(red: 0.6, green: 0.3, blue: 1.0)]),
]

// MARK: - Shared Button View

struct WidgetModeButton: View {
    let mode: ModeButton
    let iconFont: Font
    let labelFont: Font

    var body: some View {
        Link(destination: URL(string: mode.deepLink)!) {
            VStack(spacing: 3) {
                Image(systemName: mode.icon)
                    .font(iconFont)
                    .fontWeight(.semibold)
                Text(mode.label)
                    .font(labelFont)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: mode.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Widget Entry View

struct YesNoGoWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: Small Widget — 2×2 grid of 4 modes

    private var smallWidget: some View {
        let modes = ["flip", "yesno", "orb", "rps"].compactMap { allModes[$0] }

        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                WidgetModeButton(mode: modes[0], iconFont: .body, labelFont: .system(size: 10))
                WidgetModeButton(mode: modes[1], iconFont: .body, labelFont: .system(size: 10))
            }
            HStack(spacing: 6) {
                WidgetModeButton(mode: modes[2], iconFont: .body, labelFont: .system(size: 10))
                WidgetModeButton(mode: modes[3], iconFont: .body, labelFont: .system(size: 10))
            }
        }
        .padding(10)
    }

    // MARK: Medium Widget — 5 modes in two rows

    private var mediumWidget: some View {
        let topRow = ["flip", "yesno", "custom"].compactMap { allModes[$0] }
        let bottomRow = ["rps", "orb"].compactMap { allModes[$0] }

        return VStack(spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("Quick decisions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Top row: 3 buttons
            HStack(spacing: 8) {
                ForEach(topRow, id: \.label) { mode in
                    WidgetModeButton(mode: mode, iconFont: .title3, labelFont: .caption2)
                }
            }

            // Bottom row: 2 buttons
            HStack(spacing: 8) {
                ForEach(bottomRow, id: \.label) { mode in
                    WidgetModeButton(mode: mode, iconFont: .title3, labelFont: .caption2)
                }
            }
        }
        .padding(14)
    }
}

struct YesNoGoWidget: Widget {
    let kind: String = "YesNoGoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YesNoGoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Yes? No? Go!")
        .description("Quick access to make decisions")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    YesNoGoWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
    YesNoGoWidget()
} timeline: {
    SimpleEntry(date: .now)
}
