// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import workmanager
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {

  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(.alert)
  }

  /// Schedule daily background refresh for iOS 13+
  @available(iOS 13.0, *)
  func scheduleDailyRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "updatePrayerTimes")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 ชั่วโมงจากนี้
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule daily refresh: \(error)")
    }
  }

  override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ตั้ง delegate สำหรับ foreground notification
    UNUserNotificationCenter.current().delegate = self

    // ลงทะเบียนให้ Workmanager จับ callback
    WorkmanagerPlugin.registerTask(withIdentifier: "updatePrayerTimes")

    #if !targetEnvironment(simulator)
    if #available(iOS 13.0, *) {
      // ผูก handler กับ BGAppRefreshTask
      BGTaskScheduler.shared.register(forTaskWithIdentifier: "updatePrayerTimes",
                                      using: nil) { task in
        // reschedule สำหรับวันถัดไป
        self.scheduleDailyRefresh()
        // แจ้งระบบว่าทำงานเสร็จเรียบร้อย
        task.setTaskCompleted(success: true)
      }
      // schedule ครั้งแรก
      scheduleDailyRefresh()
    }
    #else
    print("Simulator detected: skipping BGTaskScheduler registration")
    #endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}