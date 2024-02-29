import 'dart:io';
import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/Interface/CallLogInterface.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// Hive stores data in the form of key value pairs
class HiveMethods implements CallLogInterface {
  String hive_box = ""; //a storage container

  @override
  openDb(dbName) => (hive_box = dbName);

  @override
  init() async {
    Directory dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }


  @override
  addLogs(CallLogModel callLogModel) async {
    await init();
    var box = await Hive.openBox(hive_box);
    var logMap = callLogModel.toMap(callLogModel);
    int idOfInput = await box.add(logMap); // for the very first addition of data the idOfInput will be 0 then 1 then 2 ...
    print("Call Dialled from Hive");
    close();
    return idOfInput;
  }
  // Hive Box (named according to hive_box variable)
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


  updateLog(int i, CallLogModel newCallLogModel) async {
    await init();
    var box = await Hive.openBox(hive_box);
    var newLogMap = newCallLogModel.toMap(newCallLogModel);
    box.putAt(i, newLogMap);
    close();
  }

  @override
  Future<List<CallLogModel>> getLogs() async {
    await init();
    var box = await Hive.openBox(hive_box);
    List<CallLogModel> logModelList = [];
    for (int i = 0; i < box.length; i++) {
      var logMap = box.getAt(i); //This value is typically a map representation of the data stored at the specified index in the Hive box.
      logModelList.add(CallLogModel.fromMap(logMap));
    }
    return logModelList;
  }

  @override
  deleteLogs(int logId) async {
    await init();
    var box = await Hive.openBox(hive_box);
    await box.deleteAt(logId);
    print("deleted");
  }

  @override
  close() {
    Hive.close();
  }

}
