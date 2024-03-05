import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class ChatQuietBox extends StatelessWidget {
  final screen;
  const ChatQuietBox({super.key, this.screen});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 100,),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  (screen=="ChatScreen")?Image.asset('assets/chatscreen.png'):Image.asset('assets/search.jpg'),
                  Text(
                    (screen=="ChatScreen")?"No Message":"Search",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                  ),
                  SizedBox(height: 10),
                  Text(
                    (screen=="ChatScreen")?"Transform silence into connection,\nExplore video calls, voice calls, image and video sharing, and more."
                        :"Discover, connect, and chat with friends and family,Search for connections, and let the conversations begin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                        fontSize: 16),
                  ),
                  SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: UniversalVariables.appThemeColor),
                    child: Text('Search',style: TextStyle(color: Colors.white),),
                    onPressed: (){
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchScreen()));
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
