import 'dart:async';
import 'dart:convert';

import 'package:agora_uikit/agora_uikit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Screens/ChatList/ChatListScreen.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class AudioCallScreen extends StatefulWidget {
  final CallModel callModel;

  const AudioCallScreen({super.key, required this.callModel});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late CallMethods callMethods;
  late StreamSubscription callStreamSubscription;
  late final AgoraClient _client;
  bool _isLoading= true;
  late String tempToken;
  //late String channelId;

  @override
  void initState() {
    // TODO: implement initState
    callMethods = CallMethods();
    getToken();
    super.initState();
    addPostFrameCallBack();
    // _initAgora();

  }

  Future<void> getToken() async{
    String channelId = widget.callModel.channelId;
    //String tokenUrlLink= "https://a0966c8a-6017-4dda-a316-dd97ae4e2dc7-00-2br8taujkm5yo.pike.replit.dev/access_token?channelName=test";
    String tokenUrlLink= "https://agoratokenserver-ny1v.onrender.com/access_token?channelName=${channelId}";
    Response _response = await get(Uri.parse(tokenUrlLink));
    if(_response.statusCode == 200){
      final data = json.decode(_response.body);
      setState(() {
        tempToken = (data["token"]).toString();
      });
      print('Token fetched: $tempToken');
    } else {
      print('Error fetching token: ${_response.statusCode}');
    }
    _client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
            appId: '3a5f9bfe0efa423e9eaf5447565e0f7b',
            tempToken: tempToken,
            channelName:  channelId
        ));
    // Initialize Agora after obtaining the token
    _initAgora();
    // Future.delayed(Duration(seconds: 1)).then((value) =>
    setState((){
      _isLoading= false;
    });
    // );
  }
  Future<void> _initAgora() async {
    try {
      await _client.initialize();
      // await _client.engine.setChannelProfile(ChannelProfile.communication);
      await _client.engine.disableVideo();
      // await _client.engine.enableAudio();
      print('Agora client initialized successfully');
    } catch (e) {
      print('Error initializing Agora: $e');
      // Handle initialization error, such as displaying an error message to the user
    }
  }

//Line 84 sets up a subscription to a stream of data. It calls the callStream method from callMethods with the uid parameter obtained from the userProvider. This method likely
// returns a stream of data related to calls. The .listen method is then used to listen to events emitted by the stream. Whenever a new event (in this case, a DocumentSnapshot) is received,
// the provided callback function is called.
  addPostFrameCallBack() {
    // This means that the callback function passed to addPostFrameCallback will be invoked after the UI has been rendered and displayed on the screen.
    SchedulerBinding.instance.addPostFrameCallback((_) {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

      callStreamSubscription = callMethods.callStream(uid: userProvider.getUser!.uid).listen((DocumentSnapshot documentSnapshot) {
      print('Received call stream event: $documentSnapshot');
      switch (documentSnapshot.data()) {
      case null:
      Navigator.pop(context);
      break;
      default:
      break;
      }
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // Cancel the call stream subscription
    callStreamSubscription.cancel();
    // Dispose of the Agora client
    _client.engine.leaveChannel();
    //_client.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Audio Call'),
        ),
        body: SafeArea(
          child: (_isLoading)?
          Center(child: CircularProgressIndicator()):
          Stack(
            children: [
              AgoraVideoViewer(
                showAVState: true,
                disabledVideoWidget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container( 
                      width: 120*ScaleUtils.horizontalScale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30*ScaleUtils.scaleFactor,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/user.jpg'),
                            foregroundImage: NetworkImage(widget.callModel.callerPic),
                          ),
                          SizedBox(height: 5*ScaleUtils.verticalScale,),
                          Text(widget.callModel.callerName,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,maxLines:2,style: TextStyle(fontSize: 20*ScaleUtils.scaleFactor,fontWeight: FontWeight.bold),)
                        ],
                      ),
                    ),
                    SizedBox(width: 20*ScaleUtils.horizontalScale,),
                    Container(
                      width: 120*ScaleUtils.horizontalScale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30*ScaleUtils.scaleFactor,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/user.jpg'),
                            foregroundImage: NetworkImage(widget.callModel.receiverPic),
                          ),
                          SizedBox(height: 5*ScaleUtils.verticalScale,),
                          Text(widget.callModel.receiverName,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,maxLines:2,style: TextStyle(fontSize: 20*ScaleUtils.scaleFactor,fontWeight: FontWeight.bold),)
                        ],
                      ),
                    )
                  ],
                ),
                client: _client,
                layoutType: Layout.grid,
                showNumberOfUsers: true,

              ),
              AgoraVideoButtons(
                client: _client,
                disconnectButtonChild: IconButton(
                  onPressed: () async{
                    await _client.engine.leaveChannel();
                    await _client.engine.release();
                    endCall(context,widget.callModel);
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.call_end,color: Colors.red,),
                ),
                enabledButtons: const [
                  BuiltInButtons.toggleMic,
                  BuiltInButtons.callEnd,
                ],
              ),
            ],
          ),
        )
    );
  }

  void endCall(BuildContext context, CallModel callModel) {
    callMethods.endCall(callModel: widget.callModel);
  }

}
