import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

struct LiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var driverCode: String
        var carModel: String
        var minutesToArrive: Int   // when > 0, show minutes
        var carArriveProgress: Int // when minutesToArrive == 0, show seconds (0…30)
    }
}

// MARK: - Widget

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityWidgetAttributes.self) { context in
            CarArravingView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.minutesToArrive > 0 {
                        Text("เหลืออีก \(context.state.minutesToArrive) นาที")
                    } else {
                        Text("เหลืออีก \(context.state.carArriveProgress) วินาที")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // you can mirror leading or show an icon
                    if context.state.minutesToArrive > 0 {
                        Text("🕌")
                    } else {
                        Text("⏱")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.minutesToArrive > 0 {
                        ProgressBarWithCar(minutesRemaining: context.state.minutesToArrive,
                                          secondsRemaining: nil)
                            .padding(.horizontal, 42)
                    } else {
                        ProgressBarWithCar(minutesRemaining: 0,
                                          secondsRemaining: context.state.carArriveProgress)
                            .padding(.horizontal, 42)
                    }
                }
            } compactLeading: {
                if context.state.minutesToArrive > 0 {
                    Text("\(context.state.minutesToArrive)m")
                } else {
                    Text("\(context.state.carArriveProgress)s")
                }
            } compactTrailing: {
                Image(systemName: "timer")
            } minimal: {
                Text("⏱")
            }
        }
    }
}

// MARK: - Preview

extension LiveActivityWidgetAttributes {
    static var preview: LiveActivityWidgetAttributes { LiveActivityWidgetAttributes() }
}
extension LiveActivityWidgetAttributes.ContentState {
    static var model1 = LiveActivityWidgetAttributes.ContentState(
        driverCode: "Matheus", carModel: "Virtus", minutesToArrive: 5, carArriveProgress: 30)
    static var model2 = LiveActivityWidgetAttributes.ContentState(
        driverCode: "Matheus", carModel: "Virtus", minutesToArrive: 0, carArriveProgress: 15)
}

// MARK: - Views

struct CarArravingView: View {
    let context: ActivityViewContext<LiveActivityWidgetAttributes>
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    if context.state.minutesToArrive > 0 {
                        Text("เหลืออีก \(context.state.minutesToArrive) นาที")
                            .semiBold20()
                    } else {
                        Text("เหลืออีก \(context.state.carArriveProgress) วินาที")
                            .semiBold20()
                    }
                    Text("\(context.state.driverCode) — \(context.state.carModel)")
                        .regular16()
                }
                Spacer()
                Image(systemName: "truck")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
            if context.state.minutesToArrive > 0 {
                ProgressBarWithCar(minutesRemaining: context.state.minutesToArrive,
                                  secondsRemaining: nil)
            } else {
                ProgressBarWithCar(minutesRemaining: 0,
                                  secondsRemaining: context.state.carArriveProgress)
            }
        }
        .padding()
    }
}

struct ProgressBarWithCar: View {
    var minutesRemaining: Int
    var secondsRemaining: Int?
    @State private var barWidth: CGFloat = 0

    private var total: Double {
        secondsRemaining != nil ? 30.0 : 5.0
    }
    private var progressValue: Double {
        if let sec = secondsRemaining {
            return Double(sec)
        } else {
            return Double(minutesRemaining)
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ProgressView(value: progressValue, total: total)
                .progressViewStyle(.linear)
                .tint(.white)
                .background(Color.gray.opacity(0.4))
                .frame(height: 24)
                .cornerRadius(6)
                .overlay(GeometryReader { geo in
                    Color.clear.onAppear { barWidth = geo.size.width }
                })
            Image(systemName: "car.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .offset(x: (CGFloat(progressValue)/CGFloat(total)) * barWidth - 24)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Text Styles

extension Text {
    func semiBold20() -> some View {
        self.font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
    }
    func regular16() -> some View {
        self.font(.system(size: 16))
            .foregroundColor(Color.white.opacity(0.8))
    }
}