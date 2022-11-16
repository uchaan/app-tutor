class Post {
  Post(
      {required this.posterUid,
      required this.posterName,
      required this.posterImg,
      required this.date,
      required this.bodytext,
      required this.image,
      required this.comments,
      required this.like,
      required this.amazed,
      required this.laugh,
      required this.sad,
      required this.angry,
      required this.reaction,
      required this.showType,
      required this.report});
  String group = '';
  late bool report;
  late String posterUid;
  late String posterName;
  late String posterImg;
  late DateTime date;
  late String bodytext;
  late String image;
  late List<dynamic> comments;
  late List<dynamic> like; //좋아요
  late List<dynamic> amazed; //놀람
  late List<dynamic> laugh; //웃김
  late List<dynamic> sad; //슬픔
  late List<dynamic> angry; //화남
  late int reaction; //내 반응. 0->반응하지 않음, 1 ->좋아요, 2-> 놀람, 3->웃김, 4->슬픔, 5->화
  late String docId; // 이거 어디다가 쓰는거임??
  late int showType; // 공개범위 0 = 전체공개 1 = 선생님에게만 2 = 학생에게만

  Post.fromjson(Map<String, dynamic> data) {
    posterUid = data['posterUid'];
    posterName = data['posterName'];
    posterImg = data['posterImg'];
    date = DateTime.fromMicrosecondsSinceEpoch(
        data['date'].microsecondsSinceEpoch);
    bodytext = data['bodytext'];
    comments = data['comments'];
    image = data['image'];
    like = data['like'];
    amazed = data['amazed'];
    laugh = data['laugh'];
    sad = data['sad'];
    angry = data['angry'];
    reaction = data['reaction'];
    showType = data['showType'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['posterUid'] = this.posterUid;
    data['posterName'] = this.posterName;
    data['posterImg'] = this.posterImg;
    data['date'] = this.date;
    data['bodytext'] = this.bodytext;
    data['comments'] = this.comments;
    data['image'] = this.image;
    data['like'] = this.like;
    data['amazed'] = this.amazed;
    data['laugh'] = this.laugh;
    data['sad'] = this.sad;
    data['angry'] = this.angry;
    data['reaction'] = this.reaction;
    data['showType'] = this.showType;
    return data;
  }
}
