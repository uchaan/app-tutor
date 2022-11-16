// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import '../../resources/chat/flutter_firebase_chat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hexcolor/hexcolor.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
    required this.room,
    required this.FCMToken,
    required this.uid,
  }) : super(key: key);

  final types.Room room;
  final Map FCMToken;
  final String uid;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _myUid = FirebaseAuth.instance.currentUser!.uid;
  String _otherUid = '';
  String _otherName = '';
  int _myUserNumber = 0;
  int _otherUserNumber = 0;
  late StreamSubscription _streamSubscription;
  late bool otherUserActive;

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  void _handleSendPressed(types.PartialText message) {
    Map chatMap = {};
    chatMap['sender_name'] =
        Provider.of<CurrentUser>(context, listen: false).name; // my
    chatMap['sender_uid'] =
        Provider.of<CurrentUser>(context, listen: false).uid;
    chatMap['sender_fcm_token'] =
        Provider.of<CurrentUser>(context, listen: false).FCMToken;
    chatMap['receiver_fcm_token'] = widget.FCMToken; // 상대방 token
    chatMap['receiver_uid'] = widget.uid; //상대방 uid
    chatMap['message'] = message.text;

    print(chatMap);

    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
      chatMap,
    );

    //when send message -> when other User is not active -> recievedNewMessage = true
    if (!otherUserActive) {
      firestore
          .collection("rooms")
          .doc(widget.room.id)
          .update({'user${_otherUserNumber}_receivedNewMessage': true})
          .then((value) => print("userState updated"))
          .catchError((error) => print("failed to update userState: $error"));
    }
  }

  @override
  void initState() {
    _otherUid = _myUid == widget.room.users[0].id
        ? widget.room.users[1].id
        : widget.room.users[0].id;
    _myUserNumber = _myUid == widget.room.users[0].id ? 1 : 2;
    _otherUserNumber = _myUid == widget.room.users[0].id ? 2 : 1;

    print("INIT CHAT VIEW");

    FirebaseFirestore.instance
        .collection('users')
        .doc(_otherUid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        //set child name to review
        Map<String, dynamic> data =
            documentSnapshot.data()! as Map<String, dynamic>;
        _otherName = data['name'].toString();
      } else {
        print('Document does not exist on the database');
      }
    });

    // print('_otherUid: $_otherUid');
    // print('_userNumber: $_myUserNumber');

    //when enter the room, update my userState
    firestore
        .collection("rooms")
        .doc(widget.room.id)
        .update({
          'user${_myUserNumber}_active': true,
          'user${_myUserNumber}_receivedNewMessage': false,
        })
        .then((value) => print("userState updated"))
        .catchError((error) => print("failed to update userState: $error"));

    //open stream subscription to other user's activity
    Stream documentStream =
        firestore.collection('rooms').doc(widget.room.id).snapshots();
    _streamSubscription = documentStream.listen((data) {
      otherUserActive = data['user${_otherUserNumber}_active'];
      print('otherUserActive: $otherUserActive');
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    Provider.of<UserState>(context, listen: false)
        .deleteNewChatEntity(_otherUid);
    print(Provider.of<UserState>(context, listen: false).numOfNewChat);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    print("leave chat");

    //I am no longer active in the room
    firestore
        .collection("rooms")
        .doc(widget.room.id)
        .update({
          'user${_myUserNumber}_active': false,
        })
        .then((value) => print("userState updated"))
        .catchError((error) => print("failed to update userState: $error"));
    //cancel stream subscription
    _streamSubscription.cancel();
    super.dispose();
  }

  Future<void> getOtherUserInfo() async {
    _otherUid = _myUid == widget.room.users[0].id
        ? widget.room.users[1].id
        : widget.room.users[0].id;
    _myUserNumber = _myUid == widget.room.users[0].id ? 1 : 2;
    _otherUserNumber = _myUid == widget.room.users[0].id ? 2 : 1;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_otherUid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data()! as Map<String, dynamic>;
        _otherName = data['name'].toString();
      } else {
        print('Document does not exist on the database');
      }
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: getOtherUserInfo(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator());
          } else {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () {
                    Provider.of<UserState>(context, listen: false)
                        .changeStateTo(NAVIGATION);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                // systemOverlayStyle: SystemUiOverlayStyle.light,
                title: Text(_otherName),
              ),
              backgroundColor: HexColor('F7F7F7'),
              body: StreamBuilder<types.Room>(
                initialData: widget.room,
                stream: FirebaseChatCore.instance.room(widget.room.id),
                builder: (context, snapshot) {
                  return StreamBuilder<List<types.Message>>(
                    initialData: const [],
                    stream: FirebaseChatCore.instance.messages(snapshot.data!),
                    builder: (context, snapshot) {
                      return SafeArea(
                        bottom: false,
                        child: Chat(
                          // isAttachmentUploading: _isAttachmentUploading,
                          messages: snapshot.data ?? [],
                          // onAttachmentPressed: _handleAtachmentPressed,
                          // onMessageTap: _handleMessageTap,
                          onPreviewDataFetched: _handlePreviewDataFetched,
                          onSendPressed: _handleSendPressed,
                          user: types.User(
                            id: FirebaseChatCore.instance.firebaseUser?.uid ??
                                '',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
        });
  }
}
