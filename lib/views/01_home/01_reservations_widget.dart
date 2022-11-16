import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:crayon/controller.dart';
import 'package:crayon/models/reservation.dart';
import 'package:crayon/providers/reservation_provider.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:crayon/resources/chat/firebase_chat_core.dart';
import 'package:crayon/resources/session_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ReservationWidget extends StatefulWidget {
  const ReservationWidget({Key? key}) : super(key: key);

  @override
  _ReservationWidgetState createState() => _ReservationWidgetState();
}

class _ReservationWidgetState extends State<ReservationWidget> {
  final CarouselController _caroController = CarouselController();
  List intToDay = ['(월)', '(화)', '(수)', '(목)', '(금)', '(토)', '(일)'];
  late CurrentUser _userInfo;

  //STATE
  int _caroCurrIndex = 0;

  @override
  void didChangeDependencies() async {
    _userInfo = Provider.of<CurrentUser>(context, listen: false);

    super.didChangeDependencies();
  }

  Widget _hashBox(String _text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.fromLTRB(2.5, 1.5, 2.5, 1.5),
      child:
          Text(_text, style: TextStyle(fontSize: 15.w, color: Colors.black87)),
    );
  }

  Widget _waitingBox() {
    return SizedBox(
        width: double.infinity,
        height: 360.w / 2,
        child: Card(
            margin: EdgeInsets.fromLTRB(9.w, 0, 9.w, 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0)),
            child: Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator())));
  }

  Widget _widgetForNoReservation() {
    return SizedBox(
        width: double.infinity,
        height: 360.w / 2,
        child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0)),
            child: InkWell(
              onTap: () {
                Get.find<Controller>().onTabTapped(2);
              },
              child: ClipRRect(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Text(
                      '예약하러 가기',
                      style: TextStyle(
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Row(
                      children: [
                        //프로필 사진
                        Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerRight,
                              height: 100,
                              padding: EdgeInsets.fromLTRB(20, 0, 0, 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/Logo.png'),
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                            )),
                      ],
                    ),
                  )
                ],
              )),
            )));
  }

  List<Widget> reservationWidgets(List<ReservationItem> reservationList) {
    List<Widget> resultList = [];
    print(reservationList[0].name);
    reservationList.forEach((reservationItem) {
      resultList.add(
        Card(
            color: Colors.white,
            // clipBehavior: Clip.antiAlias,
            // elevation: 16,
            shape: RoundedRectangleBorder(
                // side: new BorderSide(color: Colors.grey, width: 1.0),

                borderRadius: BorderRadius.circular(25.0)),
            child: InkWell(
                onTap: () {
                  Provider.of<UserState>(context, listen: false)
                      .setChildProfileView(reservationItem.toMap());
                  Provider.of<UserState>(context, listen: false)
                      .changeStateTo(PROFILE);
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 4.w),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 2.w,
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                            '${reservationItem.date} ${reservationItem.time}',
                            style: TextStyle(
                                fontSize: 16.w, color: Colors.black54)),
                      ),
                      SizedBox(
                        height: 10.w,
                      ),
                      Container(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CachedNetworkImage(
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                    Icons.person_rounded,
                                    size: 90.w,
                                  ),
                              imageUrl: '${reservationItem.img}',
                              imageBuilder: (context, imageProvdier) =>
                                  CircleAvatar(
                                      radius: 45.w,
                                      backgroundImage: imageProvdier)),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: [
                                  Text('${reservationItem.name}',
                                      style: TextStyle(
                                          fontSize: 35.w,
                                          color: Colors.black87)),
                                  SizedBox(width: 4.w),
                                  Container(
                                      padding: EdgeInsets.fromLTRB(5, 3, 5, 3),
                                      decoration: BoxDecoration(
                                        color: SessionMethods().isSessionOpened(
                                                reservationItem)
                                            ? Color(0xffF07B3F)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        "Today !",
                                        style: TextStyle(
                                            fontSize: 15.w,
                                            color: Colors.white),
                                      )),
                                ],
                              ),
                              SizedBox(height: 5.w),
                              Row(
                                children: [
                                  _hashBox(
                                      '#${reservationItem.profileInfo['grader']}'),
                                  SizedBox(width: 3.w),
                                  _hashBox(
                                      '#${reservationItem.profileInfo['level']}')
                                ],
                              ),
                              SizedBox(height: 3.h),
                              _hashBox(
                                  '#${reservationItem.profileInfo['dream']}')
                            ],
                          ),
                        ],
                      )),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                                style: TextButton.styleFrom(
                                  primary: Colors.black,
                                ),
                                icon: Icon(Icons.call, size: 14.w),
                                label: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text("세션",
                                      style: TextStyle(
                                          fontSize: 14.w,
                                          color: Colors.black87)),
                                ),
                                onPressed: () => SessionMethods()
                                    .checkOpenedThenStartSession(
                                        context, _userInfo, reservationItem)),
                            SizedBox(
                              height: 14.w,
                              child: VerticalDivider(
                                thickness: 1,
                                color: Colors.black38,
                              ),
                            ),
                            Consumer<UserState>(
                              builder: (context, _userState, child) => Badge(
                                badgeColor: Colors.red,
                                showBadge: _userState.numOfNewChat[
                                        reservationItem.childUid] !=
                                    null,
                                elevation: 1,
                                padding: EdgeInsets.all(3),
                                position: BadgePosition(end: -6.w, top: 6.w),
                                toAnimate: false,
                                badgeContent: Text(
                                    _userState
                                        .numOfNewChat[reservationItem.childUid]
                                        .toString(),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 8.w)),
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    // padding: const EdgeInsets.only(top: 15.0, right: 8.0),
                                    primary: Colors.black,
                                    // alignment: Alignment.centerRight,
                                  ),
                                  icon: Icon(Icons.chat_bubble_outlined,
                                      size: 14.w),
                                  label: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text("채팅",
                                        style: TextStyle(
                                            fontSize: 14.w,
                                            color: Colors.black87)),
                                  ),
                                  onPressed: () {
                                    FirebaseChatCore.instance.joinChat(
                                        reservationItem.toMap(), context);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 14.w,
                              child: VerticalDivider(
                                thickness: 1,
                                color: Colors.black38,
                              ),
                            ),
                            TextButton.icon(
                                style: TextButton.styleFrom(
                                  primary: Colors.black,
                                  // alignment: Alignment.centerRight,
                                ),
                                icon: Icon(Icons.auto_stories_rounded,
                                    size: 14.w),
                                label: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text("책장",
                                      style: TextStyle(
                                          fontSize: 14.w,
                                          color: Colors.black87)),
                                ),
                                onPressed: () {
                                  Provider.of<UserState>(context, listen: false)
                                      .setBookListView(reservationItem.name,
                                          reservationItem.childUid);
                                  Provider.of<UserState>(context, listen: false)
                                      .changeStateTo(BOOKLISTVIEW);
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))),
      );
    });
    return resultList;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservationLists>(builder: (context, reservations, child) {
      if (reservations.initialized == false) {
        return _waitingBox();
      } else if (reservations.items.isEmpty) {
        return _widgetForNoReservation();
      } else {
        return Column(
          children: [
            CarouselSlider(
              items: reservationWidgets(reservations.items),
              carouselController: _caroController,
              options: CarouselOptions(
                  enlargeCenterPage: true,
                  viewportFraction: 0.95,
                  aspectRatio: 2,
                  onPageChanged: (index, reason) {
                    print('index: $index');
                    setState(() {
                      _caroCurrIndex = index;
                    });
                  }),
            ),
            // 아래코드: Carousel slider 위치 표시기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: reservationWidgets(reservations.items)
                  .asMap()
                  .entries
                  .map((entry) {
                return GestureDetector(
                  onTap: () {
                    _caroController.animateToPage(entry.key);
                  },
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withOpacity(
                                _caroCurrIndex == entry.key ? 0.9 : 0.4)),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }
    });
  }
}
