import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/models/reservation.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SessionMethods {
  Future<bool> updateCurrentSession(
    context,
    String _channelID,
    String _tutorName,
    String _childName,
  ) async {
    String docKeyValue = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print(docKeyValue);
    bool result = false;
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(docKeyValue)
        .get()
        .then((_doc) {
      String docKeyId = _channelID + _tutorName + _childName;

      Map docMap = _doc.data() as Map;

      if (docMap[docKeyId] != null) {
        Map reservationInfo = docMap[docKeyId];
        Provider.of<CurrentSession>(context, listen: false)
            .getDataFromMap(reservationInfo);
        result = true;
      }
    });
    return result;
  }

  void updateTutorConnectedToFirestore(String _key, bool _connected) {
    DateTime now = DateTime.now();
    String _today = DateFormat('yyyy-MM-dd').format(now);

    DocumentReference _dReference =
        FirebaseFirestore.instance.collection('reservations').doc(_today);

    _dReference.get().then((_rDocInfo) {
      Map _rMap = _rDocInfo.data() as Map;

      if (_rMap[_key] != null) {
        Map rItem = _rMap[_key];
        rItem['tutor_connected'] = _connected;
        _dReference.update({_key: rItem});
        //ToDO: 이거 업데이트 되는지 확인하기
      }
    });
  }

  void updateBookinfoToFirestore(CurrentSession _sessionInfo) {
    DateTime now = DateTime.now();
    String _today = DateFormat('yyyy-MM-dd').format(now);

    DocumentReference _dReference =
        FirebaseFirestore.instance.collection('reservations').doc(_today);

    _dReference.get().then((_rDocInfo) {
      Map _rMap = _rDocInfo.data() as Map;
      String _key = _sessionInfo.tutorUid +
          _sessionInfo.tutorName +
          _sessionInfo.childName;
      if (_rMap[_key] != null) {
        Map rItem = _rMap[_key];
        rItem['bookTitle'] = _sessionInfo.bookTitle;
        rItem['tutorBookMark'] = _sessionInfo.tutorBookMark;

        _dReference.update({_key: rItem});
        //ToDO: 이거 업데이트 되는지 확인하기

      }
    });
  }

  bool isSessionOpened(ReservationItem _rItem) {
    DateTime now = DateTime.now();

    String _today = DateFormat('yyyy-MM-dd').format(now);
    DateTime _date = _rItem.formattedTime;
    String _rDate = DateFormat('yyyy-MM-dd').format(_date);

    if (_rDate == _today)
      return true;
    else
      return false;
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

  void checkOpenedThenStartSession(
      BuildContext context, CurrentUser _userInfo, ReservationItem _rItem) {
    bool opened = SessionMethods().isSessionOpened(_rItem);
    if (opened) {
      updateCurrentSession(context, _userInfo.uid, _userInfo.name, _rItem.name);
    } else {
      showToast('세션이 아직 오픈되지 않았습니다. 예약일에 시도해주세요.');
    }
  }
}
