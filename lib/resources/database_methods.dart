import 'dart:convert';

import 'package:crayon/configs/server.dart';
import 'package:http/http.dart' as http;

class DatabaseMethods {
  // Request to upload image file to the media server.
  // response.body['file_name'] => Uploaded filename in the server
  Future<http.Response> uploadProfileImage(String _filepath) async {
    String _url = pushServerUrl + "/profile/upload/image";
    var request = new http.MultipartRequest("POST", Uri.parse(_url));
    request.files.add(await http.MultipartFile.fromPath('file', _filepath));

    http.Response response =
        await http.Response.fromStream(await request.send());

    return response;
  }

  Future<http.Response> uploadSNSImage(String _filepath) async {
    String _url = pushServerUrl + "/sns/upload/image";
    var request = new http.MultipartRequest("POST", Uri.parse(_url));
    request.files.add(await http.MultipartFile.fromPath('file', _filepath));

    http.Response response =
        await http.Response.fromStream(await request.send());

    return response;
  }

  Future<http.Response> createProfileInfo(Map _userProfile) async {
    // crayon 서버에게 firebase firestore에 프로필 업데이트
    // Map에 필수 field: 'uid', 'name', 'img', 'phone', 'email', 'FCMToken', 'profileInfo',

    String _url = pushServerUrl + '/profile/create';

    http.Response request = await http.post(
      Uri.parse(_url),
      headers: <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'profile': _userProfile}),
    );
    print(request.body);

    return request;
  }

  Future<http.Response> updateProfileInfo(Map _userProfile) async {
    // crayon 서버에게 firebase firestore에 프로필 업데이트
    // Map에 필수 field: 'uid', 'name', 'img', 'phone', 'email', 'FCMToken', 'profileInfo',

    String _url = pushServerUrl + '/profile/update';

    http.Response request = await http.post(
      Uri.parse(_url),
      headers: <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'profile': _userProfile}),
    );
    print(request.body);

    return request;
  }
}
