import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/enum/UserState.dart';
import 'package:flutter/material.dart';

class OnlineDotIndicator extends StatelessWidget {
  final String uid;
  OnlineDotIndicator({super.key, required this.uid});

  final AuthMethods authMethods = AuthMethods();
  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    getColor(int state){
      switch(Utils.numToState(state)){
        case UserState.Offline:
          return Colors.orange;
        case UserState.Online:
          return Colors.green;
        default:
          return Colors.red;
      }
    }
    return StreamBuilder(
        stream: authMethods.getUserStream(uid: uid),
        builder: (context, snapshot) {
          UserModel? userModel;

          if (snapshot.hasData && snapshot.data?.data() != null) {
            userModel = UserModel.fromMap(snapshot.data?.data() as Map<String, dynamic>);

            return Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 12*ScaleUtils.verticalScale,
                width: 12*ScaleUtils.horizontalScale,
                margin: EdgeInsets.only(right: 8*ScaleUtils.horizontalScale, top: 8*ScaleUtils.verticalScale),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getColor(userModel.state)
                ),
              ),
            );
          }
          return Center(child: CircularProgressIndicator(),);
        }


    );
  }
}
