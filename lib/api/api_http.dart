import 'dart:convert';

import 'package:homewidget/api/res/prayer_time_response.dart';
import 'package:http/http.dart' as Http;

class ApiHttp{
  Future<PrayerTimesResponse> fetchPrayerTimes(double latitude, double longitude, int timezone) async {
    // สร้าง URL พร้อมแนบพารามิเตอร์
    final Uri url = Uri.parse("https://whiteplus.whitechannel.tv/solahtimes/api/")
        .replace(queryParameters: {
      "json": "",
      "lati": latitude.toString(),
      "longti": longitude.toString(),
      "time-z": timezone.toString(),
    });

    try {
      // ทำการส่ง GET Request
      final response = await Http.get(url);

      // ตรวจสอบว่า Response สำเร็จหรือไม่
      if (response.statusCode == 200) {
        // แปลงข้อมูล JSON
        final data = json.decode(response.body);
        final prayerTimes = PrayerTimesResponse.fromJson(data);
        return prayerTimes;
      } else {
        print("Failed to fetch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }

    return PrayerTimesResponse(
      time1: "--:--",
      time2: "--:--",
      time3: "--:--",
      time4: "--:--",
      time5: "--:--",
      time6: "--:--",
      time7: "--:--",
      dateString: "N/A",
    );
  }
}