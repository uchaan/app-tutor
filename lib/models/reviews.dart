import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewLists extends ChangeNotifier {
  final List<Review> _items = [];
  bool _initialzied = false;

  List<Review> get items => _items;
  bool get initialized => _initialzied;

  ReviewLists() {
    this.getReviewList().then((success) {
      if (success)
        this._initialzied = true;
      else
        this._initialzied = false;
      notifyListeners();
    });
  }

  // 과거세션들 가져오기
  Future<bool> getReviewList() async {
    _items.clear();
    bool success = false;
    //유저가 진행한 세션들의 데이터 가져오기
    CollectionReference sessions = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('session');

    await sessions
        .orderBy('date', descending: true)
        .limit(3)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        querySnapshot.docs.forEach((doc) {
          //session에는 child name 데이터가 없음
          Review review = Review(
              uid: doc['uid'],
              name: '',
              date: doc['date'].toDate(),
              done: doc['done']);
          // if (today.isAfter(doc['date'].subtract(Duration(days: 14))))
          //어떤 기준으로 보여줄까?
          _items.add(review);
        });
        success = await _getReviewUserData();
        this.sorting();
      } else {
        success = true;
      }
    });

    //child uid로 child name 데이터 가져오기

    if (success) notifyListeners();
    return success;
  }

  // 과거세션 child uid를 가지고 이름,사진 가져오기
  Future<bool> _getReviewUserData() async {
    bool success = false;
    for (var review in _items) {
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
          success = true;
        } else {
          print('Document does not exist on the database');
        }
      });
    }
    return success;
  }

  void sorting() {
    _items.sort((a, b) => a.done.compareTo(b.done));
  }

  void update() {}
}
