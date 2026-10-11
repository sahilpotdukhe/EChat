import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/screens/call/pickup_screen.dart';
import 'package:echat/utils/scale_utils.dart';
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
    return (userProvider.getUser != null)
        ? StreamBuilder<DocumentSnapshot>(
            stream: callMethods.callStream(uid: userProvider.getUser!.uid),
            builder: (context, snapshot) {
              // e.g. permission error while signing out: just show the app.
              if (snapshot.hasError) return scaffold;
              if (snapshot.hasData && snapshot.data!.data() != null) {
                CallModel callModel = CallModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);
                // Several screens use PickupLayout (home, and a chat pushed on
                // top of it). Only the one on top rings, so a call isn't shown,
                // timed out or logged as missed twice. This rebuilds when the
                // top screen changes, so the call moves with the user.
                final bool onTop = ModalRoute.of(context)?.isCurrent ?? true;
                if (!callModel.hasDialled && onTop) {
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
                  child: Lottie.asset('assets/reload_app.json'),
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
