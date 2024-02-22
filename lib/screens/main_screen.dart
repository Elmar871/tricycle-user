import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:users/Assistants/assistant_methods.dart';
import 'package:users/global/global.dart';
import 'package:users/global/map_key.dart';
import 'package:users/infoHandler/app_info.dart';
import 'package:users/screens/precise_pickup_location.dart';
import 'package:users/screens/rate_driver_screen.dart';
import 'package:users/screens/search_places_screen.dart';

import '../Assistants/geofire_assistant.dart';
import '../models/active_nearby_available_drivers.dart';
import '../models/directions.dart';
import '../splashScreen/splash_screen.dart';
import '../widget/pay_fare_amount_dialog.dart';
import '../widget/progress_dialog.dart';
import 'drawer_screen.dart';

Future<void> _makePhoneCall(String url) async {
  if (await canLaunch(url)){
    await launch(url);
  }
  else{
    throw "Could not launch $url";
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(14.2691, 121.4113),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoOrdinatesList =[];
  Set<Polyline> polyLineSet ={};

  Set<Marker> marketsSet = {};
  Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer =true;

  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  DatabaseReference? referenceRideRequest;

  String selectedVehicleType = "";

  String driverRideStatus ="Driver is coming";
  StreamSubscription<DatabaseEvent> ? tripRidesRequestInfoStreamSubscription;

  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];

  String userRideRequestStatus = "";
  bool requestPositionInfo = true;

  locateUserPosition() async {
    Position cPostion =await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPostion;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoOrdinates(userCurrentPosition!, context);
    print("This is our address = " + humanReadableAddress);

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

     initializeGeoFireListener();
    //
    AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  initializeGeoFireListener(){
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude,10)!
        .listen((map){
      print(map);

      if (map!=null){
        var callBack = map["callBack"];

        switch(callBack){
        //whenever
          case Geofire.onKeyEntered:
            GeoFireAssistant.activeNearByAvailableDriversList.clear();
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude =map["longitude"];
            activeNearByAvailableDrivers.driverId =map["key"];
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            if(activeNearbyDriverKeysLoaded == true){
              displayActiveDriverOnUsersMap();
            }
            break;
    //
        //nonactive
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriverOnUsersMap();
            break;
    //
    //     //moves
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude =map["longitude"];
            activeNearByAvailableDrivers.driverId =map["key"];
            GeoFireAssistant.updateActiveNearByAvailableDriverLocation(activeNearByAvailableDrivers);
            displayActiveDriverOnUsersMap();
            break;

        //display online active
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriverOnUsersMap();
            break;
        }
      }
      setState(() {

      });
    });
  }

  displayActiveDriverOnUsersMap(){
    setState(() {
      marketsSet.clear();
      circlesSet.clear();

      Set<Marker> driversMarketSet = Set<Marker>();

      for (ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarketSet.add(marker);
      }
      setState(() {
        marketsSet = driversMarketSet;
      });
    });
  }

  createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(0.2, 0.2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value){
        activeNearbyIcon = value;
      });
    }
  }


  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async{
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!, destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please Wait .....",),

    );


    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo =directionDetailsInfo;

    });

    Navigator.pop(context);


    PolylinePoints pPoints =PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoOrdinatesList.clear();

    if(decodePolyLinePointsResultList.isNotEmpty){
      decodePolyLinePointsResultList.forEach((PointLatLng pointLatLng){
        pLineCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline =Polyline(
        color: darkTheme? Colors.amberAccent : Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );

      polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if (originLatLng.latitude > destinationLatLng.latitude){
      boundsLatLng =LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      marketsSet.add(originMarker);
      marketsSet.add(destinationMarker);
    });

    Circle originCircle =Circle(
      circleId: CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle =Circle(
      circleId: CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }

  // getAddressFromLatLng() async{
  //   try{
  //     GeoData data = await Geocoder2.getDataFromCoordinates(
  //         latitude: pickLocation!.latitude,
  //         longitude: pickLocation!.longitude,
  //         googleMapApiKey: mapKey
  //     );
  //     setState(() {
  //       Directions userPickUpAddress = Directions();
  //       userPickUpAddress.locationLatitude = pickLocation!.latitude;
  //       userPickUpAddress.locationLongitude = pickLocation!.longitude;
  //       userPickUpAddress.locationName = data.address;
  //
  //       Provider.of<AppInfo> (context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
  //
  //
  //       // _address = data.address;
  //     });
  //   } catch (e){
  //     print(e);
  //   }
  // }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  saveRideRequestInformation(String selectedVehicleType){
    //1. save request
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      // "key: value"
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),

    };
    //
    Map destinationLocationMap = {
      // "key: value"
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),

    };

    Map userInformationMap ={
      "origin" : originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);
    //

    //
    tripRidesRequestInfoStreamSubscription =referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null){
        return;
      }
      if ((eventSnap.snapshot.value as Map)["car_details"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }
      if ((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["ratings"] != null){
        setState(() {
          driverRatings = (eventSnap.snapshot.value as Map)["ratings"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverLocation"] != null){
        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status =accepted
        if (userRideRequestStatus == "accepted"){
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }

        //status Arrived
        if (userRideRequestStatus == "arrived"){
          setState(() {
            driverRideStatus = "Driver has arrived";
          });
        }

        //status onTrip
        if (userRideRequestStatus == "ontrip"){
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        if(userRideRequestStatus =="ended"){
          if ((eventSnap.snapshot.value as Map)["fareAmount"] !=null){
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());
            //
            var response = await showDialog(
              context: context,
              builder: (BuildContext context) => PayFareAmountDialog(
                fareAmount : fareAmount,
              ),
            );

            if (response == "Cash Paid"){
              //user can rate now
              if ((eventSnap.snapshot.value as Map)["driverId"] != null){
                String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
                Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen(
                  assignedDriverId: assignedDriverId,
                )));

                referenceRideRequest!.onDisconnect();
                tripRidesRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }




    });

    onlineNearByAvailableDriversList =GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);

  }

  searchNearestOnlineDrivers(String selectedVehicleType)async{
    if(onlineNearByAvailableDriversList.length == 0){
      //cancel/delete request
      referenceRideRequest!.remove();
      setState(() {
        polyLineSet.clear();
        marketsSet.clear();
        circlesSet.clear();
        pLineCoOrdinatesList.clear();
      },
      );

      Fluttertoast.showToast(msg: "No online nearest Driver Available");
      Fluttertoast.showToast(msg: "Search Again. \n Restarting App");

      Future.delayed(Duration(milliseconds: 4000),(){
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("Driver List: " + driversList.toString());

    for(int i =0; i< driversList.length; i++){
      if (driversList[i]["car_details"]["type"] == selectedVehicleType){
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"],referenceRideRequest!.key!,context);

      }
    }
    Fluttertoast.showToast(msg: "Notification sent Successfully");

    showSearchingForDriversContainer();

    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot){
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if (eventRideRequestSnapshot.snapshot.value != null){
        if(eventRideRequestSnapshot.snapshot.value !="waiting"){
          showUIForAssignedDriverInfo();
        }
      }
    });
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng)async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(
          userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantMethods
          .obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng, userPickUpPosition,
      );

      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        driverRideStatus = "Driver is coming: " +
            directionDetailsInfo.distance_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async{
    if (requestPositionInfo ==true){
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context,listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation.locationLongitude!
      );

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
          driverCurrentPositionLatLng,
          userDestinationPosition
      );

      if (directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Going Towards Destination: "+ directionDetailsInfo.duration_text.toString();
      });
      requestPositionInfo = true;
    }
  }

  showUIForAssignedDriverInfo(){
    setState(() {
      waitingResponsefromDriverContainerHeight=0;
      searchLocationContainerHeight=0;
      assignedDriverInfoContainerHeight=200;
      suggestedRidesContainerHeight=0;
      bottomPaddingOfMap=200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList)async{
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for (int i =0; i< onlineNearestDriversList.length; i++){
      await ref.child(onlineNearestDriversList[i].driverId.toString()).once().then((dataSnapshot){
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver key information = " + driversList.toString());
      });
    }

  }

  void showSearchingForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight=200;

    });
  }




  void showSuggestedRidesContainer(){
    setState(() {
      suggestedRidesContainerHeight=400;
      bottomPaddingOfMap = 400;

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkIfLocationPermissionAllowed();
  }


  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    createActiveNearByDriverIconMarker();

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      //button ng location
      child: Scaffold(
        key:_scaffoldState,
        drawer: DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polyLineSet,
              markers: marketsSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller){
                _controllerGoogleMap.complete(controller);
                newGoogleMapController =controller;
                setState(() {

                });
                locateUserPosition();
              },
            //   onCameraMove: (CameraPosition? position){
            //     if (pickLocation != position!.target){
            //       setState(() {
            //         pickLocation = position.target;
            //       });
            //     }
            //   },
            //   onCameraIdle: (){
            //     getAddressFromLatLng();
            //   },
             ),
            // Align(
            //   alignment: Alignment.center,
            //   child: Padding(
            //     padding: const EdgeInsets.only(bottom: 35),
            //     child: Image.asset("images/pick.png", height: 45,width: 45,),
            //   ),
            // ),

            //custom hamburger button
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  onTap: (){
                    _scaffoldState.currentState!.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: darkTheme? Colors.black : Colors.lightBlue,
                    ),
                  ),
                ),
              ),
            ),

            //ui for searching
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                    padding: EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                      SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("From",
                                            style: TextStyle(
                                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(Provider.of<AppInfo>(context).userPickUpLocation != null
                                              ? (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 15)+ "...."
                                              : "Not Getting Address",
                                            style: TextStyle(color: Colors.grey, fontSize: 14),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5,),

                                Padding(
                                  padding:EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onTap: () async {
                                      //search places screen
                                      var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen()));

                                      if (responseFromSearchScreen == "obtainedDropoff"){
                                        setState(() {
                                          openNavigationDrawer = false;
                                        });
                                      }

                                      await drawPolyLineFromOriginToDestination(darkTheme);


                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("To",
                                              style: TextStyle(
                                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(Provider.of<AppInfo>(context).userDropOffLocation != null
                                                ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                                : "Where to?",
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),

                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 5,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => PrecisePickUpScreen()));


                                },
                                child: Text(
                                  "Change Pick Up \n Address",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    )
                                ),
                              ),

                              SizedBox(width: 10,),

                              ElevatedButton(
                                onPressed: (){
                                  if (Provider.of<AppInfo>(context, listen: false ).userDropOffLocation != null){
                                    showSuggestedRidesContainer();
                                  }
                                  else {
                                    Fluttertoast.showToast(msg: "Please select Destination location");
                                  }
                                },
                                child: Text(
                                  "Show Fare",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    )
                                ),
                              ),

                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            //ui for searching
            Positioned(
              left: 0,
              right: 0,
              bottom: 5,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    )
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(width: 10,),

                            Text(
                              Provider.of<AppInfo>(context).userPickUpLocation != null
                                  ?(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0,15)+ "..."
                                  : "Pickup",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),

                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.black,
                              ),
                            ),

                            SizedBox(width: 10,),

                            Text(
                              Provider.of<AppInfo>(context).userDropOffLocation != null
                                  ?(Provider.of<AppInfo>(context).userDropOffLocation!.locationName!)
                                  : "Where to?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2,),

                        Text("Suggested Rides",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 20,),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: (){
                                setState(() {
                                  selectedVehicleType ="Tricycle";
                                },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedVehicleType == "Tricycle" ? (darkTheme ? Colors.amber.shade400 : Colors.blue): (darkTheme ? Colors.black54 : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(0.5),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Column(
                                    children: [
                                      Image.asset("images/car.png",scale: 3,),
                                      SizedBox(height: 1,),

                                      Text(
                                        "Tricycle \n (Solo)",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: selectedVehicleType == "Tricycle" ? (darkTheme ? Colors.black : Colors.white):(darkTheme ? Colors.white :Colors.black),
                                        ),
                                      ),

                                       // SizedBox(height: 0,),

                                      Text(
                                        tripDirectionDetailsInfo != null ? "₱ ${((AssistantMethods.calculatedFareAmountFromOriginToDestination(tripDirectionDetailsInfo!)).toStringAsFixed(1))}"
                                            : "null",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // GestureDetector(
                            //   onTap: (){
                            //     setState(() {
                            //       selectedVehicleType ="CNG";
                            //     });
                            //   },
                            //   child: Container(
                            //     decoration: BoxDecoration(
                            //       color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.amber.shade400 : Colors.blue): (darkTheme ? Colors.black54 : Colors.grey[100]),
                            //       borderRadius: BorderRadius.circular(0.5),
                            //     ),
                            //     child: Padding(
                            //       padding: EdgeInsets.all(10.0),
                            //       child: Column(
                            //         children: [
                            //           Image.asset("images/car.png",scale: 2 ,),
                            //           //SizedBox(height: 30,),
                            //
                            //           Text(
                            //             "Tricycle \n Max of 4",
                            //             style: TextStyle(
                            //               fontSize: 18,
                            //               fontWeight: FontWeight.bold,
                            //               color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.black : Colors.white):(darkTheme ? Colors.white :Colors.black),
                            //             ),
                            //           ),
                            //
                            //           // SizedBox(height: 10,),
                            //
                            //           Text(
                            //             tripDirectionDetailsInfo != null ? "₱ ${((AssistantMethods.calculatedFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 1.5) * 107).toStringAsFixed(1)}"
                            //                 : "null",
                            //             style: TextStyle(
                            //               fontSize: 18,
                            //               color: Colors.black,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            // GestureDetector(
                            //   onTap: (){
                            //     setState(() {
                            //       selectedVehicleType ="Bike";
                            //     },
                            //     );
                            //   },
                            //   child: Container(
                            //     decoration: BoxDecoration(
                            //       color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.amber.shade400 : Colors.blue): (darkTheme ? Colors.black54 : Colors.grey[100]),
                            //       borderRadius: BorderRadius.circular(0.5),
                            //     ),
                            //     child: Padding(
                            //       padding: EdgeInsets.all(10.0),
                            //       child: Column(
                            //         children: [
                            //           Image.asset("images/car.png",scale: 3,),
                            //           SizedBox(height: 30,),
                            //
                            //           Text(
                            //             "Bike",
                            //             style: TextStyle(
                            //               fontWeight: FontWeight.bold,
                            //               color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.black : Colors.white):(darkTheme ? Colors.white :Colors.black),
                            //             ),
                            //           ),
                            //
                            //           SizedBox(height: 20,),
                            //
                            //           Text(
                            //             tripDirectionDetailsInfo != null ? "₱ ${((AssistantMethods.calculatedFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 0.8) * 107).toStringAsFixed(1)}"
                            //                 : "null",
                            //             style: TextStyle(
                            //               color: Colors.grey,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        SizedBox(height: 20,),

                        Expanded(
                          child: GestureDetector(
                            onTap: (){
                              if (selectedVehicleType != ""){
                                saveRideRequestInformation(selectedVehicleType);
                              }
                              else {
                                Fluttertoast.showToast(msg: "Please select a vehicle from \n suggested rides");
                              }

                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: Text(
                                  "Request a Ride",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10,),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Center(
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),

                         SizedBox(height: 10,),
                      ],
                  ),
                ),
              ),
            ),

            //Requesting a ride
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                      SizedBox(height: 10,),

                      Center(
                        child: Text(
                          "Searching for a driver...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),

                      GestureDetector(
                        onTap: (){
                          referenceRideRequest!.remove();

                          setState(() {
                            searchingForDriverContainerHeight=0;
                            suggestedRidesContainerHeight =0;
                          });
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1, color: Colors.grey)
                          ),
                          child: Icon(Icons.close, size: 25,),
                        ),
                      ),

                      SizedBox(height: 15,),

                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),


            //UI for displaying assigned driver information
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: assignedDriverInfoContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(driverRideStatus, style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 5,),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      SizedBox(height: 5,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.person,color: darkTheme ? Colors.black : Colors.white,),
                              ),
                              SizedBox(width: 10,),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driverName, style: TextStyle(fontWeight: FontWeight.bold),),

                                  Row(children: [
                                    Icon(Icons.star, color: Colors.orange,),

                                    SizedBox(width: 5,),

                                    Text(driverRatings,
                                      style: TextStyle(
                                        color: Colors.grey
                                      ),
                                    )
                                  ],
                                  )

                                ],
                              )
                            ],
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,

                            children: [
                              Image.asset("images/car.png", scale: 3,),
                              
                              Text(driverCarDetails, style: TextStyle(fontSize: 12),),
                            ],
                          )
                        ],
                      ),

                      SizedBox(height: 2,),
                        Divider(thickness: 1, color: darkTheme? Colors.grey : Colors.grey[300],),
                      ElevatedButton.icon(
                          onPressed: (){
                            _makePhoneCall("tel: ${driverPhone} ");
                          },
                          style: ElevatedButton.styleFrom(primary: darkTheme ? Colors.amber.shade400 : Colors.blue),
                          icon: Icon(Icons.phone),
                          label: Text("Call Driver"),
                      ),
                    ],
                  ),

                ),
              ),

            )







            // Positioned(
            //   top: 40,
            //   right: 20,
            //   left: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.black),
            //       color: Colors.white,
            //     ),
            //     padding: EdgeInsets.all(20),
            //     child: Text(
            //     Provider.of<AppInfo>(context).userPickUpLocation != null
            //         ? (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)+ "...."
            //         : "Not Getting Address",
            //     overflow: TextOverflow.visible, softWrap: true,
            //     ),
            //
            //   ),
            // ),

          ],
        ),
      ),
    );
  }
}
