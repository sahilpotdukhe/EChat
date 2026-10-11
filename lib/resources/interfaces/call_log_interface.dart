import 'package:echat/models/call_log_model.dart';

abstract class CallLogInterface{
  openDb(dbName);

  init();

  addLogs(CallLogModel callLogModel);

  Future<List<CallLogModel>> getLogs();

  deleteLogs(int logId);

  close();
}