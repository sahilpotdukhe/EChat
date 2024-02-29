import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/LocalDatabase/Databases/HiveMethods.dart';
import 'package:echat/Resources/LocalDatabase/Databases/SqfliteMethods.dart';

class LogRepository{
  static var dbObject;
  static bool? isHive;

  static initialize({required bool isHive, required String dbName}){
    dbObject = isHive ? HiveMethods() : SqfliteMethods();
    dbObject.openDb(dbName);
  }

  static init() => dbObject.init();

  static addLogs(CallLogModel callLogModel) => dbObject.addLogs(callLogModel);

  static deleteLogs(int logId) => dbObject.deleteLogs(logId);

  static getLogs() => dbObject.getLogs();

  static close() => dbObject.close();


}