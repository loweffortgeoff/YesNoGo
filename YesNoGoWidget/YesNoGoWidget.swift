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

struct YesNoGoWidgetEntryView : View {
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

    var smallWidget: some View {
        VStack(spacing: 8) {
            Text("Yes? No? Go!")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                Link(destination: URL(string: "yesnogo://coin")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "circle.circle")
                            .font(.title2)
                        Text("Flip")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Link(destination: URL(string: "yesnogo://yesno")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                            .font(.title2)
                        Text("Yes/No")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
    }

    var mediumWidget: some View {
        VStack(spacing: 10) {
            Text("Yes? No? Go!")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                Link(destination: URL(string: "yesnogo://coin")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.circle")
                            .font(.title3)
                        Text("Coin Flip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Link(destination: URL(string: "yesnogo://yesno")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup")
                            .font(.title3)
                        Text("Yes / No")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Link(destination: URL(string: "yesnogo://custom")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                        Text("Custom")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
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
