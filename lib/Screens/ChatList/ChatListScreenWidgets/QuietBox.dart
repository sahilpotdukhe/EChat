import 'package:echat/Screens/SearchScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class QuietBox extends StatelessWidget {
  const QuietBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Container(
          color: UniversalVariables.separatorColor,
          padding: EdgeInsets.symmetric(vertical: 35, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This is where all contacts are listed",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(height: 25),
              Text(
                "Search for your family and freinds to start calling or chatting with them",
                textAlign: TextAlign.center,
                style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: UniversalVariables.lightBlueColor),
                child: Text('Start Searching'),
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
