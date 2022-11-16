import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/views/99_session/thank_you.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../configs/AppID.dart';

import 'package:http/http.dart' as http;
import 'package:crayon/configs/server.dart';

import 'package:wakelock/wakelock.dart';

import 'dart:developer' as developer;

class PickUpView extends StatefulWidget {
  final CurrentSession sessionInfo;
  const PickUpView({Key? key, required this.sessionInfo}) : super(key: key);

  @override
  _PickUpViewState createState() => _PickUpViewState();
}

class _PickUpViewState extends State<PickUpView> {
  //User? user = FirebaseAuth.instance.currentUser;
  String currentUid = FirebaseAuth.instance.currentUser!.uid;

  late String _token;
  late RtcEngine _engine;
  bool _muted = false;
  int _uid = -1; //user id 뭘로 받아오지?
  bool pipMode = false;
  int localUid = 0; // 로컬유저의 uid
  bool isFloating = false;

  final _infoStrings = [];

  //PIP VIEW 좌표
  double _x = 10;
  double _y = 10;

  @override
  void initState() {
    Wakelock.enable();

    print("PICK UP VIEW");
    initAgoraSetup();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _x = 10;
    _y = 10;
    super.didChangeDependencies();
    this.widget.sessionInfo.updateTutorConnected();

    // ToDO: update 되는지 확인
  }

  @override
  void dispose() {
    print("PICK UP VIEW DISPOSED");
    this.widget.sessionInfo.updateTutorConnected();

    _engine.leaveChannel();
    _engine.destroy();

    Wakelock.disable();
    super.dispose();
  }

  // Init the app
  Future<void> initAgoraSetup() async {
    // get token from the server
    await getToken();

    //get the permission of camera & mic
    await [
      Permission.camera,
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request();

    // Create RTC client instance
    _engine = await RtcEngine.create(appID);

    // Define event handling logic
    _addAgoraEventHandler();
    // Enable video
    await _engine.enableVideo();
    // set Audio quality better
    await _engine.setAudioProfile(
        AudioProfile.MusicHighQualityStereo, AudioScenario.Education);

    // Join channel with channel name as _channelName
    await _engine.joinChannelWithUserAccount(
        _token, this.widget.sessionInfo.channelId, currentUid);
    await _engine.setEnableSpeakerphone(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: this.widget.sessionInfo.pipMode
            ? pipVideoCall()
            : generalVideoCall());
  }

  Widget pipVideoCall() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return Positioned(
        top: _x,
        left: _y,
        height: _height / 4,
        width: _width / 4,
        child: GestureDetector(
          onTap: () => this.widget.sessionInfo.pipModeUpdate(),
          child: Draggable(
            child: Scaffold(
              body: isLandscape ? _viewColumns() : _viewRows(),
            ),
            feedback: SizedBox(
              height: _height / 4,
              width: _width / 4,
              child: Container(color: Colors.blueGrey),
            ),
            childWhenDragging: Scaffold(
              body: isLandscape ? _viewColumns() : _viewRows(),
            ),
            onDragEnd: (_detail) {
              setState(() {
                _x = _detail.offset.dy;
                _y = _detail.offset.dx;
              });
            },
          ),
        ));
  }

  Widget pipButton() {
    return Positioned(
      top: 30,
      right: 120,
      width: 40,
      height: 40,
      child: FloatingActionButton(
        onPressed: () {
          this.widget.sessionInfo.pipModeUpdate();
        },
        child: Icon(Icons.auto_stories_rounded, size: 25),
        shape: CircleBorder(),
        elevation: 2.0,
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Widget generalVideoCall() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return Positioned(
        top: 0,
        left: 0,
        height: _height,
        width: _width,
        child: Scaffold(
            body: Stack(
          children: <Widget>[
            isLandscape ? _viewColumns() : _viewRows(),
            pipButton(),
            _toolbar(),
          ],
        )));
  }

  // Get token from the token server
  Future<void> getToken() async {
    final response = await http.post(
      Uri.parse(pushServerUrl + '/agora/token'),
      headers: <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'uid': currentUid,
        'channel_name': this.widget.sessionInfo.channelId,
        'role': 3,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _token = response.body;
        _token = jsonDecode(response.body)['token'];
      });
    } else {
      print('Failed to fetch the token');
    }
  }

  void _addAgoraEventHandler() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('joinChannelSuccess $channel $uid');
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
        localUid = uid;
        developer.log("local 참가 uid $localUid", name: "fHandler:");
      });
    }, leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _uid = -1;
      });
    }, userJoined: (int uid, int elapsed) {
      print('userJoined $uid');
      setState(() {
        _startRecording();
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _uid = uid;
        developer.log("remote 참가 uid $_uid", name: "fHandler:");
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      // print('userOffline $uid');
      setState(() {
        final info = "userOfflineL: $uid, reason: $reason";
        _infoStrings.add(info);
        _uid = -1;
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideoFrame: $uid';
        _infoStrings.add(info);
      });
    }));
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];

    // 전화걸었을때 상대방 안들어왔어도 내 사진 바로 보여주기위한 조건문
    // 이거 없으면 화면을 한번 회전하거나 책버튼 눌러야 카메라가 제대로 나옴.
    if (localUid == 0) {
      return [
        Center(
            child: SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator()))
      ];
    }

    list.add(RtcLocalView.SurfaceView());
    developer.log("local uid 가 잘 들어왔나요? $localUid", name: "fHandler:");
    // list.add(RtcRemoteView.SurfaceView(uid: localUid));
    if (_uid != -1) {
      list.add(RtcRemoteView.SurfaceView(uid: _uid));
    }

    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, width: 0.5)),
            child: Column(
              children: <Widget>[
                _videoView(views[0]),
                Expanded(
                    child: !this.widget.sessionInfo.pipMode
                        ? Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Text(
                                  "잠시만 기다려주세요",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                    "${this.widget.sessionInfo.childName}을 기다리는 중입니다."),
                                Text("3분 이상 늦을 경우 운영자에게 연락해주세요"),
                                SizedBox(
                                  height: 40,
                                )
                              ]))
                        : Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator())))
              ],
            ));
      case 2:
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, width: 0.5)),
            child: Column(
              children: <Widget>[
                _expandedVideoRow([views[0]]),
                _expandedVideoRow([views[1]])
              ],
            ));
      default:
    }
    return Container();
  }

  /// Video layout wrapper
  Widget _viewColumns() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, width: 0.5)),
            child: Row(
              children: <Widget>[
                _videoView(views[0]),
                Expanded(
                    child: !this.widget.sessionInfo.pipMode
                        ? Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Text(
                                  "잠시만 기다려주세요",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                    "${this.widget.sessionInfo.childName}기 아직 접속하지 않았습니다"),
                                Text("3분 이상 늦을 경우 운영자에게 연락해주세요"),
                              ]))
                        : Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator())))
              ],
            ));
      case 2:
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, width: 0.5)),
            child: Row(
              children: <Widget>[
                _expandedVideoRow([views[0]]),
                _expandedVideoRow([views[1]])
              ],
            ));
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThankYouView()),
    );
    this.widget.sessionInfo.offLive();
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  Future<void> _startRecording() async {
    final response = await http.post(
        Uri.parse(pushServerUrl + '/agora/start-cloud-recording'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'tutor_name': this.widget.sessionInfo.tutorName,
          'student_name': this.widget.sessionInfo.childName,
          "channel_name": this.widget.sessionInfo.channelId,
        }));

    if (response.statusCode == 200) {
      print('Recording Started');
    } else {
      print('Couldn\'t start the recording : ${response.statusCode}');
    }
  }
}
