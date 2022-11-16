import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/constants/strings.dart';
import 'package:crayon/models/reservation.dart';
import 'package:crayon/providers/reservation_provider.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:crayon/models/event.dart';
import 'package:provider/provider.dart';

class TimeSlotView extends StatefulWidget {
  final DateTime selectedDay;
  const TimeSlotView({Key? key, required this.selectedDay}) : super(key: key);

  @override
  _TimeSlotViewState createState() => _TimeSlotViewState();
}

class _TimeSlotViewState extends State<TimeSlotView> {
  late DateTime _selectedDay;
  late DocumentSnapshot _reservDocSnapshot;
  late QuerySnapshot<Map<String, dynamic>> _qSnapshot;

  List _selectedEvents = [];
  List _intToDay = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  List _timeSlots = [];
  late int _selectedTimeSlot;
  late bool _reserved;
  late bool _isClick;
  bool _isWeekend = false;
  late CurrentUser _userInfo;

  late Future<void> _timeSlotsLoad;

  FirebaseFirestore _firebase = FirebaseFirestore.instance;

  @override
  void initState() {
    print("reserve view init");
    timeSlotsInit();
    _selectedDay = this.widget.selectedDay;
    _selectedTimeSlot = -1;
    _reserved = false;
    _isClick = false;
    _timeSlotsLoad = timeSlotsLoad();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userInfo = Provider.of<CurrentUser>(context, listen: false);
  }

  @override
  void didUpdateWidget(TimeSlotView oldWidget) {
    _selectedDay = this.widget.selectedDay;
    _selectedTimeSlot = -1;
    _reserved = false;
    _isClick = false;
    _timeSlotsLoad = timeSlotsLoad();
    print("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
  }

  void timeSlotsInit() {
    for (int i = 8; i < 22; i++) {
      String prevTime =
          ((i ~/ 2) + 12).toString() + ":" + ((i % 2) == 0 ? "00" : "30");
      int j = i + 1;
      String postTime =
          ((j ~/ 2) + 12).toString() + ":" + ((j % 2) == 0 ? "00" : "30");
      String timeString = prevTime + "-" + postTime;

      _timeSlots.add(timeString);
    }
  }

  Future<void> timeSlotsLoad() async {
    // 특정 날짜 reservation 데이터 가져오기기
    String keyValue = DateFormat('yyyy-MM-dd').format(_selectedDay);
    _reservDocSnapshot =
        await _firebase.collection('reservations').doc(keyValue).get();

    _qSnapshot = await _firebase
        .collection('users')
        .where('group', isEqualTo: 'student')
        .get();
    myReserveExist(); //현재 예약이 존재하는가?
    _isClick = false;
    _selectedEvents = getEventsForDay();
    return;
  }

  void myReserveExist() {
    Map reservedMap = {};
    if (_reservDocSnapshot.data() != null) {
      reservedMap = _reservDocSnapshot.data() as Map;
      reservedMap.forEach((key, value) {
        if (value['tutor_uid'] == _userInfo.uid) {
          int index = -1;
          for (int i = 0; i < _timeSlots.length; i++) {
            if (_timeSlots[i] == value['time']) {
              index = i;
              break;
            }
          }
          if (index != -1) {
            _selectedTimeSlot = index;
            setState(() {
              _reserved = true;
            });
          }
        }
      });
    }
    print("RESERVED $_reserved");
  }

  List getEventsForDay() {
    Map events = {};
    String weekDay = _intToDay[_selectedDay.weekday - 1];
    if (weekDay == 'sat' || weekDay == 'sun') {
      //주말 예약 불가
      _isWeekend = true;
      return [];
    } else {
      _isWeekend = false;
    }

    _timeSlots.forEach((timeString) {
      Event event = Event(timeString, 0, []);
      events[timeString] = event;
    });
    // 각 시간슬롯별로 가능한 참여한 학생 수 계산.
    Map reservedMap = {};
    if (_reservDocSnapshot.data() != null)
      reservedMap = _reservDocSnapshot.data() as Map;

    _qSnapshot.docs.forEach((child) {
      Map _child = child.data();
      Map possibleTime = _child['availableTime'][weekDay];
      bool _isChildAlreadyReserved = false;

      for (final _reservation in reservedMap.values) {
        if (_reservation['child_uid'] == _child['uid']) {
          _isChildAlreadyReserved = true;
          break;
        }
      }

      if (!_isChildAlreadyReserved) {
        _timeSlots.forEach((element) {
          if (possibleTime[element]) {
            events[element].possibleSlots += 1;
            events[element].possibleChildList.add(_child);
          }
        });
      }
    });
    List returnResult = [];
    _timeSlots.forEach((timeSlot) {
      returnResult.add(events[timeSlot]);
    });

    return returnResult;
  }

  void activeBtn() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isClick = false;
      });
    });
  }

  Future<void> okBtnHandler() async {
    print("okBtnHandler");
    _isClick = true;

    // if (!isAfterTwoDay(DateTime.now(), _selectedDay)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('예약 및 변경은 이틀 전까지 가능합니다. 예약내용 변경을 원하시면 관리자에게 문의하세요.'),
    //     ),
    //   );
    //   activeBtn();
    //   return;
    // }

    //유저가 선택한 것이 있느냐?
    if (_selectedTimeSlot != -1) {
      setState(() {
        _isClick = true;
      });
      //누가 선수쳤으면 쥐쥐
      if (_selectedEvents[_selectedTimeSlot].possibleSlots == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다른 분이 해당 슬롯을 예약하셨습니다. 다시 예약하시기 바랍니다.'),
          ),
        );

        //reload
        _timeSlotsLoad = timeSlotsLoad();
        activeBtn();
        return;
      }

      bool success = false;
      try {
        await _firebase.runTransaction((transaction) async {
          //데이터 로드
          String keyValue = DateFormat('yyyy-MM-dd').format(_selectedDay);
          DocumentReference docReference =
              _firebase.collection('reservations').doc(keyValue);
          _reservDocSnapshot = await docReference.get();

          _selectedEvents = getEventsForDay();

          //학생 선택
          if (_selectedEvents.isNotEmpty) {
            _selectedEvents[_selectedTimeSlot].possibleChildList.shuffle();
            String childUid =
                _selectedEvents[_selectedTimeSlot].possibleChildList[0]['uid'];

            DocumentSnapshot childDocSnapshot =
                await _firebase.collection('users').doc(childUid).get();
            List hourAndMin = _selectedEvents[_selectedTimeSlot]
                .time
                .toString()
                .split('-')[0]
                .split(':');
            int _min = int.parse(hourAndMin[0]) * 60 + int.parse(hourAndMin[1]);

            Map childInfoMap = childDocSnapshot.data() as Map;

            Map reservationInfo = {
              'time': _selectedEvents[_selectedTimeSlot].time,
              'formatted_time':
                  DateTime.parse(keyValue).add(Duration(minutes: _min)),
              'channel_id': "${_userInfo.uid}${childInfoMap['uid']}",
              'tutor_uid': _userInfo.uid,
              'tutor_name': _userInfo.name,
              'tutor_connected': false,
              'child_uid': childUid,
              'child_name': childInfoMap['name'],
              'child_connected': false,
              'bookTitle': '?',
              'childBookMark': 1,
              'tutorBookMark': 1,
              'complete': false,
              // 'tutor': docSnapshot
            };
            String docFieldId =
                _userInfo.uid + _userInfo.name + childInfoMap['name'];
            if (!_reservDocSnapshot.exists) {
              docReference.set({docFieldId: reservationInfo});
              success = true;
              addToReservationLists(reservationInfo);
            } else {
              Map reservationMap = _reservDocSnapshot.data() as Map;
              String? reserveKeyValue;
              reservationMap.forEach((key, value) {
                if (value['child_uid'] == reservationInfo['child_uid']) {
                  reserveKeyValue = key;
                }
              });
              print(reserveKeyValue);

              if (reserveKeyValue == null) {
                transaction.set(docReference, {docFieldId: reservationInfo},
                    SetOptions(merge: true));
                success = true;
                addToReservationLists(reservationInfo);
              }
            }
          }
        });
      } catch (e) {
        success = false;
        print(e);
      }

      if (success) {
        //reload
        _timeSlotsLoad = timeSlotsLoad();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미 예약되었습니다. 재시도해주세요.'),
          ),
        );

        //reload
        _timeSlotsLoad = timeSlotsLoad();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가능한 슬롯을 하나 선택해주세요.'),
        ),
      );
    }
    activeBtn();
  }

  Future<void> editBtnHandler() async {
    setState(() {
      _isClick = true;
    });
    if (!isAfterTwoDay(DateTime.now(), _selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('예약 및 변경은 이틀 전까지 가능합니다. 이미 예약된 일정 변경을 원하시면 관리자에게 문의하세요.'),
        ),
      );

      activeBtn();
      return;
    }

    Map reservationMap = _reservDocSnapshot.data() as Map;

    String reserveKeyValue = "";
    reservationMap.forEach((key, value) {
      if (value['tutor_uid'] == _userInfo.uid) {
        reserveKeyValue = key;
      }
    });

    await _firebase
        .collection('reservations')
        .doc(DateFormat('yyyy-MM-dd').format(_selectedDay))
        .update({reserveKeyValue: FieldValue.delete()}).then(
            (value) => removeFromReservationLists(_selectedDay));

    //reload
    _timeSlotsLoad = timeSlotsLoad();

    setState(() {
      _isClick = false;
      _reserved = false;
    });
  }

  void addToReservationLists(
    Map _reservationInfo,
  ) {
    //update provider

    String _date =
        DateFormat('MM월 dd일').format(_reservationInfo['formatted_time']);
    _date = _date + intToDay[_reservationInfo['formatted_time'].weekday - 1];

    ReservationItem item = ReservationItem(
        time: _reservationInfo['time'],
        date: _date,
        childUid: _reservationInfo['child_uid'],
        formattedTime: _reservationInfo['formatted_time']);

    FirebaseFirestore.instance
        .collection('users')
        .doc(item.childUid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        //set child name to review
        Map<String, dynamic> data =
            documentSnapshot.data()! as Map<String, dynamic>;
        item.name = data['name'].toString();
        item.img = data['img'].toString();
        item.profileInfo = data['profileInfo'];
      }
      Provider.of<ReservationLists>(context, listen: false).add(item);
    });
  }

  void removeFromReservationLists(DateTime _time) {
    Provider.of<ReservationLists>(context, listen: false).removeFromTime(_time);
  }

  //allowChangeReservation
  bool isNextWeek(DateTime _today, DateTime _chosenDay) {
    int leftDateForNextSunday = 7 - _today.weekday;
    int leftDateForNextSaturday = leftDateForNextSunday + 6;

    DateTime nextSunday = _today.add(Duration(days: leftDateForNextSunday));
    DateTime nextSaturday = _today.add(Duration(days: leftDateForNextSaturday));
    print("isNextWeek");
    print(_chosenDay.isAfter(nextSunday) && _chosenDay.isBefore(nextSaturday));
    if (_chosenDay.isAfter(nextSunday) && _chosenDay.isBefore(nextSaturday))
      return true;
    else
      return false;
  }

  bool isAfterTwoDay(DateTime _today, DateTime _chosenDay) {
    return _chosenDay.isAfter(_today.add(Duration(days: 1)));
  }

  GestureDetector timeTable(int index) {
    return GestureDetector(
        onTap: () {
          if (_selectedEvents[index].possibleSlots < 1 || _reserved) {
            print("cannot touch");
          } else {
            setState(() {
              _selectedTimeSlot = index;
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: Container(
            width: 80,
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedEvents[index].toString().substring(0, 5),
                  style: TextStyle(
                      color: _selectedTimeSlot == index
                          ? Colors.white
                          : Colors.black,
                      fontSize: 16),
                ),
                Text(
                  _selectedEvents[index].possibleSlots.toString() + "명",
                  style: TextStyle(
                      color: _selectedTimeSlot == index
                          ? Colors.white
                          : Colors.black,
                      fontSize: 18),
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: _reserved
                  ? _selectedTimeSlot == index
                      ? Colors.black87
                      : HexColor('#eeeeee')
                  : _selectedTimeSlot == index
                      ? Color(0xffF07B3F)
                      : _selectedEvents[index].possibleSlots == 0
                          ? HexColor('#eeeeee')
                          : HexColor('#FAF4D3'),
            ),
          ),
        ));
  }

  Widget reservationButton() {
    return _isWeekend
        ? Container(
            decoration: BoxDecoration(
              color: Color(0xffF07B3F),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            height: 40,
            width: 320.w,
            child: Center(
                child: Text("재충전의 날!",
                    style: TextStyle(fontSize: 18, color: Colors.white))),
          )
        : InkWell(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              height: 40,
              width: 320.w,
              child: Center(
                  child: !_reserved
                      ? Text("예약하기",
                          style: TextStyle(fontSize: 20, color: Colors.white))
                      : Text("취소하기",
                          style: TextStyle(fontSize: 20, color: Colors.white))),
            ),
            onTap: !_reserved
                ? _isClick
                    ? null
                    : okBtnHandler
                : _isClick
                    ? null
                    : editBtnHandler);
  }

  @override
  Widget build(BuildContext context) {
    print("Reserve view build");
    print(_selectedDay);
    return Expanded(
        child: FutureBuilder(
            future: _timeSlotsLoad,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(" ${snapshot.error}");
                print("schedule view something wrong");
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return Column(children: [
                  Container(),
                  CircularProgressIndicator(),
                ]);
              } else {
                return Stack(children: [
                  Column(
                    children: [
                      reservationButton(),
                      Divider(),
                      (_selectedEvents.isEmpty)
                          ? Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  "주말은 편히 쉬세요!",
                                  textScaleFactor: 2,
                                ),
                              ),
                            )
                          : Expanded(
                              child: SingleChildScrollView(
                                  child: Column(children: [
                              for (int i = 0; i < 5; i++)
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    timeTable(i * 3 + 0),
                                    timeTable(i * 3 + 1),
                                    (i != 4)
                                        ? timeTable(i * 3 + 2)
                                        : Container(
                                            width: 80,
                                            height: 60,
                                          )
                                  ],
                                ),
                            ])))
                    ],
                  ),
                  _isClick
                      ? Positioned(
                          child: Container(
                            color: Color.fromARGB(204, 82, 82, 82),
                            child: Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "예약중",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ])),
                          ),
                        )
                      : Container(),
                ]);
              }
            }));
  }
}
