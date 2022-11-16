
class Review {
  Review({
    required this.uid,
    required this.name,
    required this.date,
    required this.done,
  });

  String uid;
  String name;
  DateTime date;
  int done;

  String img = '';
  Map<String, dynamic> profileInfo = {};

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'date': date,
      'done': done,
      'img': img,
      'profileInfo': profileInfo,
    };
  }
}