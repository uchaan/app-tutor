// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:hexcolor/hexcolor.dart';
import 'dart:async';

import 'package:provider/provider.dart';

class ChildProfileView extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  const ChildProfileView({
    Key? key,
    required this.childInfo,
  }) : super(key: key);

  @override
  _ChildProfileViewState createState() => _ChildProfileViewState();
}

void showToast(String str) {
  Fluttertoast.showToast(
      msg: str,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 18.0);
}

class _ChildProfileViewState extends State<ChildProfileView>
    with TickerProviderStateMixin {
  TextStyle headingText =
      TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 30);
  TextStyle heading2Text = TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  TextStyle bodyText = TextStyle(color: Colors.black45, fontSize: 15);
  late Map profileInfo;
  late final Future<List<Map>>? _getReviews;

  late TabController tabController;

  @override
  void initState() {
    profileInfo = this.widget.childInfo['profileInfo'];
    print(profileInfo);
    _getReviews = getReviews();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabSelection);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  _handleTabSelection() {
    if (tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Widget childInfoCard(context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              child: Row(
                children: [
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          height: 70,
                          // padding: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage('${widget.childInfo['img']}'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Center(
                          child: Text(
                            widget.childInfo['name'],
                            style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('지역', 'location')),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('학교', 'school')),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('학년', 'grader')),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('장래희망', 'dream')),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('성격', 'character')),
                              Expanded(
                                  flex: 5,
                                  child: _smallBoxUpside('영어실력', 'level')),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                ],
              ),
            ),
            // SizedBox(
            //   height: 5,
            // ),
            Padding(
              padding: EdgeInsets.only(left: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: profileInfo['tmi'].map<Widget>((value) {
                  return Text("◈ $value",
                      style: TextStyle(fontSize: 15.0, color: Colors.black54));
                }).toList(),
              ),
            ),

            SizedBox(
              height: 10,
            ),
            Center(
              child: TextButton.icon(
                  style: TextButton.styleFrom(
                    // padding: const EdgeInsets.only(top: 15.0, right: 8.0),
                    primary: Colors.white,
                    backgroundColor: Colors.black,
                    fixedSize: Size(340.w, 30),
                    // alignment: Alignment.centerRight,
                  ),
                  icon: Icon(Icons.auto_stories_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text("책장",
                        style: TextStyle(
                            fontSize: 20.0,
                            // fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  onPressed: () {
                    Provider.of<UserState>(context, listen: false)
                        .setBookListView(this.widget.childInfo['name'],
                            this.widget.childInfo['uid']);
                    Provider.of<UserState>(context, listen: false)
                        .changeStateTo(BOOKLISTVIEW);
                  }),
            )
          ],
        ),
      ),
    );
  }

  interestTab() {
    return Padding(
      padding: EdgeInsets.all(14.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 3, child: _smallBox("취미", "hobby")),
              Expanded(flex: 3, child: _smallBox('유튜버', 'youtube')),
              Expanded(flex: 3, child: _smallBox('게임', 'game')),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 3, child: _smallBox('음식', 'food')),
              Expanded(flex: 3, child: _smallBox('동물', 'animal')),
              Expanded(flex: 3, child: _smallBox('영화/TV', 'film')),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 3, child: _smallBox('책', 'book')),
              Expanded(
                flex: 3,
                child: Container(),
              ),
              Expanded(
                flex: 3,
                child: Container(),
              ),
            ],
          ),
          SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }

  convTopicTab() {
    return FutureBuilder(
        future: _getReviews,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Text("Something went wrong");
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(4, 1, 4, 3),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${snapshot.data[index]['tutor_name']}",
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              Text(
                                  DateFormat('MM월 dd일').format(
                                      snapshot.data[index]['date'].toDate()),
                                  style: TextStyle(fontSize: 15.0)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text("시작할 때: ${snapshot.data[index]['opening']}"),
                          Text("끝날 때: ${snapshot.data[index]['closing']}"),
                          Divider(),
                        ]),
                  );
                });
          }
        });
  }

  reviewTab() {
    return FutureBuilder(
        future: _getReviews,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Text("Something went wrong");
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(4, 1, 4, 3),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${snapshot.data[index]['tutor_name']}",
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              Text(
                                  DateFormat('MM월 dd일').format(
                                      snapshot.data[index]['date'].toDate()),
                                  style: TextStyle(fontSize: 15.0)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text("꿀팁:  ${snapshot.data[index]['honeytip']}"),
                          Text("특징: ${snapshot.data[index]['character']}"),
                          Text("해피: ${snapshot.data[index]['happyPoint']}"),
                          Divider(),
                          // Text(DateFormat('yyyy-MM-dd kk:mm').format(DateTime.parse(snapshot.data[index]['date'])).toString()),
                        ]),
                  );
                });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("학생 프로필"),
          leading: IconButton(
            onPressed: () {
              Provider.of<UserState>(context, listen: false)
                  .changeStateTo(NAVIGATION);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: HexColor('F7F7F7'),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: childInfoCard(context),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Card(
                child: Column(
                  children: [
                    TabBar(
                      labelStyle: TextStyle(
                          fontSize: 17, fontFamily: 'hope'), //For Selected tab
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(width: 2.0, color: Colors.grey),
                        insets:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      ),
                      indicatorColor: Colors.grey,
                      controller: tabController,
                      labelColor: Colors.black,
                      tabs: [
                        Tab(text: '관심사'),
                        Tab(text: '대화 주제'),
                        Tab(text: '리뷰'),
                      ],
                    ),
                    Center(
                      child: [
                        interestTab(),
                        convTopicTab(),
                        reviewTab(),
                      ][tabController.index],
                    )
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget _smallBoxUpside(String category, String _category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
              fontSize: 15.0,
              color: Colors.black87,
              fontWeight: FontWeight.bold),
        ),
        Text(
          profileInfo[_category],
          style: TextStyle(fontSize: 13.0, color: Colors.black54),
        )
      ],
    );
  }

  Widget _smallBox(String category, String _category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
              fontSize: 15.0,
              color: Colors.black87,
              fontWeight: FontWeight.bold),
        ),
        Text(
          profileInfo[_category],
          style: TextStyle(fontSize: 13.0, color: Colors.black54),
        )
      ],
    );
  }

  Future<List<Map>> getReviews() async {
    List<Map> _allReviews = [];

    QuerySnapshot<Map> reviews = await FirebaseFirestore.instance
        .collection('review')
        .where('child_uid', isEqualTo: this.widget.childInfo['uid'])
        .get();

    reviews.docs.forEach((element) {
      _allReviews.add(element.data());
    });

    _allReviews = await _getReviewUserData(_allReviews);

    _allReviews.sort((a, b) => a['date'].compareTo(b['date']));
    return _allReviews;
  }

  Future<List<Map>> _getReviewUserData(List<Map> reviewList) async {
    for (Map reviewItem in reviewList) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewItem['tutor_uid'])
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          //set child name to review
          Map<String, dynamic> data =
              documentSnapshot.data()! as Map<String, dynamic>;
          reviewItem['tutor_name'] = data['name'].toString();
          reviewItem['tutor_img'] = data['img'].toString();
        } else {
          print('Document does not exist on the database');
        }
      });
    }
    return reviewList;
  }
}
