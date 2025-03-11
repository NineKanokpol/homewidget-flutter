class PrayTimeModel {
  String? time1;
  String? time2;
  String? time3;
  String? time4;
  String? time5;
  String? time6;
  String? time7;
  String? dateString;

  PrayTimeModel(
      {this.time1,
        this.time2,
        this.time3,
        this.time4,
        this.time5,
        this.time6,
        this.time7,
        this.dateString});

  PrayTimeModel.fromJson(Map<String, dynamic> json) {
    time1 = json['time1'];
    time2 = json['time2'];
    time3 = json['time3'];
    time4 = json['time4'];
    time5 = json['time5'];
    time6 = json['time6'];
    time7 = json['time7'];
    dateString = json['date_string'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time1'] = this.time1;
    data['time2'] = this.time2;
    data['time3'] = this.time3;
    data['time4'] = this.time4;
    data['time5'] = this.time5;
    data['time6'] = this.time6;
    data['time7'] = this.time7;
    data['date_string'] = this.dateString;
    return data;
  }
}