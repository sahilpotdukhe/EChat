import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Screens/Call/PickupScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PickupLayout extends StatelessWidget {
  final Widget scaffold;
  final CallMethods callMethods = CallMethods();

  PickupLayout({super.key, required this.scaffold});

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    return (userProvider != null && userProvider.getUser != null)
        ? StreamBuilder<DocumentSnapshot>(
        stream: callMethods.callStream(uid: userProvider.getUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.data() != null) {
            CallModel callModel = CallModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
            if (!callModel.hasDialled) {
              return PickupScreen(callModel: callModel);
            }
          }
          return scaffold;
        }
    ):Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.green,),
      ),
    );
  }
}
