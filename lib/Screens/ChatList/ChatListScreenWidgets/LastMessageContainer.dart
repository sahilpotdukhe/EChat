import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:flutter/material.dart';

class LastMessageContainer extends StatelessWidget {
  final stream;

  const LastMessageContainer({super.key, this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: stream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            var docList = snapshot.data?.docs;

            if (docList!.isNotEmpty) {
              MessageModel messageModel = MessageModel.fromMap(docList.last.data() as Map<dynamic, dynamic>);
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Text(
                  messageModel.message,
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
