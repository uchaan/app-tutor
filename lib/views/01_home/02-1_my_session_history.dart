import 'package:crayon/providers/user_state.dart';
import 'package:crayon/views/99_session/review_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:crayon/models/review.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '01-2_child_profile_view.dart';

class MySessionHistoryView extends StatefulWidget {
  const MySessionHistoryView({Key? key}) : super(key: key);

  @override
  _MySessionHistoryPageState createState() => _MySessionHistoryPageState();
}

class _MySessionHistoryPageState extends State<MySessionHistoryView> {
  Future<List<Review>> _getReviewList() async {
    //유저가 진행한 세션들의 데이터 가져오기
    CollectionReference sessions = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('session');

    List<Review> resultList = [];

    // DateTime today = DateTime.now().subtract(Duration(days: 1));

    await sessions.get().then((QuerySnapshot querySnapshot) async {
      querySnapshot.docs.forEach((doc) {
        //session에는 child name 데이터가 없음
        Review review = Review(
            uid: doc['uid'],
            name: '',
            date: doc['date'].toDate(),
            done: doc['done']);
        // if (today.isAfter(doc['date'].subtract(Duration(days: 14))))
        //어떤 기준으로 보여줄까?
        resultList.add(review);
      });
    });

    //child uid로 child name 데이터 가져오기
    resultList = await _getReviewUserData(resultList);

    //작성하지 않은 리뷰를 우선순위로 띄우기
    resultList.sort((a, b) => a.done.compareTo(b.done));
    return resultList;
  }

  Future<List<Review>> _getReviewUserData(List<Review> reviewList) async {
    for (var review in reviewList) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(review.uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          //set child name to review
          Map<String, dynamic> data =
              documentSnapshot.data()! as Map<String, dynamic>;
          review.name = data['name'].toString();
          review.img = data['img'].toString();
          review.profileInfo = data['profileInfo'];
        } else {
          print('Document does not exist on the database');
        }
      });
    }
    return reviewList;
  }

  Future<void> _toProfileView(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data()! as Map<String, dynamic>;
        Provider.of<UserState>(context, listen: false)
            .setChildProfileView(data);
        Provider.of<UserState>(context, listen: false).changeStateTo(PROFILE);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('과거 세션 목록'),
      ),
      backgroundColor: HexColor('F7F7F7'),
      body: FutureBuilder<List<Review>>(
        future: _getReviewList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator());
          } else if (snapshot.data == null) {
            return Center(
                child: Text('세션을 진행한 후 리뷰를 작성해보세요!',
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)));
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                  itemCount: snapshot.data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                    childAspectRatio: 2 / 3, //item 의 가로 1, 세로 2 의 비율
                    mainAxisSpacing: 4, //수평 Padding
                    crossAxisSpacing: 4, //수직 Padding
                  ),
                  itemBuilder: (BuildContext context, index) {
                    return GestureDetector(
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                                flex: 4,
                                child: Container(
                                    width: 140,
                                    child: Image.network(
                                      '${snapshot.data[index].img}',
                                      fit: BoxFit.cover,
                                    ))),
                            SizedBox(height: 8),
                            Expanded(
                              flex: 1,
                              child: Text('${snapshot.data[index].name}',
                                  style: TextStyle(
                                      fontSize: 14.0, color: Colors.black87)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                  '${DateFormat('MM월 dd일').format(snapshot.data[index].date)}',
                                  style: TextStyle(
                                      fontSize: 13.0, color: Colors.black87)),
                            ),
                            Expanded(
                                flex: 2,
                                child: snapshot.data[index].done == 1
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '리뷰 완료 ',
                                            style: TextStyle(fontSize: 12.0),
                                          ),
                                          Icon(
                                            Icons.check,
                                            size: 16.0,
                                          )
                                        ],
                                      )
                                    : TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ReviewView(
                                                        review: snapshot
                                                            .data[index]),
                                              )).then((value) {
                                            setState(() {});
                                          });
                                        },
                                        icon: Icon(
                                          Icons.article,
                                          size: 17.0,
                                        ),
                                        label: Text(
                                          '리뷰하기',
                                          style: TextStyle(
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ))
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _toProfileView(
                            snapshot.data[index].uid); //child -> tutor_uid
                        // print("아이 정보 보여주기")
                      },
                    );
                  }),
            );
          }
        },
      ),
    );
  }
}
