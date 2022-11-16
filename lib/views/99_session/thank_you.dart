import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/models/review.dart';
import 'package:crayon/models/reviews.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../99_session/review_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class ThankYouView extends StatefulWidget {
  const ThankYouView({Key? key}) : super(key: key);

  @override
  _ThankYouViewState createState() => _ThankYouViewState();
}

class _ThankYouViewState extends State<ThankYouView> {
  late CurrentSession _sessionInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _sessionInfo = Provider.of<CurrentSession>(context, listen: false);
    super.didChangeDependencies();
  }

  void noBtnHandler() {
    developer.log("노버튼 잘 눌림", name: "체크용");
    Navigator.pop(context);
  }

  void yesBtnHandler() async {
    //date, child name, child uid, done = 0
    developer.log("예스버튼 잘 눌림", name: "체크용");
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('session')
        .doc(Uuid().v1())
        .set({'date': DateTime.now(), 'done': 0, 'uid': _sessionInfo.childUid});

    String _dateKeyValue = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DocumentSnapshot _tempSnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .doc(_dateKeyValue)
        .get();
    Map sessionInfoMap = _tempSnapshot.data() as Map;
    String _rKeyValue =
        _sessionInfo.tutorUid + _sessionInfo.tutorName + _sessionInfo.childName;

    Map updatedValue = sessionInfoMap[_rKeyValue];
    print(updatedValue);
    updatedValue['complete'] = true;

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(_dateKeyValue)
        .update({_rKeyValue: updatedValue});

    await FirebaseFirestore.instance
        .collection('books')
        .doc(_sessionInfo.childUid)
        .get()
        .then((value) {
      List booklist = value.data()!['booklist'];
      for (int i = 0; i < booklist.length; i++) {
        if (booklist[i]['title'] == _sessionInfo.bookTitle) {
          booklist[i]['iterationNum'] += 1;
          break;
        }
      }
      value.reference.update({'booklist': booklist});
    });

    Review _review = Review(
        uid: _sessionInfo.childUid,
        name: _sessionInfo.childName,
        date: DateTime.now(),
        done: 0);
    Provider.of<ReviewLists>(context, listen: false).getReviewList();
    _sessionInfo.clear(); // current session 정보 초기화

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewView(review: _review)),
    );

    ///review 등록하라고 하기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "수고하셨습니다.",
      )),
      backgroundColor: Colors.blueGrey,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            child: Container(
              width: MediaQuery.of(context).size.width - 60,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text(
                        "감사합니다",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  Text("세션을 정상적으로 종료하셨으면 '예'버튼을 눌러주세요.",
                      style: TextStyle(fontSize: 20)),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    yesBtnHandler();
                  },
                  child: Text("예")),
              ElevatedButton(
                  onPressed: () {
                    noBtnHandler();
                  },
                  child: Text("아니오"))
            ],
          )
        ],
      ),
    );
  }
}
