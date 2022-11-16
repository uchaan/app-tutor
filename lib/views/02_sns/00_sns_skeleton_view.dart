import 'dart:convert';

import 'package:crayon/constants/strings.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/resources/database_methods.dart';
import 'package:crayon/resources/sns_firebase_api.dart';
import 'package:crayon/configs/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:crayon/models/post.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../providers/posts_provider.dart';
import 'package:provider/provider.dart';
import '01_post_item_widget.dart';
import 'package:http/http.dart' as http;

class SNSView extends StatefulWidget {
  const SNSView({Key? key}) : super(key: key);

  @override
  _SNSViewState createState() => _SNSViewState();
}

class _SNSViewState extends State<SNSView> {
  late CurrentUser _userInfo;
  bool waitingForUpload = false;
  // 현재 유저 이미지

  CollectionReference posts = FirebaseFirestore.instance.collection('posts');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userInfo = Provider.of<CurrentUser>(context, listen: false);
  }

  Future<void> newPostDialog(PostsProvider _postProvider) async {
    File? _image;
    final picker = ImagePicker();
    TextEditingController _controller = TextEditingController();
    // // 공개범위 0 = 전체공개  // 2 = 선생님에게만 //  1 = 학생에게만

    int showType = SNS_OPEN_TO_EVERYONE;

    Future _uploadFile(BuildContext context) async {
      try {
        String fileName = "";
        // 사진 있을때
        if (_image != null) {
          // 서버에 저장하기
          http.Response response =
              await DatabaseMethods().uploadSNSImage(_image!.path);
          String _fName = json.decode(response.body)['file_name'];
          print(response.statusCode.toString());
          fileName = snsDataServerUrl + "/" + _fName;
        }
        // 사진 없을때
        else {
          fileName = "empty";
        }
        // 파이어베이스에 Post 올려주기
        Post newPost = Post(
          posterUid: _userInfo.uid,
          posterName: _userInfo.name,
          posterImg: _userInfo.img, // 안씀
          date: DateTime.now(),
          bodytext: _controller.text,
          image: fileName,
          comments: [],
          like: [],
          amazed: [],
          laugh: [],
          sad: [],
          angry: [],
          reaction: 0,
          report: false,
          showType: showType,
        );

        // 문서 작성
        await SNSFirebaseApi.uploadPost(newPost);
      } catch (e) {
        print(e);
      }
      // 완료 후 앞 화면으로 이동
      _postProvider.initializePosts(_userInfo.blocked);
      Navigator.pop(context);
    }

    return showDialog<void>(
      context: this.context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            content: SingleChildScrollView(
                child: Container(
              width: 800,
              height: 600,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                            '  새 게시물',
                            style: TextStyle(color: Colors.black, fontSize: 25),
                          ),
                        ),
                        IconButton(
                            onPressed: () async {
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 600,
                                  imageQuality: 75);
                              if (pickedFile != null) {
                                setState(() {
                                  _image = File(pickedFile.path);
                                });
                              }
                            },
                            icon: Icon(Icons.camera_alt)),
                        IconButton(
                            onPressed: () => showDialog<void>(
                                  context: this.context,
                                  barrierDismissible:
                                      false, // user must tap button!
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(builder:
                                        (context, StateSetter setState) {
                                      return AlertDialog(
                                          contentPadding:
                                              EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          content: Container(
                                            height: 200,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      icon: Icon(
                                                        Icons.arrow_back,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Expanded(
                                                        child: Text('공개범위'))
                                                  ],
                                                ),
                                                TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        showType =
                                                            SNS_OPEN_TO_EVERYONE;
                                                      });
                                                    },
                                                    icon: Icon(
                                                        showType ==
                                                                SNS_OPEN_TO_EVERYONE
                                                            ? Icons
                                                                .radio_button_checked
                                                            : Icons
                                                                .radio_button_off_outlined,
                                                        color: Colors.black),
                                                    label: Text(
                                                      '전체공개',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    )),
                                                TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        showType =
                                                            SNS_OPEN_TO_TUTORS;
                                                      });
                                                    },
                                                    icon: Icon(
                                                        showType ==
                                                                SNS_OPEN_TO_TUTORS
                                                            ? Icons
                                                                .radio_button_checked
                                                            : Icons
                                                                .radio_button_off_outlined,
                                                        color: Colors.black),
                                                    label: Text(
                                                      '선생님에게만 공개',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    )),
                                                TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        showType =
                                                            SNS_OPEN_TO_CHILDREN;
                                                      });
                                                    },
                                                    icon: Icon(
                                                        showType ==
                                                                SNS_OPEN_TO_CHILDREN
                                                            ? Icons
                                                                .radio_button_checked
                                                            : Icons
                                                                .radio_button_off_outlined,
                                                        color: Colors.black),
                                                    label: Text(
                                                      '학생에게만 공개',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    )),
                                              ],
                                            ),
                                          ));
                                    });
                                  },
                                ),
                            icon: Icon(Icons.lock_outline_rounded,
                                color: Colors.black)),
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              waitingForUpload = true;
                            });
                            await _uploadFile(context);
                            setState(() {
                              waitingForUpload = false;
                            });
                          },
                          tooltip: '업로드',
                          icon: Icon(
                            Icons.check,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _image != null
                      ? SizedBox(
                          child: Image.file(
                            File(_image!.path),
                            // fit: BoxFit.cover,
                          ),
                          height: MediaQuery.of(context).size.height / 2,
                          width: MediaQuery.of(context).size.width,
                          // height: 100,
                          // width: 100,
                        )
                      : Container(),
                  Expanded(
                    child: Container(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
                        child: TextField(
                          style: TextStyle(fontSize: 20),
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration:
                              InputDecoration.collapsed(hintText: '문구 입력'),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )),
          );
        });
      },
    );
  }

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => PostsProvider(),
        child: Consumer<PostsProvider>(
            builder: (context, postsProvider, _) => Scaffold(
                  backgroundColor: HexColor('F7F7F7'),
                  body: Stack(children: [
                    ListViewWidget(
                      postsProvider: postsProvider,
                    ),
                    waitingForUpload
                        ? Positioned(
                            width: 360.w,
                            height: 690.w,
                            child: Container(
                              color: Color.fromARGB(204, 82, 82, 82),
                              child: Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "업로드중",
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ])),
                            ),
                          )
                        : Container(),
                  ]),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      newPostDialog(postsProvider);
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Color((0xffF07B3F)),
                  ),
                )));
  }
}
