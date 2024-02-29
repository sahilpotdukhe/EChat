import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/Widgets/UserDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCircle extends StatelessWidget {
  const UserCircle({super.key});

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return GestureDetector(
      onTap: () {
         showModalBottomSheet(
            context: context,
             builder: (context) => UserDetails(),
             backgroundColor: UniversalVariables.blackColor,
              isScrollControlled: true,
         );
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: UniversalVariables.separatorColor),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                Utils.getInitials(userProvider.getUser?.name),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UniversalVariables.lightBlueColor,
                    fontSize: 13),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: UniversalVariables.blackColor, width: 2),
                    color: UniversalVariables.onlineDotColor),
              ),
            )
          ],
        ),
      ),
    );
  }
}

