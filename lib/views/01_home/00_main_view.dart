import 'package:crayon/views/01_home/02-1_my_session_history.dart';
import 'package:crayon/views/01_home/01_reservations_widget.dart';
import 'package:crayon/views/01_home/02_prev_sessions_widget.dart';
import 'package:crayon/views/01_home/03_notification_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  Widget headerWidget(String name, IconData icon) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Icon(Icons.motion_photos_on_outlined, color: Colors.green,), // motion_phones_on
          Icon(
            icon,
            size: 25.sp,
          ), //event_rounded
          SizedBox(
            width: 5,
          ),
          Text(name,
              style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(0), children: <Widget>[
        headerWidget("세션 예약 목록", Icons.access_alarm),
        ReservationWidget(),
        Divider(thickness: 3.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            headerWidget("과거 세션 목록", Icons.auto_awesome_outlined),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 15.0, right: 8.0),
                primary: Colors.black,
                alignment: Alignment.centerRight,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MySessionHistoryView(),
                    ));
              },
              child: Text(
                '전체 보기 >',
                style: TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
        SessionHistoryWidget(),
        SizedBox(
          height: 10,
        ),
        Divider(
          thickness: 3.0,
        ),
        headerWidget("최신 알람 목록", Icons.campaign_outlined),
        NotificationWidget(),
      ]),
    );
  }
}
