import 'package:crayon/resources/session_method.dart';
import 'package:flutter/material.dart';

class CurrentSession extends ChangeNotifier {
  bool onLive = false;
  bool pipMode = false;
  String time = "Not decided yet";
  String channelId = "Not decided yet";
  String tutorUid = "Not decided yet";
  String tutorName = "Not decided yet";
  bool tutorConnected = false;
  String childUid = "Not decided yet";
  String childName = "Not decided yet";
  bool childConnected = false;
  String bookTitle = "Not decided yet";
  int childBookMark = 1;
  int tutorBookMark = 1;

  void getDataFromMap(Map session) {
    onLive = true;
    time = session['time'];
    channelId = session['channel_id'];
    tutorUid = session['tutor_uid'];
    tutorName = session['tutor_name'];
    tutorConnected = false; //ToDO: child app에서는 바꿔줘야 함
    childUid = session['child_uid'];
    childName = session['child_name'];
    childConnected = session['child_connected'];
    bookTitle = session['bookTitle'];
    childBookMark = session['childBookMark'];
    tutorBookMark = session['tutorBookMark'];
    print("GET DATA FROM MAP");
    notifyListeners();
  }

  void offLive() {
    onLive = false;
    notifyListeners();
  }

  void updateBookTitle(String _title) {
    bookTitle = _title;
  }

  void updateTutorConnected() {
    tutorConnected = !tutorConnected;
    //notifyListeners();

    SessionMethods().updateTutorConnectedToFirestore(
        tutorUid + tutorName + childName, tutorConnected);
  }

  void updateTutorBookMark(int _curPage) {
    tutorBookMark = _curPage;
  }

  void pipModeUpdate() {
    pipMode = !pipMode;
    notifyListeners();
  }

  void clear() {
    onLive = false;
    time = "Not decided yet";
    channelId = "Not decided yet";
    tutorUid = "Not decided yet";
    tutorConnected = false;
    childUid = "Not decided yet";
    childName = "Not decided yet";
    childConnected = false;
    bookTitle = "Not decided yet";
    childBookMark = 1;
    tutorBookMark = 1;
    notifyListeners();
  }
}
