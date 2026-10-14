import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/resources/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// started: both call docs written. busy: the server refused because the
/// caller or receiver is already in a call. failed: offline or other error.
enum CallResult { started, busy, failed }

class CallMethods{

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // This will constantly notices that whether there is any call documents are not
  Stream<DocumentSnapshot> callStream({required String uid}){
    return firestore.collection("Call").doc(uid).snapshots();
  }

  Future<CallResult> makeCall({required CallModel callModel}) async{
    Map<String,dynamic> callMap = Map<String,dynamic>.from(callModel.toMap(callModel));
    callMap["created_at"] = FieldValue.serverTimestamp();
    callMap["accepted"] = false;

    // Caller's doc has has_dialled true, receiver's doc has it false.
    // One batch, so either both docs are written or neither is.
    WriteBatch batch = firestore.batch();
    batch.set(firestore.collection("Call").doc(callModel.callerId), {...callMap, "has_dialled": true});
    batch.set(firestore.collection("Call").doc(callModel.receiverId), {...callMap, "has_dialled": false});

    try{
      // Offline, commit() never completes, so give up after 10 seconds.
      await batch.commit().timeout(const Duration(seconds: 10));
      // Rings the receiver's phone if the app isn't open; not awaited.
      NotificationService.notifyCall(receiverId: callModel.receiverId);
      return CallResult.started;
    } on FirebaseException catch(e){
      // The rules refuse to overwrite a call that is still live.
      if (e.code == 'permission-denied') return CallResult.busy;
      debugPrint("makeCall error: $e");
      return CallResult.failed;
    } on TimeoutException {
      // The batch stays queued and would ring the receiver once we're back
      // online, so queue the hang-up right behind it.
      endCall(callModel: callModel);
      return CallResult.failed;
    } catch(e){
      debugPrint("makeCall error: $e");
      return CallResult.failed;
    }
  }

  // Receiver picked up. Either doc may already be gone if the other side
  // hung up, so each update is allowed to fail on its own.
  Future<void> markAccepted({required CallModel callModel}) async{
    await Future.wait([callModel.callerId, callModel.receiverId].map((uid) =>
        firestore.collection("Call").doc(uid).update({"accepted": true})
            .catchError((e) => debugPrint("markAccepted error: $e"))));
  }

  Future<bool> endCall({required CallModel callModel}) async{
    try{
      // Both deletes are queued at once, so offline both still go out later.
      await Future.wait([
        firestore.collection("Call").doc(callModel.callerId).delete(),
        firestore.collection("Call").doc(callModel.receiverId).delete(),
      ]);
      // The caller ended it: silence the receiver's ringing notification.
      // Not awaited; if it fails the notification still stops after 45 s.
      if (FirebaseAuth.instance.currentUser?.uid == callModel.callerId) {
        NotificationService.notifyCallEnded(receiverId: callModel.receiverId);
      }
      return true;
    }catch(e){
      debugPrint('$e');
      return false;
    }
  }
}
