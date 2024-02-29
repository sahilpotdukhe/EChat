import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/CallLogs/LogListContainer.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/UserCircle.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class CallLogsScreen extends StatelessWidget {
  const CallLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: UniversalVariables.blackColor,
        appBar: CustomAppBar(
            title: UserCircle(),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/searchScreen');
                },
              )
            ],
            leading: IconButton(
              icon: Icon(Icons.notifications),
              color: Colors.white,
              onPressed: () {},
            ),
            centerTitle: true
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 15),
          child: LogListContainer(),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: UniversalVariables.fabGradient
              ),
              child:Icon(
                Icons.dialpad,
                color: Colors.white,
                size: 25,
              ),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UniversalVariables.blackColor,
                  border: Border.all(width: 2,color: UniversalVariables.gradientColorEnd)
              ),
              child:Icon(
                Icons.add_call,
                color: UniversalVariables.gradientColorEnd,
                size: 25,
              ),
            )
          ],
        ),
      );
  }
}
