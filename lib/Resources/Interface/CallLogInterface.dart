import 'package:echat/Models/CallLogModel.dart';

abstract class CallLogInterface{
  openDb(dbName);

  init();

  addLogs(CallLogModel callLogModel);

  Future<List<CallLogModel>> getLogs();

  deleteLogs(int logId);

  close();
}