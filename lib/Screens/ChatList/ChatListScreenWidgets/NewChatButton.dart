import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return InkWell(
      onTap: (){
        Navigator.pushNamed(context, '/searchScreen');
      },
      child: Container(
        decoration: BoxDecoration(
            gradient: UniversalVariables.appGradient,
            borderRadius: BorderRadius.circular(50*ScaleUtils.scaleFactor)),
        padding: EdgeInsets.all(16*ScaleUtils.scaleFactor),
        child:  Icon(
          Icons.chat,
          color: Colors.white,
          size: 26*ScaleUtils.scaleFactor,
        ),
      ),
    );
  }
}
