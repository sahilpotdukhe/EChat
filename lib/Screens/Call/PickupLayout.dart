import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Screens/Call/PickupScreen.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class PickupLayout extends StatelessWidget {
  final Widget scaffold;
  final CallMethods callMethods = CallMethods();

  PickupLayout({super.key, required this.scaffold});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    return (userProvider != null && userProvider.getUser != null)
        ? StreamBuilder<DocumentSnapshot>(
            stream: callMethods.callStream(uid: userProvider.getUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.data() != null) {
                CallModel callModel = CallModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);
                if (!callModel.hasDialled) {
                  return PickupScreen(callModel: callModel);
                }
              }
              return scaffold;
            })
        : Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to\n EChat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32*ScaleUtils.scaleFactor,
                      fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins'
                  ),
                ),
                Center(
                  child: Lottie.asset('assets/reloadApp.json'),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20*ScaleUtils.scaleFactor),
                    color: HexColor("3957ED"),
                  ),
                  child: Padding(
                    padding:  EdgeInsets.fromLTRB(18.0*ScaleUtils.horizontalScale, 8*ScaleUtils.verticalScale, 18*ScaleUtils.horizontalScale, 8*ScaleUtils.verticalScale),
                    child: Text(
                      "Get Started",
                      style: TextStyle(fontSize: 18*ScaleUtils.scaleFactor, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
