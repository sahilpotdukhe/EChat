import 'package:echat/models/call_log_model.dart';
import 'package:echat/resources/interfaces/call_log_interface.dart';
import 'package:echat/resources/local_database/hive_methods.dart';

/// The call history on this phone, one store per signed-in account.
class LogRepository {
  static CallLogInterface? _store;

  /// Replaces the store, e.g. with a fake in tests.
  static set dbObject(CallLogInterface store) => _store = store;

  // Called by HomeScreen once the signed-in user is known.
  static void initialize({required String dbName}) {
    _store = HiveMethods()..openDb(dbName);
  }

  static CallLogInterface get _db {
    final store = _store;
    if (store == null) throw StateError('Call history used before LogRepository.initialize');
    return store;
  }

  static Future<void> init() => _db.init();

  static Future<void> addLogs(CallLogModel callLogModel) => _db.addLogs(callLogModel);

  static Future<void> deleteLogs(int logId) => _db.deleteLogs(logId);

  static Future<List<CallLogModel>> getLogs() => _db.getLogs();

  static Future<void> close() => _db.close();
}
