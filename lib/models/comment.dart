class Comment {
  Comment({
    required this.commenterUid,
    required this.commenterName,
    required this.commenterImg,
    required this.date,
    required this.bodytext,
  });

  late String commenterUid;
  late String commenterName;
  late String commenterImg;
  late DateTime date;
  late String bodytext;

  Comment.fromJson(Map<String, dynamic> data) {
    commenterUid = data['commenterUid'];
    commenterName = data['commenterName'];
    commenterImg = data['commenterImg'];
    date = DateTime.fromMicrosecondsSinceEpoch(
        data['date'].microsecondsSinceEpoch);
    bodytext = data['bodytext'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['commenterUid'] = this.commenterUid;
    data['commenterName'] = this.commenterName;
    data['commenterImg'] = this.commenterImg;
    data['date'] = this.date;
    data['bodytext'] = this.bodytext;
    return data;
  }
}
