import 'package:crayon/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

const int NAVIGATION = 1;
const int BOOKLISTVIEW = 2;
const int COREADING = 3;
const int CHATTING = 4;
const int PROFILE = 5;
const int THANKYOU = 6;

const int PORTRAIT = 0;
const int LANDSCAPE = -1;

class UserState extends ChangeNotifier {
  int _state = NAVIGATION;

  late int _orientation = PORTRAIT;

  late Book _book;
  late String _childName;
  late String _childUid;
  late Map _FCMTokens;
  late types.Room _room;
  late Map<String, dynamic> _profileInfo;
  Map<String, int> _numOfNewChat = {};

  int get state => _state;
  String get childName => _childName;
  String get childUid => _childUid;
  Book get book => _book;
  Map get FCMTokens => _FCMTokens;
  types.Room get room => _room;
  Map<String, dynamic> get profileInfo => _profileInfo;
  Map get numOfNewChat => _numOfNewChat;
  int get orientation => _orientation;

  int changeStateTo(int targetState) {
    _state = targetState;
    notifyListeners();
    return _state;
  }

  void changeOrientation(int __orientation) {
    _orientation = __orientation;
  }

  bool setChattingView(types.Room _chatRoom, String _uid, Map _tokens) {
    print("SET CHATTING VIEW");
    _childUid = _uid;
    _FCMTokens = _tokens;
    _room = _chatRoom;
    return true;
  }

  bool deleteNewChatEntity(String _uid) {
    print(_uid);
    if (_numOfNewChat.remove(_uid) == null)
      return false;
    else
      return true;
  }

  void newChatIsAdded(String uid) {
    if (_numOfNewChat[uid] == null) {
      _numOfNewChat[uid] = 1;
    } else {
      _numOfNewChat[uid] = _numOfNewChat[uid]! + 1;
    }
    notifyListeners();
  }

  void numOfChatUpdateByMap(Map<String, int> _data) {
    _data.forEach((key, value) {
      _numOfNewChat[key] = value;
    });
    notifyListeners();
  }

  void setChildProfileView(Map<String, dynamic> _childInfo) {
    _profileInfo = _childInfo;
  }

  void setBookListView(String _name, String _uid) {
    _childName = _name;
    _childUid = _uid;
  }

  void setCoReadingView(String _name, String _uid, Book _bookInfo) {
    _childName = _name;
    _childUid = _uid;
    _book = _bookInfo;
  }
}
