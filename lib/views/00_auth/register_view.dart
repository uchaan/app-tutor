import 'dart:convert';
import 'dart:io';

import 'package:crayon/configs/path.dart';
import 'package:crayon/constants/strings.dart';
import 'package:crayon/resources/database_methods.dart';
import 'package:crayon/resources/device_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home_view.dart';
import 'package:http/http.dart' as http;

enum Role { TUTOR, STUDENT }

class RegisterView extends StatefulWidget {
  final User user;
  const RegisterView({Key? key, required this.user}) : super(key: key);

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final phoneField = TextEditingController();
  final schoolField = TextEditingController();
  final majorField = TextEditingController();
  final jobField = TextEditingController();
  final hobbyField = TextEditingController();
  final gradeField = TextEditingController();
  final likeField = TextEditingController();
  final dislikeField = TextEditingController();
  //final introField = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _imgUrl = PROFILE_PATH + "/default.png";

  /// 프로필 사진, 이름, 생년월일,

  Future<Map<String, dynamic>> getProfileMap(User user) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Device id token for FCM
    String? token = await messaging.getToken();

    var data = Map<String, dynamic>();
    data['uid'] = user.uid;
    data['name'] = nameField.text;
    data['phone'] = phoneField.text;
    data['email'] = user.email;
    data['FCMToken'] = {await getDeviceUniqueId(): token};
    data['status'] = CALL_STATE_IDLE; // #idle, inSession통화중, 전화거는중, 전화기다리는중
    data['group'] = 'tutor';
    data['blocked'] = [];
    data['profileInfo'] = {
      'hobby': hobbyField.text,
      'grader': gradeField.text,
      'job': jobField.text,
      'school': schoolField.text,
      'major': majorField.text,
      'like': likeField.text,
      'dislike': dislikeField.text,
    };
    data['img'] = _imgUrl;

    print(data);

    // if (_role == Role.TUTOR) {
    //   data['group'] = "tutor";
    // } else
    //   data['group'] = 'student';

    return data;
  }

  Future<void> buttonHandler() async {
    String msg = '';
    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        http.Response response = await DatabaseMethods()
            .uploadProfileImage(_imageFile!.path); //server에 profile 이미지 업로드 요청
        String _fName = json.decode(response.body)['file_name'];
        if (response.statusCode == 200) {
          _imgUrl = PROFILE_PATH + '/' + _fName;
        }
      }

      Map profileMap = await getProfileMap(widget.user);
      http.Response response = await DatabaseMethods()
          .createProfileInfo(profileMap); // server에 db 생성 요청
      if (response.statusCode == 200) {
        msg = "정상적으로 등록되었습니다.";
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeView()),
          ModalRoute.withName(MaterialApp().toString()),
        );
      }
    } else
      msg = "다시 입력해주세요.";

    final snackBar = SnackBar(
      content: Text(msg),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return;
  }

  @override
  void dispose() {
    nameField.dispose();
    phoneField.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("회원가입"),
        ),
        backgroundColor: Colors.blueGrey,
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
                padding: EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Card(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Container(
                                  child: headingText("◇ 프로필 정보를 입력해주세요 ◇"),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Text(
                                    "아이들과 빨리 친해질 수 있도록 자신을 소개해주세요. 적어주신 내용은 아이스브레이킹 때 아이에게 제공됩니다. 해당 내용은 추후에 '내 정보' 탭에서 수정 가능합니다."),
                              ],
                            )),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Card(
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  headingText("사진 등록"),
                                  SizedBox(height: 10),
                                  imageProfile(),
                                  SizedBox(height: 10),
                                  headingText("정보 입력"),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput("이름", "홍길동", nameField,
                                          "text", "이름을 입력하세요"),
                                      SizedBox(width: 10),
                                      textFieldInput("핸드폰", "01055559999",
                                          phoneField, "phone", "번호를 입력하세요"),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput("소속학교", "카이스트",
                                          schoolField, "text", "소속을 입력하세요"),
                                      SizedBox(width: 10),
                                      textFieldInput("직업", "대학생", jobField,
                                          "text", "직업 항목이 비어있습니다."),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      textFieldInput("전공", "컴퓨터공학", majorField,
                                          "text", "전공 항목이 비어있습니다."),
                                      SizedBox(width: 10),
                                      textFieldInput("학년", "3학년/석사3년차",
                                          gradeField, "text", "학년을 입력해주세요."),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput("자신있는것", "고기굽기", likeField,
                                          "text", "해당칸을 입력해주세요"),
                                      SizedBox(width: 10),
                                      textFieldInput("자신없는것", "노래부르기",
                                          dislikeField, "text", "해당칸을 입력해주세요"),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: hobbyField,
                                    decoration: InputDecoration(
                                        labelText: "취미",
                                        hintText: "육식맨 채널 보고 고기요리 따라하기"),
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return "취미를 입력해주세요.";
                                      else
                                        return null;
                                    },
                                  )
                                ],
                              ))),
                      Container(
                        padding: EdgeInsets.all(20),
                        child: FractionallySizedBox(
                          widthFactor:
                              0.8, // means 100%, you can change this to 0.8 (80%)
                          child: ElevatedButton(
                            onPressed: buttonHandler,
                            style: ElevatedButton.styleFrom(
                                shape: new RoundedRectangleBorder(
                                    borderRadius:
                                        new BorderRadius.circular(50.0)),
                                padding: EdgeInsets.all(3)),
                            child: Text("제출", style: TextStyle(fontSize: 25)),
                          ),
                        ),
                      ),
                    ]))));
  }

  Widget headingText(String str) {
    return Text(str,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));
  }

  Widget imageProfile() {
    return Center(
        child: Stack(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: _imageFile == null
              ? AssetImage('assets/lg.png') as ImageProvider
              : FileImage(File(_imageFile!.path)),
        ),
        Positioned(
            bottom: 0,
            left: 0,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                    context: context, builder: ((builder) => bottomSheet()));
              },
              child: Container(
                  width: 140,
                  color: Color.fromARGB(162, 255, 255, 255),
                  child:
                      Icon(Icons.change_circle, color: Colors.grey, size: 35)),
            ))
      ],
    ));
  }

  Widget bottomSheet() {
    return Container(
        height: 100,
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('사진을 선택해주세요', style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton.icon(
                        onPressed: () async {
                          await takePhoto(ImageSource.camera);
                        },
                        icon: Icon(Icons.camera, size: 40),
                        label: Text("카메라")),
                    TextButton.icon(
                        onPressed: () async {
                          await takePhoto(ImageSource.gallery);
                        },
                        icon: Icon(Icons.photo_rounded, size: 40),
                        label: Text("앨범")),
                  ])
            ],
          ),
        ));
  }

  Widget textFieldInput(String name, String hint, TextEditingController field,
      String textOption, String errorMsg) {
    Map options = {'phone': TextInputType.phone, 'text': TextInputType.text};
    return Flexible(
      flex: 1,
      child: TextFormField(
        controller: field,
        decoration: InputDecoration(labelText: name, hintText: hint),
        validator: (value) {
          if (value!.isEmpty) {
            return errorMsg;
          } else
            return null;
        },
        keyboardType: options[textOption],
      ),
    );
  }

  Future<void> takePhoto(ImageSource source) async {
    final XFile? _pickedFile =
        await _picker.pickImage(source: source, maxWidth: 300);
    print(_pickedFile!.path);

    setState(() {
      _imageFile = _pickedFile;
    });
    if (_imageFile == null) print("null...");
  }
}
