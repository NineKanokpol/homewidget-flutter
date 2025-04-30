//
//  LiveActivityWidget.swift
//  LiveActivityWidget
//
//  Created by Kanokpol Tipkan on 14/4/2568 BE.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.tnd.homewidget"

struct PrayerTime: Codable, Hashable {
    let name: String
    let time: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let text: String
    let additionalText: String
    let prayerTimes: [PrayerTime]
}

struct Provider: TimelineProvider {

private func getDataFromFlutter() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.tnd.homewidget")
        let textFromFlutterApp = userDefaults?.string(forKey: "text1") ?? "0"
        let additionalTextFromFlutterApp = userDefaults?.string(forKey: "text2") ?? "default"
        return SimpleEntry(
            date: Date(),
            text: textFromFlutterApp,
            additionalText: additionalTextFromFlutterApp,
            prayerTimes: getPrayerTimesFromFlutter()
        )
    }

    // Decode prayer times from a JSON string stored in UserDefaults.
    private func getPrayerTimesFromFlutter() -> [PrayerTime] {
        let userDefaults = UserDefaults(suiteName: "group.com.tnd.homewidget")
        if let jsonString = userDefaults?.string(forKey: "prayerTimes"),
           let jsonData = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PrayerTime].self, from: jsonData) {
            return decoded
        }
        // Fallback default data.
        return [
            PrayerTime(name: "ศุบฮิ", time: ""),
            PrayerTime(name: "ชุรูก", time: ""),
            PrayerTime(name: "ซุฮฺริ", time: ""),
            PrayerTime(name: "อัศริ", time: ""),
            PrayerTime(name: "มัฆริบ", time: ""),
            PrayerTime(name: "อิชาอฺ", time: "")
        ]
    }

    func placeholder(in context: Context) -> SimpleEntry {
                SimpleEntry(
                    date: Date(),
                    text: "0",
                    additionalText: "placeholder",
                    prayerTimes: getPrayerTimesFromFlutter()
                )
            }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
                let entry = getDataFromFlutter()
                completion(entry)
            }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
                let entry = getDataFromFlutter()
                // For testing, you could force a refresh in a few minutes:
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct LiveActivityWidgetEntryView : View {
     var entry: SimpleEntry

     private let iconMap: [String: String] = [
             "ศุบฮิ":  "sunny_up",
             "ชุรูก":  "sunny_up2",
             "ซุฮฺริ": "sunny_full",
             "อัศริ":  "sunny_clound",
             "มัฆริบ":"sunny_down",
             "อิชาอฺ":"moon"
         ]

        var body: some View {
            ZStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Top row: date/title on the left, timer on the right
                    HStack(alignment: .center, spacing: 12) {
                                        HStack(spacing: 8) {
                                                            Image("logo")
                                                                .renderingMode(.original)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 20, height: 20)
                                                                .foregroundColor(.white)

                                                            Text(entry.text)
                                                                .foregroundColor(.white)
                                                                .font(.headline)
                                                                .lineLimit(1)
                                                                .minimumScaleFactor(0.75)
                                                        }

                                        Spacer()

                                        HStack(spacing: 8) {
                                                Text(entry.additionalText)
                                                  .foregroundColor(.white)
                                                  .font(.subheadline)
                                                  .lineLimit(1)
                                                  .minimumScaleFactor(0.75)

                                                   Button {
                                                                                                       WidgetCenter.shared.reloadAllTimelines()
                                                                                                   } label: {
                                                                                                       Image("refresh")
                                                                                                         .renderingMode(.original)
                                                                                                         .resizable()
                                                                                                         .scaledToFit()
                                                                                                         .frame(width: 24, height: 24)
                                                                                                   }
                                                                                                   .buttonStyle(.plain)

                                              }
                                    }.frame(maxWidth: .infinity)

                    // Divider
                    Divider()
                      .frame(height: 2)
                      .background(
                        Color(
                          red:   Double(0x74) / 255.0,
                          green: Double(0x88) / 255.0,
                          blue:  Double(0x25) / 255.0
                        )
                      )

                    // Prayer times row
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(entry.prayerTimes, id: \.name) { prayer in
                            VStack(spacing: 4) {
                                // Circle icon
                                let iconName = iconMap[prayer.name] ?? "defaultIcon"
                                    Image(iconName)
                                      .resizable()
                                      .scaledToFit()
                                      .frame(width: 24, height: 24)
                                      .foregroundColor(.white)

                                // Prayer name
                                Text(prayer.name)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                // Prayer time
                                Text(prayer.time)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }.frame(maxWidth: .infinity)
                        }
                    }.frame(maxWidth: .infinity)
                }
                // Slight padding around content to match the screenshot spacing
                .padding(8)
            }
        }
}

struct LiveActivityWidget: Widget {
    let kind: String = "LiveActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LiveActivityWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(
                          red:   0x18 / 255.0,
                          green: 0x2E / 255.0,
                          blue:  0x37 / 255.0
                        )
                    }
            } else {
                LiveActivityWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#if DEBUG
struct MyHomeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LiveActivityWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                text: "Sample Text",
                additionalText: "Additional Sample",
                prayerTimes: [
                    PrayerTime(name: "Fajr", time: "05:05"),
                    PrayerTime(name: "Sunrise", time: "06:12"),
                    PrayerTime(name: "Dhuhr", time: "12:26"),
                    PrayerTime(name: "Asr", time: "15:37"),
                    PrayerTime(name: "Maghrib", time: "18:30"),
                    PrayerTime(name: "Isha", time: "00:21")
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            LiveActivityWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                text: "Sample Text",
                additionalText: "Additional Sample",
                prayerTimes: [
                    PrayerTime(name: "Fajr", time: "05:05"),
                    PrayerTime(name: "Sunrise", time: "06:12"),
                    PrayerTime(name: "Dhuhr", time: "12:26"),
                    PrayerTime(name: "Asr", time: "15:37"),
                    PrayerTime(name: "Maghrib", time: "18:30"),
                    PrayerTime(name: "Isha", time: "00:21")
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            LiveActivityWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                text: "Sample Text",
                additionalText: "Additional Sample",
                prayerTimes: [
                    PrayerTime(name: "Fajr", time: "05:05"),
                    PrayerTime(name: "Sunrise", time: "06:12"),
                    PrayerTime(name: "Dhuhr", time: "12:26"),
                    PrayerTime(name: "Asr", time: "15:37"),
                    PrayerTime(name: "Maghrib", time: "18:30"),
                    PrayerTime(name: "Isha", time: "00:21")
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
#endif

