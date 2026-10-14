import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:echat/models/call_log_model.dart';
import 'package:echat/resources/interfaces/call_log_interface.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

// Hive stores data in the form of key value pairs
class HiveMethods implements CallLogInterface {
  String hiveBox = ""; //a storage container

  @override
  void openDb(String dbName) => hiveBox = dbName;

  @override
  Future<void> init() async {
    Directory dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }


  @override
  Future<void> addLogs(CallLogModel callLogModel) async {
    await init();
    var box = await Hive.openBox(hiveBox);
    var logMap = callLogModel.toMap(callLogModel);
    await box.add(logMap); // keys count up from 0: 0, 1, 2…
    debugPrint("Call Dialled from Hive");
    await close();
  }
  // Hive Box (named according to hiveBox variable)
  // -----------------------------------------------
  // | Key (Index) | Value (CallLogModel as Map)    |
  // -----------------------------------------------
  // | 0           | {                               |
  // |             |   "callType": "outgoing",      |
  // |             |   "phoneNumber": "123456789",  |
  // |             |   "timestamp": 1645537200000   |
  // |             | }                               |
  // -----------------------------------------------
  // | 1           | {                               |
  // |             |   "callType": "incoming",      |
  // |             |   "phoneNumber": "987654321",  |
  // |             |   "timestamp": 1645537300000   |
  // |             | }                               |
  // -----------------------------------------------
  // | 2           | {                               |
  // |             |   "callType": "missed",        |
  // |             |   "phoneNumber": "567890123",  |
  // |             |   "timestamp": 1645537400000   |
  // |             | }                               |
  // -----------------------------------------------

  @override
  Future<List<CallLogModel>> getLogs() async {
    await init();
    var box = await Hive.openBox(hiveBox);
    List<CallLogModel> logModelList = [];
    for (int i = 0; i < box.length; i++) {
      var logMap = box.getAt(i); //This value is typically a map representation of the data stored at the specified index in the Hive box.
      logModelList.add(CallLogModel.fromMap(logMap));
    }
    return logModelList;
  }

  @override
  Future<void> deleteLogs(int logId) async {
    await init();
    var box = await Hive.openBox(hiveBox);
    await box.deleteAt(logId);
    debugPrint("deleted");
  }

  @override
  Future<void> close() => Hive.close();

}
