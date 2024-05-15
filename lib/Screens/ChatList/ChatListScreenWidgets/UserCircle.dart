import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/Widgets/NewUserDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCircle extends StatelessWidget {
  const UserCircle({super.key});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (context)=> NewUserDetails()));
      },
      child: Container(
        height: 40*ScaleUtils.verticalScale,
        width: 40*ScaleUtils.horizontalScale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
            // borderRadius: BorderRadius.circular(50*ScaleUtils.scaleFactor),
            color: Colors.white),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                Utils.getInitials(userProvider.getUser?.name),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UniversalVariables.lightBlueColor,
                    fontSize: 16*ScaleUtils.scaleFactor),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 12*ScaleUtils.verticalScale,
                width: 12*ScaleUtils.horizontalScale,
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

