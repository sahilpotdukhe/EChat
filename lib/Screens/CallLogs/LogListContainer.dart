import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/QuietBox.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:flutter/material.dart';

class LogListContainer extends StatefulWidget {
  const LogListContainer({super.key});

  @override
  State<LogListContainer> createState() => _LogListContainerState();
}

class _LogListContainerState extends State<LogListContainer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: LogRepository.getLogs(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData) {
            List<dynamic> logList = snapshot.data;
            if (logList.isNotEmpty) {
              return ListView.builder(
                  itemCount: logList.length,
                  itemBuilder: (context, index) {
                    CallLogModel callLogModel = logList[index];
                    bool hasDialled = callLogModel.callStatus == "Dialled";
                    return ChatCustomTile(
                        leading: CachedChatImage(
                            imageUrl: (hasDialled)
                                ? callLogModel.receiverPic
                                : callLogModel.callerPic,
                            isRound: true,
                            radius: 50,
                            height: 0,
                            width: 0,
                            fit: BoxFit.cover),
                        title: Text(
                            (hasDialled)
                                ? callLogModel.receiverName
                                : callLogModel.callerName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white)),
                        icon: getIcon(callLogModel.callStatus),
                        subtitle: Text(
                          Utils.formatDateString(callLogModel.timestamp),
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: (callLogModel.callType == "videoCall")
                            ? Icon(
                                Icons.video_call,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.call,
                                color: Colors.white,
                              ),
                        margin: EdgeInsets.all(0),
                        mini: false,
                        onTap: () {},
                        onLongPress: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text("Delete this log"),
                                  content:
                                      Text("Are you sure to delete this log?"),
                                  actions: [
                                    MaterialButton(
                                        child: Text("Yes"),
                                        onPressed: () async {
                                          Navigator.maybePop(context);
                                          await LogRepository.deleteLogs(index);
                                          //It  checks if the widget is mounted before triggering a state update and rebuild.
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        }),
                                    MaterialButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          Navigator.maybePop(context);
                                        })
                                  ],
                                )));
                  });
            }
            return QuietBox(
              screen: "LogListContainer",
            );
          }
          return Text("No call logs");
        });
  }

  getIcon(String callStatus) {
    Icon _icon;
    double _iconSize = 15;

    switch (callStatus) {
      case "Dialled":
        _icon = Icon(
          Icons.call_made,
          size: _iconSize,
          color: Colors.green,
        );
        break;
      case "received":
        _icon = Icon(
          Icons.call_received,
          size: _iconSize,
          color: Colors.grey,
        );
        break;
      default:
        _icon = Icon(
          Icons.call_missed,
          size: _iconSize,
          color: Colors.red,
        );
    }
    return Container(
      margin: EdgeInsets.only(right: 5),
      child: _icon,
    );
  }
}
