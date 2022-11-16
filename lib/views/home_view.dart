import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/controller.dart';
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/providers/reservation_provider.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:crayon/resources/chat/firebase_chat_core.dart';
import 'package:crayon/resources/firebase_method.dart';
import 'package:crayon/views/01_home/00_main_view.dart';
import 'package:crayon/views/01_home/01-2_child_profile_view.dart';
import 'package:crayon/views/03_schedule/schedule_view.dart';
import 'package:crayon/views/99_session/booklist_view.dart';
import 'package:crayon/views/99_session/coreading_view.dart';
import 'package:crayon/views/99_session/pick_up_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '01_home/01-1_chat_view.dart';
import '02_sns/00_sns_skeleton_view.dart';
import '04_mypage/my_page_view.dart';

import 'dart:io'; //Platform .isAndroid // isIOS
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'dart:convert';

/* 
* Navigation Bar (1. home, 2.SNS, 3.schedule, 4.My Page) 관리
* Noification 관리에 관련된 함수들
* a) initFCMHandler (forgroundHandler, backgroundHandler)
* b) _showNotification: FCM으로 받은 message를 FlutterLocalNotification으로 보여줌
* c) saveToCache: sharedPreference에 최근 5개 notifcation 저장 (FCM message 올 때 마다 불림)
* d) ReceivedNotification : notification용 자료구조 
* e) onSelectedNotifciation: 알람 클릭했을때 알람과 관련된 화면 띄어주는 코드
*/

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

Future<void> _showNotification(Map<String, dynamic> dataMap) async {
  print("show notification");
  //chat, news, alarm

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('crayon', 'crayon 알림',
          channelDescription: '메시지/뉴스/알람을 띄어줍니다.',
          showWhen: true,
          channelShowBadge: true,
          importance: Importance.max,
          priority: Priority.max,
          enableLights: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          ticker: 'ticker',
          icon: '@drawable/logo',
          largeIcon: const DrawableResourceAndroidBitmap('logo'));

  const iOSNotificationDetails = IOSNotificationDetails();

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSNotificationDetails);
  int _notiID = UniqueKey().hashCode;
  await flutterLocalNotificationsPlugin.show(
      _notiID,
      dataMap['title'], // title에 앱 이름 적어서 보내주자.
      dataMap['body'],
      platformChannelSpecifics,
      payload: json.encode(dataMap)); // ToDO: id값 의미 찾아보기
}

Future<void> saveToCache(RemoteMessage message) async {
  // 알림띄우기 전에 캐시 불러와서 노티피케이션 추가해줘야함
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cachedData = prefs.getString('notification') ?? '';
  //캐시에 저장된거 없을때
  if (cachedData == '') {
    List<dynamic> cacheList = [message.data];
    prefs.setString('notification', jsonEncode(cacheList));
  }
  // 캐시에 저장된거 있을때
  else {
    print(cachedData);
    var cacheList = jsonDecode(cachedData);
    cacheList.insert(0, message.data);
    if (cacheList.length > 5) {
      cacheList.removeLast();
    }
    prefs.setString('notification', jsonEncode(cacheList));
  }
}

Future<void> saveChatNotiToSharedPreferenceCache(String _uid) async {
  final prefs = await SharedPreferences.getInstance();
  String _data = prefs.getString('chat') ?? '';

  if (_data == '') {
    prefs.setString('chat', json.encode({_uid: 1}));
  } else {
    Map _numOfNoti = jsonDecode(_data);
    if (_numOfNoti[_uid] == null) {
      _numOfNoti[_uid] = 1;
    } else {
      _numOfNoti[_uid] = _numOfNoti[_uid] + 1;
    }
    print(_numOfNoti);
    prefs.setString('chat', json.encode(_numOfNoti));
  }
}

Future<void> _backgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  developer.log("백그라운드핸들러", name: "체크용");
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  print(message.data['type']);

  if (message.data['type'] == 'receive_chat') {
    print("background 새로운 채팅 도착 : ${message.data}");
    saveChatNotiToSharedPreferenceCache(message.data['uid']);
    // _showNotification(message.data);
  } else if (message.data['type'] == 'video') {
    print("background 새로운 세션 알림 도착 : ${message.data}");
    saveToCache(message);

    // _showNotification(message.data);
  } else {
    saveToCache(message);
  }
  _showNotification(message.data);
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // ignore: cancel_subscriptions
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List _children = [MainView(), SNSView(), ScheduleView(), MyPage()];
  late SharedPreferences prefs;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
    developer.log("Init STATE", name: "APP STATE");

    WidgetsBinding.instance?.addObserver(this);

    _requestPermission(); // ios notification permission
    _initializeLocalNotificationSettings();
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    await Firebase.initializeApp();
    String? token = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh
        .listen(FirebaseMethods().updateTokenToDatabase); // token 바뀌면 서버에 저장하기
    FirebaseMethods().saveTokenToDatabase(token!);
    prefs = await SharedPreferences.getInstance();

    Map<String, int> numOfChat = await checkBgNotiNum();

    Provider.of<UserState>(context, listen: false)
        .numOfChatUpdateByMap(numOfChat);

    initFCMHandlers();

    super.didChangeDependencies();
  }

  void _requestPermission() {
    //iOS - require notification permission
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    //android - do not need notification permission
  }

  Future<Map<String, int>> checkBgNotiNum() async {
    await prefs.reload();

    String? cachedData = prefs.getString('chat');
    Map<String, int> cache = {};
    // 캐시에 저장된거 있을때
    if (cachedData != null) {
      Map _cache = jsonDecode(cachedData);
      _cache.forEach((key, value) {
        cache[key] = value;
      });
      prefs.remove('chat');
    }
    print(cache);
    return cache;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print("APP STATE : RESUMED");
      Map<String, int> numOfChat = await checkBgNotiNum();
      print(numOfChat);
      Provider.of<UserState>(context, listen: false)
          .numOfChatUpdateByMap(numOfChat);
    } else if (state == AppLifecycleState.paused) {
      print("APP STATE: PAUSED");
      await prefs.reload();
      prefs.setString(
          'chat',
          json.encode(
              Provider.of<UserState>(context, listen: false).numOfNewChat));
    }
  }

  //Local Notifciation initialization...
  void _initializeLocalNotificationSettings() {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid = AndroidInitializationSettings(
        'logo'); // 같은 안드로이드 11인데 뭔 뜨고 뭔 안뜸 이렇게 어이없을수가;
    final initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {
          didReceiveLocalNotificationSubject.add(
            ReceivedNotification(
              id: id,
              title: title,
              body: body,
              payload: payload,
            ),
          );
        });

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String? payload) async {
    developer.log("온 셀렉트 잘 들어왔어요", name: "체크용");
    Map<String, dynamic> payloadMap = {};

    // 현재 terminated 된 상태에서 들어올때는 배너 알림 누르고 들어와도 이 함수가 호출이 안됨
    // 기존처럼 remoteMessage 온게 있는지 직접 확인하고 체크해줘야하는 것 같아

    if (payload != null) {
      payloadMap = json.decode(payload);
    }

    if (payloadMap['type'] == 'receive_chat') {
      types.User otherUser = types.User(id: payloadMap['uid']);
      types.Room room = await FirebaseChatCore.instance.createRoom(otherUser);

      UserState _userState = Provider.of<UserState>(context, listen: false);
      // print("PAYLOAD ${payloadMap}");
      String _senderUid = payloadMap['uid'];
      Map _senderToken = json.decode(payloadMap['sender_token']);
      _userState.setChattingView(room, _senderUid, _senderToken);

      _userState.changeStateTo(CHATTING);
      print(_userState.state);
    } else if (payloadMap['type'] == 'video') {
      print('세션 알림 잘 도착했습니다');
    }
  }

  //FCM initialization ...
  Future<void> initFCMHandlers() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // IOS Notification permission setting
    if (Platform.isIOS) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    }

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_foregroundHandler);
  }

  Future<void> _foregroundHandler(RemoteMessage message) async {
    developer.log("포어그라운드 핸들러", name: "체크용");
    print('onMessage: $message');

    if (message.data["type"] == 'video') {
      print("foreground 새로운 세션알림 도착 : ${message.data}");
      saveToCache(message);
      _showNotification(message.data);
    } else if (message.data["type"] == "receive_chat") {
      if (Provider.of<UserState>(context, listen: false).state != CHATTING) {
        print("foreground 새로운 채팅 도착 : ${message.data}");
        Provider.of<UserState>(context, listen: false)
            .newChatIsAdded(message.data['uid']);
        _showNotification(message.data);
      }
    } else {
      saveToCache(message);
      _showNotification(message.data);
    }
    //saveToCache(message); //지난 알림 5개 저장하기
  }

  @override
  dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("HOME BUILD");

    print(Provider.of<CurrentSession>(context, listen: false).onLive);
    final controller = Get.put(Controller());
    return GetBuilder<Controller>(builder: (_) {
      return ChangeNotifierProvider(
          create: (context) => ReservationLists(),
          child: Consumer<UserState>(
            builder: (context, _userState, child) => Consumer<CurrentSession>(
                builder: (context, _sessionInfo, child) => Stack(
                      children: [
                        Scaffold(
                          appBar: AppBar(
                            title: Text("CRAYON 시즌3"),
                          ),
                          body: _children[_.currentIndex],
                          bottomNavigationBar: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            // backgroundColor: HexColor('F7F7F7'),
                            backgroundColor: Colors.white,
                            selectedItemColor: Color(0xffF07B3F),
                            unselectedItemColor:
                                Colors.black54.withOpacity(.60),
                            selectedFontSize: 14,
                            unselectedFontSize: 14,
                            onTap: _.onTabTapped,
                            currentIndex: _.currentIndex,
                            items: [
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.home), label: '홈'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.people), label: '소식'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.schedule), label: '스케쥴'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.person), label: "내 계정"),
                            ],
                            selectedLabelStyle:
                                TextStyle(color: Colors.black87),
                          ),
                        ),
                        if (_userState.state == BOOKLISTVIEW)
                          BookListView(
                              childName: _userState.childName,
                              childUid: _userState.childUid),
                        if (_userState.state == CHATTING)
                          ChatPage(
                              room: _userState.room,
                              FCMToken: _userState.FCMTokens,
                              uid: _userState.childUid),
                        if (_userState.state == PROFILE)
                          ChildProfileView(childInfo: _userState.profileInfo),
                        if (_userState.state == COREADING)
                          ReadBook(
                            sessionInfo: _sessionInfo,
                            userState: _userState,
                            book: _userState.book,
                          ),
                        if (_sessionInfo.onLive)
                          PickUpView(sessionInfo: _sessionInfo)
                      ],
                    )),
          ));
    });
  }
}
