import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../global/global.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key : key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();

  DatabaseReference userRef=FirebaseDatabase.instance.ref().child("users");

  Future<void> showUserNameDialogAlert(BuildContext context, String name){

    nameTextEditingController.text=name;

    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Cancel",style: TextStyle(color: Colors.black),),
              ),
              TextButton(
                onPressed: (){
                  userRef.child(firebaseAuth.currentUser!.uid).update({
                    "name": nameTextEditingController.text.trim(),
                  }).then((value){
                    nameTextEditingController.clear();
                    Fluttertoast.showToast(msg: "Update Succesfully.\n Reload the apps to see the change");
                  }).catchError((errorMessage){
                    Fluttertoast.showToast(msg: "Error Occurred. \n $errorMessage");
                  });

                  Navigator.pop(context);
                },
                child: Text("Ok",style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        }
        );
  }
  Future<void> showUserPhoneDialogAlert(BuildContext context, String phone){

    phoneTextEditingController.text=phone;

    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: phoneTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text("Cancel",style: TextStyle(color: Colors.black),),
              ),
              TextButton(
                onPressed: (){
                  userRef.child(firebaseAuth.currentUser!.uid).update({
                    "phone": phoneTextEditingController.text.trim(),
                  }).then((value){
                    phoneTextEditingController.clear();
                    Fluttertoast.showToast(msg: "Update Succesfully.\n Reload the apps to see the change");
                  }).catchError((errorMessage){
                    Fluttertoast.showToast(msg: "Error Occured. \n $errorMessage");
                  });

                  Navigator.pop(context);
                },
                child: Text("Ok",style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        }
   );
  }
  Future<void> showUserAddressDialogAlert(BuildContext context, String address){

    addressTextEditingController.text=address;

    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: addressTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text("Cancel",style: TextStyle(color: Colors.black),),
              ),
              TextButton(
                onPressed: (){
                  userRef.child(firebaseAuth.currentUser!.uid).update({
                    "address": addressTextEditingController.text.trim(),
                  }).then((value){
                    addressTextEditingController.clear();
                    Fluttertoast.showToast(msg: "Update Succesfully.\n Reload the apps to see the change");
                  }).catchError((errorMessage){
                    Fluttertoast.showToast(msg: "Error Occured. \n $errorMessage");
                  });

                  Navigator.pop(context);
                },
                child: Text("Ok",style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        }
    );
  }




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
          title: Text("Profile Screen", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Center(child: Padding(
          padding: EdgeInsets.fromLTRB(29, 20, 20, 50),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_search_outlined,color: Colors.white,),
              ),

              SizedBox(height: 30,),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Name: ${userModelCurrentInfo!.name!}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                  ),

                  // IconButton(
                  //     onPressed: (){
                  //       showUserNameDialogAlert(context, userModelCurrentInfo!.name!);
                  //     },
                  //     icon: Icon(
                  //       Icons.edit,
                  //     )
                  // ),
                ],
              ),


            Divider(
              thickness: 1,
            ),
              SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Contact Number: ${userModelCurrentInfo!.phone!}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),

                // IconButton(
                //     onPressed: (){
                //       showUserPhoneDialogAlert(context, userModelCurrentInfo!.phone!);
                //     },
                //     icon: Icon(
                //       Icons.edit,
                //     )
                // ),
              ],
            ),


            Divider(
              thickness: 1,
            ),
              SizedBox(height: 30,),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Address: ${userModelCurrentInfo!.address!}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),

                // IconButton(
                //     onPressed: (){
                //       showUserAddressDialogAlert(context, userModelCurrentInfo!.address!);
                //     },
                //     icon: Icon(
                //       Icons.edit,
                //     )
                // ),
              ],
            ),

            Divider(
              thickness: 1,
            ),
              SizedBox(height: 30,),

            Row(
              children: [
                Text("Email: ${userModelCurrentInfo!.email!}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
              Divider(
                thickness: 1,
              ),
              SizedBox(height: 30,),

          ],
        ),
      ),
      ),
      ),
    );
  }
}
