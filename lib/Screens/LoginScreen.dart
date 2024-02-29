import 'package:echat/Resources/AuthMethods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:echat/Widgets/BottomNavigationBar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMethods authMethods = AuthMethods();
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          (isPressed)?
          Center(
              child: Container(
                  child: CircularProgressIndicator()
              )
          )
          :Center(
            child: SizedBox(
              height: 40,
              width: 260,
              child: SignInButton(
                Buttons.GoogleDark,
                text: 'Sign Up with Google',
                onPressed: () async{
                  setState((){
                    isPressed =true;
                  });
                  await authMethods.googleSignIn(context);
                  print("Account Created");
                  // ignore: use_build_context_synchronously
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context){
                        return BotttomNavigationBar();
                      }));
                  setState((){
                    isPressed =false;
                  });
                },
              ),
            ),
          ),
        ],

      ),
    );
  }
}
