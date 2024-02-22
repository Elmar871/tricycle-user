import 'dart:async';

import 'package:flutter/material.dart';
import 'package:users/screens/main_screen.dart';

import '../Assistants/assistant_methods.dart';
import '../global/global.dart';
import '../screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}): super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  startTimer() async {
    if (firebaseAuth.currentUser != null) {
      //await firebaseAuth.currentUser != null ? AssistantMethods.readCurrentOnlineUserInfo(): null;
      await firebaseAuth.currentUser != null ? AssistantMethods.readCurrentOnlineUserInfo(): null;
      // await AssistantMethods.readOnlineDriverCarInfo();
      // await AssistantMethods.readOnTripInformation();
      Timer(Duration(seconds: 7), () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
      });
    }
    else {
      Timer(Duration(seconds: 7), () {
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => LoginScreen()));

      }

      );
    }
  }

  @override
  void initState(){
    super.initState();

    startTimer();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Pasada Apps',
          style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}


// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:users/Assistants/assistant_methods.dart';
// import 'package:users/global/global.dart';
// import 'package:users/screens/login_screen.dart';
// import 'package:users/screens/main_screen.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//
//   startTimer(){
//     Timer(Duration(seconds: 3),()async{
//       if(await firebaseAuth.currentUser != null){
//         firebaseAuth.currentUser != null ? AssistantMethods.readCurrentOnlineUserInfo() : null;
//         Navigator.push(context, MaterialPageRoute(builder: (c) =>LoginScreen()));
//       }
//     });
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//
//     startTimer();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text(
//           'Trippo',
//           style: TextStyle(
//             fontSize: 40,
//             fontWeight: FontWeight.bold
//           ),
//         ),
//       ),
//     );
//   }
// }
