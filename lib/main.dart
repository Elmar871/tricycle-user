import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users/infoHandler/app_info.dart';
import  'package:users/screens/forgot_password_screen.dart';
import 'package:users/screens/login_screen.dart';
import 'package:users/screens/main_screen.dart';
import 'package:users/screens/rate_driver_screen.dart';
import 'package:users/screens/register_screen.dart';
import 'package:users/screens/search_places_screen.dart';
import 'package:users/splashScreen/splash_screen.dart';
import 'package:users/themeProvider/theme_provider.dart';
import 'package:users/widget/pay_fare_amount_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Platform.isAndroid
      ? await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyATL-AeQjVJZalFRh9qC88w6KD6TmFGBSg",
      appId: "1:450594127609:android:93287d585b887371c7ec28",
      messagingSenderId: "450594127609",
      projectId: "trippo-9b658",
    ),

  )
      : await Firebase.initializeApp();
  runApp(const MyApp());
}
  // runApp(const MyApp());
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter Demo',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
      ),
    );
  }
}


