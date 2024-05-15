import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastMessageContainer extends StatelessWidget {
  final stream;
  final position;

  const LastMessageContainer({super.key, this.stream, this.position});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return StreamBuilder(
        stream: stream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            var docList = snapshot.data?.docs;

            if (docList!.isNotEmpty) {
              MessageModel messageModel = MessageModel.fromMap(docList.last.data() as Map<dynamic, dynamic>);
              Timestamp date = messageModel.timestamp;
              DateTime datenew = date.toDate();
              String time = DateFormat.jm().format(datenew);
              return SizedBox(
                width:  (position == "subtitle")?MediaQuery.of(context).size.width -170*ScaleUtils.horizontalScale:60*ScaleUtils.horizontalScale,
                child: Text(
                  (position == "subtitle")? messageModel.message: time ,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              );
            }
            return Text(
              "No message",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            );
          }
          return Text("..", style: TextStyle(color: Colors.grey, fontSize: 14));
        });
  }
}
