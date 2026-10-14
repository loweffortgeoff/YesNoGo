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

/// One mode shortcut. The palette mirrors `ModeTheme` in the app target:
/// a muted accent that stays readable in light and dark widgets.
struct ModeButton {
    let icon: String
    let label: String
    let deepLink: String
    let accent: Color
    let accentDeep: Color
    let onAccent: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private let allModes: [String: ModeButton] = [
    "flip": ModeButton(
        icon: "centsign.circle.fill",
        label: "Flip",
        deepLink: "yesnogo://coin",
        accent: Color(rgbHex: 0xE0B053),
        accentDeep: Color(rgbHex: 0xB07E1C),
        onAccent: Color(rgbHex: 0x2A2004)
    ),
    "yesno": ModeButton(
        icon: "questionmark.circle.fill",
        label: "Yes/No",
        deepLink: "yesnogo://yesno",
        accent: Color(rgbHex: 0x4C7ED8),
        accentDeep: Color(rgbHex: 0x2F5FA8),
        onAccent: .white
    ),
    "custom": ModeButton(
        icon: "shuffle",
        label: "Custom",
        deepLink: "yesnogo://custom",
        accent: Color(rgbHex: 0x4E9E6E),
        accentDeep: Color(rgbHex: 0x2F6B49),
        onAccent: .white
    ),
    "rps": ModeButton(
        icon: "hand.raised.fill",
        label: "RPS",
        deepLink: "yesnogo://rps",
        accent: Color(rgbHex: 0xCE6A58),
        accentDeep: Color(rgbHex: 0xA84A38),
        onAccent: .white
    ),
    "orb": ModeButton(
        icon: "bubbles.and.sparkles.fill",
        label: "Orb",
        deepLink: "yesnogo://orb",
        accent: Color(rgbHex: 0x7B68C9),
        accentDeep: Color(rgbHex: 0x56449B),
        onAccent: .white
    ),
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
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(mode.onAccent)
            .background(mode.gradient)
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

            HStack(spacing: 8) {
                ForEach(topRow, id: \.label) { mode in
                    WidgetModeButton(mode: mode, iconFont: .title3, labelFont: .caption2)
                }
            }

            HStack(spacing: 8) {
                ForEach(bottomRow, id: \.label) { mode in
                    WidgetModeButton(mode: mode, iconFont: .title3, labelFont: .caption2)
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Widget

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

// MARK: - Color Helper

extension Color {
    /// Builds a color from a packed 0xRRGGBB value.
    /// Kept local to the widget target, which does not share app sources.
    init(rgbHex: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgbHex >> 16) & 0xFF) / 255,
            green: Double((rgbHex >> 8) & 0xFF) / 255,
            blue: Double(rgbHex & 0xFF) / 255,
            opacity: 1
        )
    }
}
