import 'package:flutter/material.dart';

class FCMMessages extends ChangeNotifier {
  int _numOfUnreadMessage = 0;
  List _messageList = [];

  int get numOfUnreadMessage => _numOfUnreadMessage;

  List get messsageList => _messageList;

  loadingFromSharedPreference() {}
}
