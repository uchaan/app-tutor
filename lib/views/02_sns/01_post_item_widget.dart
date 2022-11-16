import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/models/post.dart';
import 'package:crayon/views/02_sns/02_sns_comment_view.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/current_user.dart';
import '../../providers/posts_provider.dart';
import 'package:flutter/material.dart';
import '../../resources/sns_firebase_api.dart';

class EmotionItemModel {
  String title;
  String icon;
  int index;

  EmotionItemModel(this.title, this.icon, this.index);
}

class EmotionUser {
  String name;
  String uid;
  String img;
  int emotionIndex;

  EmotionUser(this.name, this.uid, this.img, this.emotionIndex);
}

class OptionItemModel {
  String title;
  IconData icon;
  int index;
  OptionItemModel(this.title, this.icon, this.index);
}

class ListViewWidget extends StatefulWidget {
  final PostsProvider postsProvider;

  const ListViewWidget({
    required this.postsProvider,
    Key? key,
  }) : super(key: key);

  @override
  _ListViewWidgetState createState() => _ListViewWidgetState();
}

class _ListViewWidgetState extends State<ListViewWidget> {
  final scrollController = ScrollController();

  String _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _isFetchingPosts = false;

  List<EmotionItemModel> emotionMenuItems = [
    EmotionItemModel('좋아요', '\u{1F44D}', 1),
    EmotionItemModel('놀라워요', '\u{1F632}', 2),
    EmotionItemModel('웃겨요', '\u{1F602}', 3),
    EmotionItemModel('슬퍼요', '\u{1F622}', 4),
    EmotionItemModel('화나요', '\u{1F621}', 5),
  ];

  List<OptionItemModel> optionMenuItems = [
    OptionItemModel('신고', Icons.report_problem_outlined, 1),
    OptionItemModel('차단', Icons.block_outlined, 2)
  ];

  @override
  void initState() {
    super.initState();

    scrollController.addListener(scrollListener);
  }

  @override
  void didChangeDependencies() {
    setState(() {
      _isFetchingPosts = true;
    });
    widget.postsProvider.fetchNextPosts(context);
    setState(() {
      _isFetchingPosts = false;
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent / 2 &&
        !scrollController.position.outOfRange) {
      if (widget.postsProvider.hasNext) {
        widget.postsProvider.fetchNextPosts(context);
      }
    } else if (scrollController.offset ==
            scrollController.position.minScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _isFetchingPosts = true;
      });
      widget.postsProvider.initializePosts(
          Provider.of<CurrentUser>(context, listen: false).blocked);
      setState(() {
        _isFetchingPosts = false;
      });
    }
  }

  void reportToServiceProvider(Post _post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("게시물 신고하기"),
          content: new Text(
              "다른 사람들에게 불쾌감을 줄 수 있거나, 폭력적인 컨텐츠를 담고 있으면 아래 신고 버튼을 해당 게시물을 신고해주세요."),
          actions: <Widget>[
            ElevatedButton(
              child: new Text("신고"),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('posts')
                    .doc(_post.docId)
                    .update({'report': true});

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(primary: Colors.grey),
            ),
            ElevatedButton(
              child: new Text("취소"),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(primary: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  void blockThisUsersContent(Post _post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("해당 유저 차단하기"),
          content: new Text("해당 유저를 차단하시겠습니까? 차단된 게시자의 게시물은 앞으로 게시되지 않습니다."),
          actions: <Widget>[
            ElevatedButton(
                child: new Text("예"),
                onPressed: () {
                  CurrentUser _userInfo =
                      Provider.of<CurrentUser>(context, listen: false);
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_userInfo.uid)
                      .get()
                      .then((value) {
                    List _updatedBlockedList = value['blocked'];
                    _updatedBlockedList.add(_post.posterUid);

                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(_userInfo.uid)
                        .update({'blocked': _updatedBlockedList}).then((value) {
                      _userInfo.addBlockedUser(_post.posterUid);
                      widget.postsProvider.initializePosts(_userInfo.blocked);
                    });
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(primary: Colors.grey)),
            ElevatedButton(
              child: new Text("아니오"),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(primary: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  Widget showOptions(Post _post) {
    CustomPopupMenuController _optionController = CustomPopupMenuController();

    List<Widget> _optionList = optionMenuItems
        .map((item) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _optionController.hideMenu();
              switch (item.title) {
                case "신고":
                  reportToServiceProvider(_post);
                  break;
                case "차단":
                  blockThisUsersContent(_post);
                  break;
              }
            },
            child: Container(
              height: 40,
              child: Row(children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  item.title,
                  style: TextStyle(fontSize: 17, color: Colors.white),
                )
              ]),
            )))
        .toList();

    return Row(children: [
      _uid == _post.posterUid
          ? GestureDetector(
              child: Icon(Icons.delete_outlined),
              onTap: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('포스트 삭제'),
                  content: const Text('포스트를 영구적으로 삭제하시겠습니까?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        bool success =
                            await SNSFirebaseApi.deletePost(_post.docId);
                        Navigator.pop(context);

                        setState(() {});

                        if (success) {
                          Fluttertoast.showToast(
                              msg: "포스트가 삭제되었습니다.",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                          setState(() {
                            _isFetchingPosts = true;
                          });
                          widget.postsProvider.initializePosts(
                              Provider.of<CurrentUser>(context, listen: false)
                                  .blocked);
                          setState(() {
                            _isFetchingPosts = false;
                          });
                        } else {
                          Fluttertoast.showToast(
                              msg: "다시 시도해 주십시오.",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }

                        // setState(() {});
                      },
                      child: const Text('예'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('아니요'),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      CustomPopupMenu(
          child: Icon(Icons.menu),
          menuBuilder: () => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  color: Colors.black54,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: IntrinsicWidth(
                      child: Column(
                    children: _optionList,
                  )),
                ),
              ),
          pressType: PressType.singleClick,
          verticalMargin: -10,
          controller: _optionController)
    ]);
  }

  Future<Map> getPosterInfo(String _uid) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();

    return documentSnapshot.data() as Map;
  }

  @override
  Widget build(BuildContext context) => ListView(
        controller: scrollController,
        children: [
          _isFetchingPosts
              ? Center(child: CircularProgressIndicator())
              : Container(),
          ...widget.postsProvider.posts.map((post) {
            Future<Map> _posterInfo = getPosterInfo(post.posterUid);

            return FutureBuilder<Map>(
                future: _posterInfo,
                builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
                  String posterName = post.posterName;

                  if (snapshot.hasData) {
                    if (snapshot.data!['group'] == 'tutor')
                      posterName += " 튜터";
                    else
                      posterName += "";
                  }
                  return ExpandableNotifier(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //작성자 프로필, 삭제 메뉴
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: post.posterImg,
                                        imageBuilder: (context, _provider) {
                                          return CircleAvatar(
                                              backgroundImage: _provider);
                                        },
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.person),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(posterName),
                                          Text(DateFormat('MM월 dd일')
                                              .format(post.date)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  showOptions(post)
                                ]),
                            SizedBox(
                              height: 10,
                            ),
                            //사진이 있을때만 보여주기
                            if (post.image != "empty")
                              CachedNetworkImage(imageUrl: post.image),
                            SizedBox(
                              height: 10,
                            ),
                            //글
                            ScrollOnExpand(
                              scrollOnExpand: true,
                              scrollOnCollapse: false,
                              child: ExpandablePanel(
                                theme: const ExpandableThemeData(
                                  headerAlignment:
                                      ExpandablePanelHeaderAlignment.center,
                                  tapBodyToCollapse: true,
                                ),
                                header: Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Text(
                                      posterName,
                                      // style: Theme.of(context).textTheme.body2,
                                    )),
                                collapsed: Text(
                                  post.bodytext,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                expanded: Text(
                                  post.bodytext,
                                ),
                                builder: (_, collapsed, expanded) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        left: 10, right: 10, bottom: 10),
                                    child: Expandable(
                                      collapsed: collapsed,
                                      expanded: expanded,
                                      theme: const ExpandableThemeData(
                                          crossFadePoint: 0),
                                    ),
                                  );
                                },
                              ),
                            ),
                            //감정 표현들, 나의 감정표현
                            StatefulBuilder(builder: (context, setState) {
                              CustomPopupMenuController _popupMenuController =
                                  CustomPopupMenuController();

                              return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    //감정 표현들
                                    GestureDetector(
                                      onLongPress: () {
                                        HapticFeedback.lightImpact();
                                        print("누가 감정표현했는지 보여주기");
                                        showModalBottomSheet<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return FutureBuilder(
                                                future: SNSFirebaseApi
                                                    .getEmotionUserInfos(
                                                        post.like,
                                                        post.amazed,
                                                        post.laugh,
                                                        post.sad,
                                                        post.angry),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot
                                                        emotionUserList) {
                                                  if (emotionUserList.hasData) {
                                                    return Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              .4,
                                                      color: Colors.white,
                                                      child: ListView.builder(
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            emotionUserList
                                                                .data.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    2),
                                                            child: ListTile(
                                                              leading: emotionUserList
                                                                          .data[
                                                                              index]
                                                                          .emotionIndex ==
                                                                      1
                                                                  ? Text(
                                                                      '\u{1F44D}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              20),
                                                                    )
                                                                  : emotionUserList
                                                                              .data[index]
                                                                              .emotionIndex ==
                                                                          2
                                                                      ? Text(
                                                                          '\u{1F632}',
                                                                          style:
                                                                              TextStyle(fontSize: 20),
                                                                        )
                                                                      : emotionUserList.data[index].emotionIndex == 3
                                                                          ? Text(
                                                                              '\u{1F602}',
                                                                              style: TextStyle(fontSize: 20),
                                                                            )
                                                                          : emotionUserList.data[index].emotionIndex == 4
                                                                              ? Text(
                                                                                  '\u{1F622}',
                                                                                  style: TextStyle(fontSize: 20),
                                                                                )
                                                                              : Text(
                                                                                  '\u{1F621}',
                                                                                  style: TextStyle(fontSize: 20),
                                                                                ),
                                                              title: Text(
                                                                  emotionUserList
                                                                      .data[
                                                                          index]
                                                                      .name),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  } else if (emotionUserList
                                                      .hasError) {
                                                    return Center(
                                                        child: Text(
                                                            '에러가 발생했습니다.'));
                                                  } else {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }
                                                });
                                          },
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(width: 2),
                                          post.like.length == 0
                                              ? Container()
                                              : Text(
                                                  '\u{1F44D} ${post.like.length.toString()}  '),
                                          post.amazed.length == 0
                                              ? Container()
                                              : Text(
                                                  '\u{1F632} ${post.amazed.length.toString()}  '),
                                          post.laugh.length == 0
                                              ? Container()
                                              : Text(
                                                  '\u{1F602} ${post.laugh.length.toString()}  '),
                                          post.sad.length == 0
                                              ? Container()
                                              : Text(
                                                  '\u{1F622} ${post.sad.length.toString()}  '),
                                          post.angry.length == 0
                                              ? Container()
                                              : Text(
                                                  '\u{1F621} ${post.angry.length.toString()}'),
                                        ],
                                      ),
                                    ),
                                    //나의 감정표현
                                    CustomPopupMenu(
                                      child: Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(3, 0, 3, 0),
                                          child: post.reaction == 0
                                              ? Icon(
                                                  Icons.add_reaction_outlined,
                                                  size: 20,
                                                )
                                              : post.reaction == 1
                                                  ? Text(
                                                      '\u{1F44D}',
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    )
                                                  : post.reaction == 2
                                                      ? Text(
                                                          '\u{1F632}',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        )
                                                      : post.reaction == 3
                                                          ? Text(
                                                              '\u{1F602}',
                                                              style: TextStyle(
                                                                  fontSize: 20),
                                                            )
                                                          : post.reaction == 4
                                                              ? Text(
                                                                  '\u{1F622}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20),
                                                                )
                                                              : Text(
                                                                  '\u{1F621}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20),
                                                                )),
                                      menuBuilder: () => ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Container(
                                          // color: const Color(0xFF4C4C4C),
                                          color: Colors.white,
                                          child: IntrinsicWidth(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: emotionMenuItems
                                                  .map(
                                                    (item) => GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .translucent,
                                                      onTap: () {
                                                        print(
                                                            "onTap ${item.title} ${item.index}");
                                                        _popupMenuController
                                                            .hideMenu();
                                                        setState(() {
                                                          //이전거 빼고
                                                          switch (
                                                              post.reaction) {
                                                            case 1:
                                                              {
                                                                post.like
                                                                    .remove(
                                                                        _uid);
                                                                break;
                                                              }
                                                            case 2:
                                                              {
                                                                post.amazed
                                                                    .remove(
                                                                        _uid);
                                                                break;
                                                              }
                                                            case 3:
                                                              {
                                                                post.laugh
                                                                    .remove(
                                                                        _uid);
                                                                break;
                                                              }
                                                            case 4:
                                                              {
                                                                post.sad.remove(
                                                                    _uid);
                                                                break;
                                                              }
                                                            case 5:
                                                              {
                                                                post.angry
                                                                    .remove(
                                                                        _uid);
                                                                break;
                                                              }
                                                          }

                                                          //새로운거 넣고
                                                          switch (item.index) {
                                                            case 1:
                                                              {
                                                                post.like
                                                                    .add(_uid);
                                                                break;
                                                              }
                                                            case 2:
                                                              {
                                                                post.amazed
                                                                    .add(_uid);
                                                                break;
                                                              }
                                                            case 3:
                                                              {
                                                                post.laugh
                                                                    .add(_uid);
                                                                break;
                                                              }
                                                            case 4:
                                                              {
                                                                post.sad
                                                                    .add(_uid);
                                                                break;
                                                              }
                                                            case 5:
                                                              {
                                                                post.angry
                                                                    .add(_uid);
                                                                break;
                                                              }
                                                          }

                                                          SNSFirebaseApi
                                                              .updateEmotion(
                                                                  post.docId,
                                                                  post.reaction,
                                                                  item.index);

                                                          //reaction 바꾸고
                                                          post.reaction =
                                                              item.index;
                                                        });
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 5),
                                                        child: Column(
                                                          children: <Widget>[
                                                            Text(
                                                              item.icon,
                                                            ),
                                                            Text(
                                                              item.title,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      position: PreferredPosition.bottom,
                                      pressType: PressType.singleClick,
                                      verticalMargin: -5,
                                      controller: _popupMenuController,
                                    ),
                                  ]);
                            }),
                            Divider(
                              thickness: 0.5,
                            ),
                            //최근 댓글 1개 미리보기
                            post.comments.length == 0
                                ? Container()
                                : Padding(
                                    padding: EdgeInsets.fromLTRB(3, 1, 3, 1),
                                    child: Row(
                                      children: [
                                        Text(
                                          post.comments[0]['commenterName'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 3),
                                        Text(post.comments[0]['bodytext']),
                                      ],
                                    ),
                                  ),
                            //댓글 더보기
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SNSCommentView(
                                          // postId: docId[index],
                                          postId: post.docId,
                                          comments: post.comments,
                                        ),
                                      ));
                                  setState(() {});
                                },
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(3, 1, 3, 2),
                                  child: post.comments.length == 0
                                      ? Text('첫 댓글을 달아주세요')
                                      : Text(
                                          '댓글 ${post.comments.length.toString()}개 모두 보기'),
                                ))
                          ],
                        ),
                      ),
                    ),
                  );
                });
          }).toList(),
        ],
      );
}
