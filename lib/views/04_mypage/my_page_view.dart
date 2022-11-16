import 'package:cached_network_image/cached_network_image.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/views/00_auth/login_view.dart';
import 'package:crayon/views/03_schedule/schedule_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';

import 'edit_view.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  TextStyle headingText =
      TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 30);
  TextStyle heading2Text = TextStyle(color: Colors.blue);
  TextStyle bodyText = TextStyle(color: Colors.black, fontSize: 18);

  @override
  void initState() {
    super.initState();
  }

  void logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LogInView()),
      ModalRoute.withName(MaterialApp().toString()),
    );
    return null;
  }

  void edit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditView()),
    );
    return null;
  }

  void updateScheudle(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScheduleView()),
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(title: Text("내 정보")),
        // backgroundColor: Colors.blueGrey,
        backgroundColor: HexColor('F7F7F7'),
        body: ListView(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Icon(Icons.motion_photos_on_outlined, color: Colors.green,), // motion_phones_on
                  Text('내 정보',
                      style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  SizedBox(
                    width: 3,
                  ),
                  Icon(
                    Icons.account_circle_rounded,
                    size: 30,
                  ),
                ],
              ),
            ),
            Consumer<CurrentUser>(builder: (context, currentUserData, child) {
              if (!currentUserData.initialized)
                return Center(child: CircularProgressIndicator());
              else {
                print(currentUserData.name);
                return Padding(
                  padding: EdgeInsets.only(right: 20.0, left: 20.0),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: currentUserData.img,
                            imageBuilder: (context, imageProvdier) =>
                                CircleAvatar(
                              radius: 60,
                              backgroundImage: imageProvdier,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Center(
                            child: Text(
                              currentUserData.name,
                              style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ),
                          Center(
                            child: Text(
                              '튜터',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("직업",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['job'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("학교",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['school'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("학년",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['grader'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 13,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("전공",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['major'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("자신있는것",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['like'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("자신없는것",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData
                                              .profileInfo['dislike'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 13,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("취미",
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    SizedBox(height: 3),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          top: 1.5,
                                          bottom: 1.5,
                                          left: 2.5,
                                          right: 2.5),
                                      child: Text(
                                          currentUserData.profileInfo['hobby'],
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(flex: 3, child: Container()),
                              Expanded(flex: 3, child: Container()),
                            ],
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.black),
                                ),
                                onPressed: () => edit(),
                                icon: Icon(Icons.edit, size: 15),
                                label: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text("수정하기",
                                      style: TextStyle(
                                          fontSize: 13.0, color: Colors.white)),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.black),
                                ),
                                onPressed: () => logout(context),
                                icon: Icon(Icons.logout, size: 15),
                                label: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text("로그아웃",
                                      style: TextStyle(
                                          fontSize: 13.0, color: Colors.white)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            }),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }
}



//
