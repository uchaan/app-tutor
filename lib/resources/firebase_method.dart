import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/resources/device_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseMethods {
  // //message format: REQUEST, DECLINE, DESTROY, ACCEPT
  // Future<http.Response> sendFCMMessage(Map callMap, String message) async {
  //   callMap['token'] = callMap['caller_token'];
  //   final response = await http.post(
  //     Uri.parse(pushServerUrl + message),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(callMap),
  //   );

  //   return response;
  // }

  Future<void> updateTokenToDatabase(String token) async {
    // Assume user is logged in for this example
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String deviceUID = await getDeviceUniqueId();

    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot userSnap = await userDocRef.get();
    Map<String, dynamic> tokens = (userSnap.data() as Map)['FCMToken'];

    tokens[deviceUID] = token;
    await userDocRef.update({
      'FCMToken': tokens,
    });

    print(tokens);
  }

  Future<void> saveTokenToDatabase(String token) async {
    // Assume user is logged in for this example
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String deviceUID = await getDeviceUniqueId();
    print("UID: $deviceUID");
    print("FCMTOKEN: $token");

    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot userSnap = await userDocRef.get();
    Map<String, dynamic> tokens = (userSnap.data() as Map)['FCMToken'];

    if (tokens[deviceUID] == null || tokens[deviceUID] != token) {
      tokens[deviceUID] = token;
      userDocRef.update({
        'FCMToken': tokens,
      });
    }
  }
}
