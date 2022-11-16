import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/providers/notification_provider.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:crayon/views/home_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import './views/00_auth/login_view.dart';
import 'models/reviews.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  runApp(App());
}

class App extends StatefulWidget {
  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  Future<bool> _initAuth() async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (docSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ReviewLists>(
              create: (context) => ReviewLists()),
          ChangeNotifierProvider<CurrentUser>(
              create: (context) => CurrentUser()),
          ChangeNotifierProvider<CurrentSession>(
              create: (context) => CurrentSession()),
          ChangeNotifierProvider(create: (context) => FCMMessages()),
          ChangeNotifierProvider(create: (context) => UserState())
        ],
        child: ScreenUtilInit(
            designSize: Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: () => GetMaterialApp(
                title: "Crayon",
                debugShowCheckedModeBanner: false,
                initialRoute: '/',
                theme: ThemeData(
                    fontFamily: 'hope',
                    appBarTheme: AppBarTheme(
                      backgroundColor: Color(
                          0xffF07B3F), //Color.fromARGB(255, 248, 140, 101),
                      //backgroundColor: Colors.white30,
                      iconTheme: IconThemeData(
                        color: Colors.white, //change your color here
                      ),
                      toolbarHeight: 40.0,
                      centerTitle: true,
                    ),
                    primaryColor: Color.fromARGB(255, 248, 140, 101),
                    textTheme: TextTheme(
                        bodyText1:
                            TextStyle(color: Colors.black87, fontSize: 20),
                        bodyText2:
                            TextStyle(color: Colors.black54, fontSize: 15))),
                builder: (context, widget) {
                  ScreenUtil.setContext(context);
                  return MediaQuery(
                    //Setting font does not change with system font size
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                    child: widget!,
                  );
                },
                home: FutureBuilder(
                  // Initialize FlutterFire:
                  future: _initialization,
                  builder: (context, snapshot) {
                    // Check for errors
                    if (snapshot.hasError) {
                      return Text('something has wrong');
                    }

                    // Once complete, show your application
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (FirebaseAuth.instance.currentUser != null) {
                        return FutureBuilder(
                          future: _initAuth(),
                          builder: (context, _authSnapshot) {
                            if (_authSnapshot.connectionState ==
                                ConnectionState.done) {
                              if (_authSnapshot.data == true)
                                return HomeView();
                              else
                                return LogInView();
                            }
                            return Container(
                              color: Colors.white,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        );
                      } else {
                        return LogInView();
                      }
                    }
                    // Otherwise, show something whilst waiting for initialization to complete
                    return Container();
                  },
                ))));
  }
}
