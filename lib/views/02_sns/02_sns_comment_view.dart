import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/models/comment.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/resources/sns_firebase_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';

class SNSCommentView extends StatefulWidget {
  final String postId;
  final List<dynamic> comments;
  SNSCommentView({Key? key, required this.postId, required this.comments})
      : super(key: key);
  @override
  _SNSCommentViewState createState() => _SNSCommentViewState();
}

class _SNSCommentViewState extends State<SNSCommentView> {
  CollectionReference posts = FirebaseFirestore.instance.collection('posts');
  TextEditingController _controller = TextEditingController();
  String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    print('build called');
    print('comments length: ${widget.comments.length}');
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: HexColor('F7F7F7'),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '댓글',
                        style: TextStyle(color: Colors.black, fontSize: 25),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.arrow_back,
                        color: HexColor('F7F7F7'),
                      ),
                    ),
                  ],
                ),
              ),
              // 코멘트 별로 하나하나 보여주는 부분
              for (int i = 0; i < widget.comments.length; i++)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(15, 10, 10, 10),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                    widget.comments[i]['commenterImg']),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.comments[i]['commenterName'],
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 17),
                                    ),
                                    Text(
                                      '   ${widget.comments[i]['bodytext']}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateTime.fromMicrosecondsSinceEpoch(widget
                                              .comments[i]['date']
                                              .microsecondsSinceEpoch)
                                          .month
                                          .toString() +
                                      "월 " +
                                      DateTime.fromMicrosecondsSinceEpoch(widget
                                              .comments[i]['date']
                                              .microsecondsSinceEpoch)
                                          .day
                                          .toString() +
                                      '일',

                                  // widget.comments[i]['date'].month.toString() +
                                  //     "월 " +
                                  //     widget.comments[i]['date'].day.toString() +
                                  //     '일',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _uid == widget.comments[i]['commenterUid']
                            ? Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: GestureDetector(
                                  child: Icon(Icons.delete_outlined),
                                  onTap: () => showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: const Text('댓글 삭제'),
                                            content:
                                                const Text('댓글을 삭제하시겠습니까?'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('예'),
                                                onPressed: () {
                                                  print('comment deleted');
                                                  print(
                                                      'comments length: ${widget.comments.length}');

                                                  //파이어베이스 업데이트 - 코멘트 삭제
                                                  SNSFirebaseApi.deleteComment(
                                                      widget.postId,
                                                      Comment(
                                                          commenterUid: widget
                                                                  .comments[i]
                                                              ['commenterUid'],
                                                          commenterName: widget
                                                                  .comments[i]
                                                              ['commenterName'],
                                                          commenterImg: widget
                                                                  .comments[i]
                                                              ['commenterImg'],
                                                          date: DateTime.fromMicrosecondsSinceEpoch(
                                                              widget
                                                                  .comments[i]
                                                                      ['date']
                                                                  .microsecondsSinceEpoch),
                                                          bodytext: widget
                                                                  .comments[i]
                                                              ['bodytext']));

                                                  //UI 업데이트 - 코멘트 삭제
                                                  widget.comments.removeWhere(
                                                      (item) =>
                                                          item['commenterUid'] ==
                                                              widget.comments[i]
                                                                  [
                                                                  'commenterUid'] &&
                                                          item['date'] ==
                                                              widget.comments[i]
                                                                  ['date']);

                                                  Navigator.pop(context);
                                                  setState(() {});
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('아니요'),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              )
                                            ],
                                          )),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Divider())
                  ],
                ),
              // 밑에 가려져서 안보이는걸 막기위한 패딩용도
              Container(
                height: 50,
                color: HexColor('F7F7F7'),
              ),
            ],
          ),
        ),
        // 약간 이게 가려서 뒤에가 안보인다는 문제가 있는데 나중에 디버깅해주기 -> gesture detector 달아줘서 다른데 누르면 내려가도록 만들어줘야겠음
        bottomSheet: Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 0, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                    Provider.of<CurrentUser>(context, listen: true).img),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 110,
                  height: 50,
                  child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '댓글 입력하기',
                        // labelText: '댓글 입력하기',
                      )),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Firebase 업데이트 - 코멘트 추가

                  CurrentUser _userInfo =
                      Provider.of<CurrentUser>(context, listen: false);
                  SNSFirebaseApi.uploadComment(
                      widget.postId,
                      Comment(
                          commenterUid: _userInfo.uid,
                          commenterName: _userInfo.name,
                          commenterImg: _userInfo.img,
                          date: DateTime.now(),
                          bodytext: _controller.text));

                  // UI 업데이트 - 코멘트 추가
                  widget.comments.add(Comment(
                          commenterUid: _userInfo.uid,
                          commenterName: _userInfo.name,
                          commenterImg: _userInfo.img,
                          date: DateTime.now(),
                          bodytext: _controller.text)
                      .toJson());

                  print('comment added');
                  print('comments length: ${widget.comments.length}');

                  _controller.clear();

                  FocusScope.of(context).unfocus();
                  setState(() {});
                  print('add comment');
                  print('i: ${widget.comments.length}');
                },
                tooltip: '댓글추가',
                icon: Icon(
                  Icons.check,
                  color: Colors.blue,
                  size: 20.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
