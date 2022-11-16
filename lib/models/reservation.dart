// ignore_for_file: non_constant_identifier_names

class ReservationItem {
  ReservationItem({
    required this.time,
    required this.date,
    required this.childUid,
    required this.formattedTime,
  });

  String time;
  String date; // 2022-02-04
  String childUid;
  DateTime formattedTime;
  Map FCMToken = {};
  String name = '';
  String img = '';
  Map<String, dynamic> profileInfo = {};

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'date': date,
      'uid': childUid,
      'name': name,
      'FCMToken': FCMToken,
      'img': img,
      'profileInfo': profileInfo,
    };
  }
}
