import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:users/global/global.dart';
import 'package:users/screens/forgot_password_screen.dart';
import 'package:users/screens/login_screen.dart';
import 'package:users/screens/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final confirmTextEditingController = TextEditingController();

  bool _passwordVisible = false;

  //declare global key
  final _formKey = GlobalKey<FormState>();

  void _submit ()async{
    //validate your field
    if(_formKey.currentState!.validate()){
      await firebaseAuth.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim()
      ).then((auth) async{
        currentUser = auth.user;

        if (currentUser != null){
          Map userMap ={
            "id" : currentUser!.uid,
            "name": nameTextEditingController.text.trim(),
            "email": emailTextEditingController.text.trim(),
            "address": addressTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),
            "blockStatus": "yes",

          };
          DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
          userRef.child(currentUser!.uid).set(userMap);
        }
        await Fluttertoast.showToast(msg: "Successfully Registered");
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }).catchError((errorMessage){
        Fluttertoast.showToast(msg: "Error Occured: \n $errorMessage");
      });
    }
    else{
      Fluttertoast.showToast(msg: "Not all field are valid");
    }
  }




  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
        child: Scaffold(
          body: ListView(
            padding:  EdgeInsets.all(0),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.asset(darkTheme ? 'images/logo.png' : "images/logo.png"),

                    SizedBox(height: 5,),

                    Text(
                      'Register',
                      style: TextStyle(
                        color: darkTheme ?  Colors.amber.shade400 : Colors.blue,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                  decoration: InputDecoration(
                                    hintText: "Name",
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,
                                      )
                                    ),
                                    prefixIcon: Icon(Icons.person, color: darkTheme ? Colors.amber.shade400 : Colors.grey,)
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text == null || text.isEmpty){
                                      return 'Name can\'t be empty';
                                    }
                                    if (text.length < 2){
                                      return "Please Enter a Valid Name";
                                    }
                                    if (text.length > 49){
                                      return "Name can\'t be more than 50";
                                    }
                                  },
                                  onChanged: (text) => setState(() {
                                    nameTextEditingController.text =text;
                                  }),

                                ),
                                SizedBox(height: 20,),

                                TextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(100)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.email, color: darkTheme ? Colors.amber.shade400 : Colors.grey,)
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text == null || text.isEmpty){
                                      return 'Email can\'t be empty';
                                    }
                                    if (EmailValidator.validate(text) == true){
                                      return null;
                                    }
                                    if (text.length < 2){
                                      return "Please Enter a Valid email";
                                    }
                                    if (text.length > 99){
                                      return "Email can\'t be more than 100";
                                    }
                                  },
                                  onChanged: (text) => setState(() {
                                    emailTextEditingController.text =text;
                                  }),

                                ),
                                SizedBox(height: 20,),

                                IntlPhoneField(
                                  showCountryFlag: false,
                                  dropdownIcon: Icon(
                                    Icons.arrow_drop_down,
                                    color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                                  ),
                                  decoration: InputDecoration(
                                      hintText: "Phone Number",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )
                                      ),
                                  ),
                                  initialCountryCode: 'PH',
                                  onChanged: (text) => setState(() {
                                    phoneTextEditingController.text =text.completeNumber;
                                  }),


                                ),
                                TextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(100)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Address",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.location_city, color: darkTheme ? Colors.amber.shade400 : Colors.grey,)
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text == null || text.isEmpty){
                                      return 'Address can\'t be empty';
                                    }
                                    if (text.length < 2){
                                      return "Please Enter a Valid Address";
                                    }
                                    if (text.length > 99){
                                      return "Address can\'t be more than 100";
                                    }
                                  },
                                  onChanged: (text) => setState(() {
                                    addressTextEditingController.text =text;
                                  }),

                                ),
                                SizedBox(height: 20,),

                                TextFormField(
                                  obscureText: !_passwordVisible,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.lock, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                        color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                                      ),
                                      onPressed: (){
                                        //update Toggle password
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    )
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text == null || text.isEmpty){
                                      return 'Password can\'t be empty';
                                    }
                                    if (text.length < 6){
                                      return "Please Enter a Valid Password";
                                    }
                                    if (text.length > 49){
                                      return "Password can\'t be more than 50";
                                    }
                                    return null;
                                  },
                                  onChanged: (text) => setState(() {
                                    passwordTextEditingController.text =text;
                                  }),

                                ),
                                SizedBox(height: 20,),

                                TextFormField(
                                  obscureText: !_passwordVisible,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Confirm Password",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.lock, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                                        ),
                                        onPressed: (){
                                          //update Toggle password
                                          setState(() {
                                            _passwordVisible = !_passwordVisible;
                                          });
                                        },
                                      )
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text == null || text.isEmpty){
                                      return 'Confirm Password can\'t be empty';
                                    }
                                    if (text!= passwordTextEditingController.text){
                                      return "Password do not match";
                                    }
                                    if (text.length < 6){
                                      return "Please Enter a Valid Password";
                                    }
                                    if (text.length > 49){
                                      return "Confirm Password can\'t be more than 50";
                                    }
                                    return null;
                                  },
                                  onChanged: (text) => setState(() {
                                    confirmTextEditingController.text =text;
                                  }),

                                ),
                                SizedBox(height: 20,),

                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                      onPrimary: darkTheme ? Colors.black : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      minimumSize: Size(double.infinity, 50),
                                    ),
                                    onPressed: (){
                                      _submit();
                                    },

                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    )
                                ),

                                SizedBox(height: 20,),

                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (c) => ForgotPasswordScreen()));
                                  },
                                  child: Text(
                                    'Forgot Password',
                                    style: TextStyle(
                                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20,),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Have an Account?",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(width: 5,),

                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                                      },
                                      child: Text(
                                        "Sign in",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                        ),
                                      ),
                                    )
                                  ],
                                )

                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),

        ),
    );
  }
}
