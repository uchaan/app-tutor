import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/constants/strings.dart';
import 'package:crayon/models/reservation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ReservationLists extends ChangeNotifier {
  final List<ReservationItem> _items = [];
  bool _initialzied = false;

  List<ReservationItem> get items => _items;
  bool get initialized => _initialzied;

  ReservationLists() {
    this.getReservations();
  }

  // 예약자 userUid 가져오기
  Future<bool> getReservations() async {
    print("_getReservations");
    this._initialzied = false;
    //예약한 세션들 목록을 가져오기 위함
    try {
      List<ReservationItem> resultList = [];
      DateTime today = DateTime.now().subtract(Duration(days: 1));
      await FirebaseFirestore.instance
          .collection('reservations')
          .get()
          .then((value) {
        value.docs.forEach((doc) async {
          DateTime candidateDate = DateTime.parse(doc.id);
          if (today.compareTo(candidateDate) <= 0) {
            String _date = DateFormat('MM월 dd일').format(candidateDate);
            _date = _date + intToDay[candidateDate.weekday - 1];
            print(doc.id);
            for (final value in doc.data().values) {
              if (value['tutor_uid'] ==
                  FirebaseAuth.instance.currentUser!.uid) {
                ReservationItem item = ReservationItem(
                    time: value['time'],
                    date: _date,
                    formattedTime: DateTime.parse(
                        value['formatted_time'].toDate().toString()),
                    childUid: value['child_uid']);
                if (!resultList.contains(item)) resultList.add(item);
              }
            }
            // }
          }
        });
      });

      _items.addAll(await _getUserDataFromReservationItems(resultList));
      _items.sort(
        (a, b) => a.formattedTime.compareTo(b.formattedTime),
      );
      print('resultList: $_items');
      _initialzied = true;
      notifyListeners();

      return true;
    } catch (e) {
      _initialzied = false;
      //notifyListeners();
      return false;
    }
  }

  // userUid를 바탕으로 데이터(porfile, 이름, 이미지 ...)
  Future<List<ReservationItem>> _getUserDataFromReservationItems(
      List<ReservationItem> reservationList) async {
    for (var reservationItem in reservationList) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(reservationItem.childUid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          //set child name to review
          Map<String, dynamic> data =
              documentSnapshot.data()! as Map<String, dynamic>;
          reservationItem.name = data['name'].toString();
          reservationItem.img = data['img'].toString();
          reservationItem.FCMToken = data['FCMToken'];
          reservationItem.profileInfo = data['profileInfo'];
        } else {
          print('Document does not exist on the database');
        }
      });
    }
    return reservationList;
  }

  void add(ReservationItem item) {
    if (_items.isNotEmpty) {
      int index;
      for (index = 0; index < _items.length; index++) {
        if (_items[index].formattedTime.isAfter(item.formattedTime)) {
          break;
        }
      }
      print("INDEX: $index");
      _items.insert(index, item);
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  void removeFromTime(DateTime _time) {
    int index;
    for (index = 0; index < _items.length; index++) {
      if (_items[index].formattedTime.day == _time.day) {
        break;
      }
    }
    _items.removeAt(index);
    notifyListeners();
  }

  void remove(ReservationItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _initialzied = false;
    notifyListeners();
  }
}
