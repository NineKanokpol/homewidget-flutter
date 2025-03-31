class PrayerTimesResponse {
  final String time1;
  final String time2;
  final String time3;
  final String time4;
  final String time5;
  final String time6;
  final String time7;
  final String dateString;

  // Constructor
  PrayerTimesResponse({
    required this.time1,
    required this.time2,
    required this.time3,
    required this.time4,
    required this.time5,
    required this.time6,
    required this.time7,
    required this.dateString,
  });

  // Factory method: Convert JSON to Object
  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    return PrayerTimesResponse(
      time1: json["time1"] ?? "",
      time2: json["time2"] ?? "",
      time3: json["time3"] ?? "",
      time4: json["time4"] ?? "",
      time5: json["time5"] ?? "",
      time6: json["time6"] ?? "",
      time7: json["time7"] ?? "",
      dateString: json["date_string"] ?? "",
    );
  }

  // Convert Object back to JSON
  Map<String, dynamic> toJson() {
    return {
      "time1": time1,
      "time2": time2,
      "time3": time3,
      "time4": time4,
      "time5": time5,
      "time6": time6,
      "time7": time7,
      "date_string": dateString,
    };
  }
}