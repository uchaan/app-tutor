import 'package:crayon/views/00_auth/register_view.dart';
import 'package:flutter/material.dart';

//For the authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; //google signin
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../home_view.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

class LogInView extends StatelessWidget {
  const LogInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SignInSection();
  }
}

class _SignInSection extends StatefulWidget {
  _SignInSection();

  @override
  State<StatefulWidget> createState() => _SignInSectionState();
}

class _SignInSectionState extends State<_SignInSection> {
  late final FirebaseFirestore firestore;

  final idField = TextEditingController();
  final passwordField = TextEditingController();

  @override
  void initState() {
    firestore = FirebaseFirestore.instance;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 50, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                child: const Text('CRAYON',
                    style:
                        TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold)),
              ),
              Container(
                  alignment: Alignment.center,
                  width: 200,
                  child: Image.asset('assets/lg.png', fit: BoxFit.contain)),
              //logInField(),
              //ElevatedButton(onPressed: () {}, child: Text("로그인")),
              Divider(),
              SignInButton(
                Buttons.GoogleDark,
                onPressed: () async {
                  _signInWithGoogle();
                },
              ),
              SignInButton(
                Buttons.AppleDark,
                onPressed: () async {
                  signInWithApple();
                },
              ),
            ],
          )),
    );
  }

  //Example code of how to sign in with Google.
  Future<void> _signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        var googleProvider = GoogleAuthProvider();
        userCredential = await auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication googleAuth =
            await googleUser!.authentication;
        final googleAuthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await auth.signInWithCredential(googleAuthCredential);
      }

      signInHandler(userCredential);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: $e'),
        ),
      );
    }
  }

  String generateNonce([int length = 32]) {
    final charset = ""; // *security issue*
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);
    var oauthCredential;

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      final clientState = Uuid().v4();
      final url = Uri.https(); // *security issue*

      final result = await FlutterWebAuth.authenticate(
          url: url.toString(), callbackUrlScheme: "applink");

      final body = Uri.parse(result).queryParameters;
      oauthCredential = OAuthProvider("apple.com").credential(
        idToken: body['id_token'],
        accessToken: body['code'],
      );
    } else {
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: "com.nclab.crayon-service",
          redirectUri: Uri.parse(), // *security issue*
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
    }
    print(oauthCredential);

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    signInHandler(userCredential);
  }

  void signInHandler(UserCredential userCredential) {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          print('User is currently signed out!');
        } else {
          print('User is signed in!');
          //Firestore에 등록한 유저인지 확인하기.
          CollectionReference userCollections = firestore.collection('users');
          print(user.uid);
          userCollections
              .doc(user.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) {
            if (documentSnapshot.exists) {
              print("Already Registered");

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeView()),
                ModalRoute.withName(MaterialApp().toString()),
              );
            } else {
              print("Need to register");
              showDialog(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return RegisterView(user: user);
                  });
            }
          });
        }
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Apple: $e'),
        ),
      );
    }
  }

  Widget logInField() {
    return SingleChildScrollView(
        child: Container(
            child: Column(children: [
      SizedBox(height: 10.0),
      TextFormField(
        controller: idField,
        decoration: InputDecoration(
          fillColor: Colors.grey,
          focusColor: Colors.grey,
          labelText: "아이디",
          icon: Icon(Icons.email_rounded),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "아이디를 입력해주세요!";
          } else
            return null;
        },
      ),
      SizedBox(height: 5.0),
      TextFormField(
        controller: passwordField,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: "비밀번호",
          icon: Icon(Icons.password_rounded),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "비밀번호를 입력해주세요!";
          } else
            return null;
        },
      )
    ])));
  }
}
