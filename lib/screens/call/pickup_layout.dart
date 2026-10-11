import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/screens/call/pickup_screen.dart';
import 'package:echat/widgets/common/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PickupLayout extends StatelessWidget {
  final Widget scaffold;
  final CallMethods callMethods = CallMethods();

  PickupLayout({super.key, required this.scaffold});

  @override
  Widget build(BuildContext context) {
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
        // Shown for a moment at startup while your profile loads.
        : const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandLogo(size: 56, showName: false),
                  SizedBox(height: 24),
                  SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                ],
              ),
            ),
          );
  }
}
