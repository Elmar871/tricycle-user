
import 'package:firebase_auth/firebase_auth.dart';
import 'package:users/models/direction_details_info.dart';

import '../models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String cloudMessagingServerToken = "key=AAAAaOmAvvk:APA91bFZvoDRnFFR_paZo-a3gp7VvHB1INdBx1uQxJ_5aAKyH3ABaECqakok61bU0Irsih9Vptinjwl79O1_W8ERbVc1WWbzj5oQFrv5u4XFrMGg9U3I2BeV5-EB92WiN-HzzwBcRRov";
List driversList =[];
DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDropOffAddress = "";
String driverCarDetails = "";
String driverName = "";
String driverPhone = "";
String driverRatings = "";

double countRatingStars =0.0;
String titleStarsRating = "";