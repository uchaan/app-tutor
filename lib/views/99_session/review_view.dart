import 'package:flutter/material.dart';
import 'package:crayon/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

class ReviewView extends StatefulWidget {
  const ReviewView({
    Key? key,
    required this.review,
  }) : super(key: key);

  final Review review;

  @override
  _ReviewViewState createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final _formKey = GlobalKey<FormState>();
  String conversationField = '선택해주세요';
  String childActivityField = '선택해주세요';
  String tutorActivityField = '선택해주세요';
  final openingField = TextEditingController();
  final closingField = TextEditingController();
  final characterField = TextEditingController();
  final honeytipField = TextEditingController();
  final happyPointField = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    openingField.dispose();
    closingField.dispose();
    characterField.dispose();
    honeytipField.dispose();
    happyPointField.dispose();
    super.dispose();
  }

  addNewReview(Review review) async {
    //review collection에 새로운 review를 추가
    CollectionReference reviews =
        FirebaseFirestore.instance.collection('review');
    await reviews
        .add({
          'child_uid': review.uid,
          'tutor_uid': FirebaseAuth.instance.currentUser!.uid,
          'date': review.date,
          'conversation': conversationField,
          'childActivity': childActivityField,
          'tutorActivity': tutorActivityField,
          'opening': openingField.text,
          'closing': closingField.text,
          'character': characterField.text,
          'honeytip': honeytipField.text,
          'happyPoint': happyPointField.text,
        })
        .then((value) => print("review added"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  updateDone(Review review) async {
    //user > session collection에서 해당 session을 찾아 done을 1로 update
    CollectionReference sessions = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('session');

    await sessions.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        //해당 session을 진행한 student uid와 date가 일치하는 곳으로 찾아 done update
        if (review.uid == doc['uid'] &&
            DateFormat('yyyy-MM-dd kk:mm').format(review.date) ==
                DateFormat('yyyy-MM-dd kk:mm').format(doc['date'].toDate())) {
          doc.reference
              .update({'uid': doc['uid'], 'date': doc['date'], 'done': 1})
              .then((value) => print("User Updated"))
              .catchError((error) => print("Failed to update user: $error"));
        }
      });
    });
  }

  Future<void> _buttonHandler() async {
    String msg = '';

    //입력해야할 값들이 모두 입력되었을 때
    if (_formKey.currentState!.validate() &&
        conversationField != '선택해주세요' &&
        childActivityField != '선택해주세요' &&
        tutorActivityField != '선택해주세요') {
      //session의 done 값을 1로 바꾸고
      await updateDone(widget.review);

      //리뷰를 DB에 등록한 이후
      await addNewReview(widget.review);

      // Provider.of<ReviewLists>(context, listen: false).getReviewList();

      //리뷰 리스트 페이지로 돌아간다.
      Navigator.pop(context);
      msg = "정상적으로 등록되었습니다.";
    } else {
      msg = "다시 입력해주세요.";
    }

    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.review.done == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text("세션 리뷰"),
        ),
        backgroundColor: HexColor('F7F7F7'),
        body: Center(
          child: Text("세션 리뷰가 완료되었습니다."),
        ),
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            title: Text("세션 리뷰"),
          ),
          backgroundColor: HexColor('F7F7F7'),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '아이와 대화가',
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      DropdownButton<String>(
                        value: conversationField,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: conversationField == '선택해주세요'
                              ? Colors.red
                              : Colors.black,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            conversationField = newValue!;
                          });
                        },
                        items: <String>['선택해주세요', '잘 통했어요', '무난했어요', '어색했어요']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '아이가',
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      DropdownButton<String>(
                        value: childActivityField,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: childActivityField == '선택해주세요'
                              ? Colors.red
                              : Colors.black,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            childActivityField = newValue!;
                          });
                        },
                        items: <String>['선택해주세요', '적극적', '보통', '소극적']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '으로 참여했어요.',
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '세션이',
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      DropdownButton<String>(
                        value: tutorActivityField,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: tutorActivityField == '선택해주세요'
                              ? Colors.red
                              : Colors.black,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            tutorActivityField = newValue!;
                          });
                        },
                        items: <String>['선택해주세요', '재미있었다', '보통이었다', '지루했다']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '어요.',
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: openingField,
                    decoration: const InputDecoration(
                      hintText: '예시) 동네 친구들이랑 이야기',
                      labelText: 'Opening 대화 주제(*)',
                    ),
                    validator: (value) {
                      return value!.isEmpty ? "Opening 대화 주제를 입력해주세요." : null;
                    },
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextFormField(
                    controller: closingField,
                    decoration: const InputDecoration(
                      hintText: '예시) 친구들과 저녁 게임 약속',
                      labelText: 'Closing 대화 주제(*)',
                    ),
                    validator: (value) {
                      return value!.isEmpty ? "Closing 대화 주제를 입력해주세요." : null;
                    },
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextFormField(
                    controller: characterField,
                    decoration: const InputDecoration(
                      hintText: '예시) 처음에는 낯을 가리지만 은근 장난기가 많아요.',
                      labelText: '내가 발견한 아이의 특징(*)',
                    ),
                    validator: (value) {
                      return value!.isEmpty ? "아이의 특징을 입력해주세요." : null;
                    },
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextFormField(
                    controller: honeytipField,
                    decoration: const InputDecoration(
                      hintText: '예시) 처음에는 낯을 가리지만 은근 장난기가 많아요.',
                      labelText: '다음 선생님에게 전하는 나의 꿀팁(*)',
                    ),
                    validator: (value) {
                      return value!.isEmpty ? "꿀팁을 입력해주세요." : null;
                    },
                  ),
                  Text(
                    "책 읽기 팁이나 아이의 특성, 주의사항 등을 다음 선생님에게 공유해주세요!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextFormField(
                    controller: happyPointField,
                    decoration: const InputDecoration(
                      hintText: '예시) 제 연기에 아이가 웃어줄 때 행복해요.',
                      labelText: '행복함을 느꼈을 때',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 15)),
                  //   onPressed: () {_buttonHandler();},
                  //   child: const Text('제출'),
                  // ),
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 20),
                    child: FractionallySizedBox(
                      widthFactor:
                          0.4, // means 100%, you can change this to 0.8 (80%)
                      child: ElevatedButton(
                        onPressed: _buttonHandler,
                        style: ElevatedButton.styleFrom(
                            primary: Colors.black,
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10.0)),
                            padding: EdgeInsets.all(3)),
                        child: Text("제출",
                            style:
                                TextStyle(fontSize: 15.0, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
    }
  }
}
