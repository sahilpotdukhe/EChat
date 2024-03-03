import 'package:echat/Models/OnBoardModel.dart';
import 'package:echat/Screens/LoginScreen.dart';
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
    return Scaffold(
      backgroundColor: (currentIndex%2 ==0 )?Colors.white: Colors.blue,
      appBar: AppBar(
        backgroundColor:(currentIndex%2 ==0 )?Colors.white: Colors.blue,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: () async{
                await _storeOnBoardInfo();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
              },
              child: Text("Skip",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: currentIndex % 2 == 0 ? Colors.blue  : Colors.white,
                ),
              )),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: PageView.builder(
            itemCount: screens.length,
            controller: _pageController,
            // physics: NeverScrollableScrollPhysics(),
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
                  Image.asset(screens[index].image),
                  Text(
                    screens[index].text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: index % 2 == 0 ? Colors.black  : Colors.white,
                    ),
                  ),
                  Text(
                    screens[index].description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontFamily: 'Montserrat',
                      color: index % 2 == 0 ? Colors.black  : Colors.white,
                    ),
                  ),
                  Container(
                    height: 10,
                    child: ListView.builder(
                      itemCount: screens.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context,index){
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              width: currentIndex == index ?25 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: currentIndex == index && currentIndex %2 ==0 ? Colors.blue:Colors.blue[100],
                                  borderRadius: BorderRadius.circular(10)
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
                      _pageController.nextPage(duration: Duration(microseconds: 300), curve: Curves.bounceIn);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30,vertical: 10),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.blue  : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          Text("Next",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: index % 2 == 0 ? Colors.white  : Colors.blue,
                          ),
                          ),
                          SizedBox(width: 15,),
                          Icon(Icons.arrow_forward_sharp,color: index % 2 == 0 ? Colors.white  : Colors.blue,),
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
