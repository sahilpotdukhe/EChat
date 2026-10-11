import 'package:echat/models/call_log_model.dart';

/// Where the call history on this phone is stored.
abstract class CallLogInterface {
  void openDb(String dbName);

  Future<void> init();

  Future<void> addLogs(CallLogModel callLogModel);

  Future<List<CallLogModel>> getLogs();

  /// [logId] is the log's position in storage (oldest first).
  Future<void> deleteLogs(int logId);

  Future<void> close();
}
