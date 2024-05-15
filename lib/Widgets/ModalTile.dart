import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:flutter/material.dart';
import 'package:echat/Utils/UniversalVariables.dart';

class ModalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Function() onTap;

  const ModalTile(
      {super.key, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return ChatCustomTile(
        leading: Container(
          margin: EdgeInsets.only(right: 10*ScaleUtils.horizontalScale),
          padding: EdgeInsets.all(10*ScaleUtils.scaleFactor),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15*ScaleUtils.scaleFactor),
            color: UniversalVariables.receiverColor
          ),
          child: Icon( icon,color: UniversalVariables.greyColor,size: 38*ScaleUtils.scaleFactor,),
        ),
        title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18*ScaleUtils.scaleFactor
          ),
        ),
        icon: Container(),
        subtitle: Text(subtitle,
          style: TextStyle(
              color: UniversalVariables.greyColor,
              fontSize: 16*ScaleUtils.scaleFactor
          ),
        ),
          trailing: Icon(null),
          margin: EdgeInsets.all(0),
          mini: false,
          onTap: onTap,
          onLongPress: (){}
    );
  }
}
