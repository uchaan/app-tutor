// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CurrentUser extends ChangeNotifier {
  bool _initialized = false;
  late String _uid;
  late String _name;
  late String _email;
  late Map _FCMToken;
  late String _img;
  late String _group;
  late String _phone;
  late Map _profileInfo;
  late List _blocked;

  bool get initialized => _initialized;
  String get uid => _uid;
  String get name => _name;
  String get email => _email;
  Map get FCMToken => _FCMToken;
  String get img => _img;
  String get phone => _phone;
  String get group => _group;
  Map get profileInfo => _profileInfo;
  List get blocked => _blocked;

  CurrentUser() {
    print(FirebaseAuth.instance.currentUser!.uid);
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      Map<String, dynamic>? userInfoMap = value.data();
      _uid = userInfoMap!['uid'];
      _name = userInfoMap['name'];
      _email = userInfoMap['email'];
      _FCMToken = userInfoMap['FCMToken'];
      _img = userInfoMap['img'];
      _phone = userInfoMap['phone'];
      _profileInfo = userInfoMap['profileInfo'];
      _group = userInfoMap['group'];
      _blocked = userInfoMap['blocked'];
      _initialized = true;

      notifyListeners();
    });
  }

  Future<void> updateUserInfo() async {
    print(FirebaseAuth.instance.currentUser!.uid);
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      Map<String, dynamic>? userInfoMap = value.data();
      _uid = userInfoMap!['uid'];
      _name = userInfoMap['name'];
      _email = userInfoMap['email'];
      _FCMToken = userInfoMap['FCMToken'];
      _img = userInfoMap['img'];
      _phone = userInfoMap['phone'];
      _profileInfo = userInfoMap['profileInfo'];
      _group = userInfoMap['group'];
      _blocked = userInfoMap['blocked'];
      _initialized = true;

      notifyListeners();
    });
  }

  void addBlockedUser(String _userId) {
    _blocked.add(_userId);
    notifyListeners();
  }

  void updateUserInfoFromMap(Map<String, dynamic> userInfoMap) async {
    _initialized = true;

    _uid = userInfoMap['uid'];
    _name = userInfoMap['name'];
    _email = userInfoMap['email'];
    _phone = userInfoMap['phone'];

    _FCMToken = userInfoMap['FCMToken'];
    _img = userInfoMap['img'];
    _profileInfo = userInfoMap['profileInfo'];
    _group = userInfoMap['group'];
    _blocked = userInfoMap['blocked'];

    notifyListeners();

    return;
  }
}
