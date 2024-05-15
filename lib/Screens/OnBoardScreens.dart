import 'dart:math';

import 'package:echat/Models/OnBoardModel.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardScreens extends StatefulWidget {
  const OnBoardScreens({super.key});

  @override
  State<OnBoardScreens> createState() => _OnBoardScreensState();
}

class _OnBoardScreensState extends State<OnBoardScreens> {
  int currentIndex = 0;
  late PageController _pageController =PageController();

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  _storeOnBoardInfo() async{
    int isViewed = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("OnBoard", isViewed);
  }

  List<OnBoardModel> screens = <OnBoardModel>[
    OnBoardModel(
      image: 'assets/first.png',
      text: "Chat anytime, anywhere",
      description:"Passing of any information on any screen, any device instantly is made simple at its sublime",
    ),
    OnBoardModel(
      image: 'assets/second.png',
      text: "Perfect chat solution",
      description:"Welcome to our chat app! Join our community effortlessly and enjoy personalized profiles, enhanced messaging features, and limitless connections. Let's start chatting!"
    ),
    OnBoardModel(
      image: 'assets/third.png',
      text: "Your space in your dream",
      description: "A lag-free video chat connection between your users is easy and much everywhere on any device",
    ),
  ];
  @override
  Widget build(BuildContext context) {
    // double height = MediaQuery.of(context).size.height;
    // double width = MediaQuery.of(context).size.width;
    // var verticalScale = height / mockUpHeight;
    // var horizontalScale = width / mockUpWidth;
    // // Calculate the scale factor based on the smaller dimension
    // double scaleFactor = max(horizontalScale,verticalScale);
    ScaleUtils.init(context);
    return Scaffold(
      backgroundColor: (currentIndex%2 ==0 )?Colors.white: UniversalVariables.appThemeColor,
      appBar: AppBar(
        backgroundColor:(currentIndex%2 ==0 )?Colors.white: UniversalVariables.appThemeColor,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: () async{
                await _storeOnBoardInfo();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
              },
              child: Text("Skip",
                style: TextStyle(
                  fontSize: 20.0*ScaleUtils.scaleFactor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: currentIndex % 2 == 0 ? UniversalVariables.appThemeColor  : Colors.white,
                ),
              )),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: ScaleUtils.horizontalScale*20),
        child: PageView.builder(
            itemCount: screens.length,
            controller: _pageController,
            onPageChanged: (int index){
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (_, index){
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(screens[index].image,height: 360*ScaleUtils.verticalScale,width: 366*ScaleUtils.horizontalScale,),
                  Text(
                    screens[index].text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25.0*ScaleUtils.scaleFactor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: index % 2 == 0 ? Colors.black  : Colors.white,
                    ),
                  ),
                  Text(
                    screens[index].description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16*ScaleUtils.scaleFactor,
                      fontFamily: 'Montserrat',
                      color: index % 2 == 0 ? Colors.black  : Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 10*ScaleUtils.verticalScale,
                    child: ListView.builder(
                      itemCount: screens.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context,index){
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 3*ScaleUtils.horizontalScale),
                              width: currentIndex == index ?20*ScaleUtils.horizontalScale : 8*ScaleUtils.horizontalScale,
                              height: 8*ScaleUtils.verticalScale,
                              decoration: BoxDecoration(
                                  color: currentIndex == index && currentIndex %2 ==0 ? UniversalVariables.appThemeColor:Colors.blue[200],
                                  borderRadius: BorderRadius.circular(10*ScaleUtils.scaleFactor)
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () async{
                      if(index == screens.length -1 ){
                        await _storeOnBoardInfo();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
                      }
                      _pageController.nextPage(duration: Duration(microseconds: 500), curve: Curves.bounceIn);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24*ScaleUtils.horizontalScale,vertical: 10*ScaleUtils.verticalScale),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? UniversalVariables.appThemeColor  : Colors.white,
                        borderRadius: BorderRadius.circular(15*ScaleUtils.scaleFactor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          Text((index == screens.length -1 )?"Finish":"Next",
                          style: TextStyle(
                            fontSize: 16.0*ScaleUtils.scaleFactor,
                            color: index % 2 == 0 ? Colors.white  : UniversalVariables.appThemeColor,
                          ),
                          ),
                          SizedBox(width: 9*ScaleUtils.horizontalScale,),
                          Icon(Icons.arrow_forward_sharp,color: index % 2 == 0 ? Colors.white  : UniversalVariables.appThemeColor,),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }
        ),
      )
    );
  }
}
