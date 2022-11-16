import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({Key? key}) : super(key: key);

  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  List<dynamic> cacheList = [];

  Future<void> checkCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cachedData = prefs.getString('notification') ?? '';

    // 캐시에 저장된거 있을때
    if (cachedData != '') {
      var cache = jsonDecode(cachedData);
      setState(() {
        cacheList = cache;
      });
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await checkCache();
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(
      cacheList.length,
      (i) => GestureDetector(
          onTap: () async {
            cacheList.removeAt(i);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('notification', jsonEncode(cacheList));

            setState(() {});
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 30, 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color(0xffFEECE9).withOpacity(0.7)),
              child: Column(
                children: [
                  Row(children: [
                    Icon(
                      cacheList[i]['type'] == 'video'
                          ? Icons.video_call_outlined
                          : Icons.mail,
                    ),
                    SizedBox(width: 10),
                    Text(
                        cacheList[i]['type'] == 'video'
                            ? cacheList[i]['receiver_name']
                            : cacheList[i]['title'],
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold))
                  ]),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          cacheList[i]['type'] == 'video'
                              ? '세션 알림이 도착했습니다'
                              : cacheList[i]['body'],
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left)
                    ],
                  )
                ],
              ),
            ),
          )),
    );
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          // Each Dismissible must contain a Key. Keys allow Flutter to
          // uniquely identify widgets.
          key: UniqueKey(),
          // Provide a function that tells the app
          // what to do after an item has been swiped away.
          onDismissed: (direction) async {
            // Remove the item from the data source.
            cacheList.removeAt(index);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('notification', jsonEncode(cacheList));

            setState(() {
              items.remove(index);
            });
          },
          child: item,
        );
      },
    );
  }
}
