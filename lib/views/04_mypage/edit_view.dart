import 'dart:convert';
import 'dart:io';

import 'package:crayon/configs/path.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/resources/database_methods.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class EditView extends StatefulWidget {
  const EditView({Key? key}) : super(key: key);

  @override
  _EditViewState createState() => _EditViewState();
}

class _EditViewState extends State<EditView> {
  late final CurrentUser _user;
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

  String img = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _user = Provider.of<CurrentUser>(context, listen: false);
    img = _user.img;

    super.didChangeDependencies();
  }

  Map<String, dynamic> getProfileMap() {
    Map<String, dynamic> _userProfile = {};
    _userProfile['uid'] = _user.uid;
    _userProfile['name'] = nameField.text;
    _userProfile['img'] = img;
    _userProfile['phone'] = phoneField.text;
    _userProfile['email'] = _user.email;
    _userProfile['FCMToken'] = _user.FCMToken;
    _userProfile['group'] = 'tutor';
    _userProfile['blocked'] = _user.blocked;
    _userProfile['profileInfo'] = {
      'hobby': hobbyField.text,
      'grader': gradeField.text,
      'job': jobField.text,
      'school': schoolField.text,
      'major': majorField.text,
      'like': likeField.text,
      'dislike': dislikeField.text,
    };
    return _userProfile;
  }

  Future<void> buttonHandler() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        http.Response response =
            await DatabaseMethods().uploadProfileImage(_imageFile!.path);
        if (response.statusCode == 200) {
          String _fName = json.decode(response.body)['file_name'];
          img = PROFILE_PATH + '/' + _fName;
          print(img);
        } else {
          final snackBar =
              SnackBar(content: Text("인터넷 연결이 불안정합니다. 다시 시도해주세요."));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return;
        }
      }

      Map<String, dynamic> userProfile = getProfileMap();
      http.Response response =
          await DatabaseMethods().updateProfileInfo(userProfile);

      if (response.statusCode == 200) {
        Provider.of<CurrentUser>(context, listen: false)
            .updateUserInfoFromMap(userProfile);
        Navigator.pop(context);
      } else {
        final snackBar = SnackBar(content: Text("인터넷 연결이 불안정합니다. 다시 시도해주세요."));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      final snackBar = SnackBar(content: Text("다시 입력해주세요."));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
          title: Text("정보수정"),
        ),
        backgroundColor: HexColor('F7F7F7'),
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
                padding: EdgeInsets.all(10.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                            left: 10, top: 10, bottom: 10),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Icon(Icons.motion_photos_on_outlined, color: Colors.green,), // motion_phones_on
                            Text('내 정보 수정',
                                style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            SizedBox(
                              width: 3,
                            ),
                            Icon(
                              Icons.account_circle_rounded,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                      Card(
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatefulBuilder(builder: (context, setState) {
                                    return imageProfile();
                                  }),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput("이름", "홍길동", nameField,
                                          "text", "이름을 입력하세요", _user.name),
                                      SizedBox(width: 10),
                                      textFieldInput(
                                          "핸드폰",
                                          "01055559999",
                                          phoneField,
                                          "phone",
                                          "번호를 입력하세요",
                                          _user.phone),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput(
                                          "소속학교",
                                          "카이스트",
                                          schoolField,
                                          "text",
                                          "소속을 입력하세요",
                                          _user.profileInfo['school']),
                                      SizedBox(width: 10),
                                      textFieldInput(
                                          "직업",
                                          "대학생",
                                          jobField,
                                          "text",
                                          "직업 항목이 비어있습니다.",
                                          _user.profileInfo['job']),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      textFieldInput(
                                          "전공",
                                          "컴퓨터공학",
                                          majorField,
                                          "text",
                                          "전공 항목이 비어있습니다.",
                                          _user.profileInfo['major']),
                                      SizedBox(width: 10),
                                      textFieldInput(
                                          "학년",
                                          "3학년/석사3년차",
                                          gradeField,
                                          "text",
                                          "학년을 입력해주세요.",
                                          _user.profileInfo['grader']),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      textFieldInput(
                                          "자신있는것",
                                          "고기굽기",
                                          likeField,
                                          "text",
                                          "해당칸을 입력해주세요",
                                          _user.profileInfo['like']),
                                      SizedBox(width: 10),
                                      textFieldInput(
                                          "자신없는것",
                                          "노래부르기",
                                          dislikeField,
                                          "text",
                                          "해당칸을 입력해주세요",
                                          _user.profileInfo['dislike']),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: hobbyField
                                      ..text = _user.profileInfo['hobby'],
                                    decoration: InputDecoration(
                                        labelText: "취미",
                                        hintText: "육식맨 채널 보고 고기요리 따라하기"),
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return "취미를 입력해주세요.";
                                      else
                                        return null;
                                    },
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.only(top: 20),
                                    child: FractionallySizedBox(
                                      widthFactor:
                                          0.4, // means 100%, you can change this to 0.8 (80%)
                                      child: ElevatedButton(
                                        onPressed: buttonHandler,
                                        style: ElevatedButton.styleFrom(
                                            primary: Colors.black,
                                            shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        10.0)),
                                            padding: EdgeInsets.all(3)),
                                        child: Text("저장",
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ],
                              ))),
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
              ? NetworkImage(img) as ImageProvider
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
      String textOption, String errorMsg, String initialString) {
    Map options = {'phone': TextInputType.phone, 'text': TextInputType.text};
    return Flexible(
      flex: 1,
      child: TextFormField(
        controller: field..text = initialString,
        decoration: InputDecoration(
          labelText: name,
          hintText: hint,
        ),
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

    setState(() {
      _imageFile = _pickedFile;
    });
  }
}
