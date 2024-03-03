import 'package:echat/Screens/SearchScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class QuietBox extends StatelessWidget {
  final screen;
  const QuietBox({super.key, this.screen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 35, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text((screen =="ChatScreen")?
                "This is where all contacts are listed":"All the logs will be displayed here",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(height: 25),
              Text((screen =="ChatScreen")?
                "Search for your family and freinds to start calling or chatting with them":"Have a video call with your family and friends to get engage",
                textAlign: TextAlign.center,
                style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: UniversalVariables.lightBlueColor),
                child: Text('Start Searching',style: TextStyle(color: Colors.white),),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchScreen()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
