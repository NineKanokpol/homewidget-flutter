import WidgetKit
import SwiftUI

// MARK: - Data Models

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

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    // Retrieve data from Flutter via shared UserDefaults.
    private func getDataFromFlutter() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.tnd.homewidget")
        let textFromFlutterApp = userDefaults?.string(forKey: "text1") ?? "0"
        let additionalTextFromFlutterApp = userDefaults?.string(forKey: "text2") ?? "default"
        let prayerTimes = getPrayerTimesFromFlutter()
        return SimpleEntry(date: Date(), text: textFromFlutterApp, additionalText: additionalTextFromFlutterApp, prayerTimes: prayerTimes)
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
            PrayerTime(name: "Fajr", time: "05:05"),
            PrayerTime(name: "Sunrise", time: "06:12"),
            PrayerTime(name: "Dhuhr", time: "12:26"),
            PrayerTime(name: "Asr", time: "15:37"),
            PrayerTime(name: "Maghrib", time: "18:30"),
            PrayerTime(name: "Isha", time: "00:21")
        ]
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), text: "0", additionalText: "placeholder", prayerTimes: getPrayerTimesFromFlutter())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getDataFromFlutter()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getDataFromFlutter()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View

struct MyHomeWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: date/title on the left, timer on the right
                HStack {
                    Text("5 เชาวาล 1446")
                        .foregroundColor(.white)
                        .font(.headline)
                        // Ensure it doesn't wrap
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Text("Timer: 59 sec")
                        .foregroundColor(.green)
                        .font(.headline)
                        // Ensure it doesn't wrap
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                // Divider
                Divider()
                    .background(Color.white)

                // Prayer times row
                HStack(alignment: .center, spacing: 16) {
                    ForEach(entry.prayerTimes, id: \.name) { prayer in
                        VStack(spacing: 4) {
                            // Circle icon
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 24, height: 24)

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
                        }
                    }
                }
            }
            // Slight padding around content to match the screenshot spacing
            .padding(8)
        }
    }
}


// MARK: - Widget Configuration

struct MyHomeWidget: Widget {
    let kind: String = "MyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MyHomeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MyHomeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

// MARK: - Widget Preview

#if DEBUG
struct MyHomeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyHomeWidgetEntryView(entry: SimpleEntry(
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

            MyHomeWidgetEntryView(entry: SimpleEntry(
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

            MyHomeWidgetEntryView(entry: SimpleEntry(
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
