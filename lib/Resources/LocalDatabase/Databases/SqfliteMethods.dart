import 'dart:io';

import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/Interface/CallLogInterface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//Sqflite stores data in form of Rows and Columns in table
class SqfliteMethods implements CallLogInterface{

  Database? _db; //_db is a nullable Database object,
  String databaseName = "";
  String tableName = "CallLogsTable";

  // Columns  // Should be same as to store in database and CallLogModel fields
  String callLogId = "callLog_id";
  String callerName = "caller_name";
  String callerPic = "caller_pic";
  String receiverName = "receiver_name";
  String receiverPic = "receiver_pic";
  String callStatus = "call_status";
  String timestamp = "timestamp";
  String callType = "callType";

  //This is the constructor for the SqfliteMethods class. It initializes _db to null.
  SqfliteMethods() {
    _db = null;
  }

  //the get keyword indicates that db is a getter method. It allows you to access the db property of the SqfliteMethods class without explicitly calling a method.
  Future<Database> get db async{
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    print("db was null,now awaiting it");
    _db = await init();
    return _db!;
  }

  @override
  openDb(dbName) =>(databaseName = dbName);


  //This method initializes the database. It retrieves the application documents directory, constructs the path for the database file using the databaseName, opens the database,
  // and assigns it to the _db variable. It also calls the _onCreateTable method to create the necessary table if it doesn't exist.
  @override
  init() async{
    Directory dir = await getApplicationDocumentsDirectory(); // Example: dir.path = "/data/user/0/com.example.app/app_flutter" databaseName = "my_database.db"
    String path = join(dir.path, databaseName); // path = "/data/user/0/com.example.app/app_flutter/my_database.db"
    var db = await openDatabase(path,version: 1,onCreate: _onCreateTable);
    _db = db; // Assign db to _db
    return db;
  }

  // This method is called when the database is created. It executes a SQL query to create a table named tableName with the specified columns.
  _onCreateTable(Database db, int version) async{
    String createTableQuery = "CREATE TABLE $tableName ($callLogId INTEGER PRIMARY KEY AUTOINCREMENT,$callerName TEXT,$callerPic TEXT,$receiverName TEXT, $receiverPic TEXT, $callStatus TEXT,$timestamp TEXT)";
    await db.execute(createTableQuery);
    print("Table created");
  }

  @override
  addLogs(CallLogModel callLogModel) async{
    var dbClient = await db;
    await dbClient.insert(tableName, callLogModel.toMap(callLogModel)); //This method helps insert a map of values into the specified table and returns the id of the last inserted row.
    print("Call Dialled from Sqflite");
  }

  // dbName
  // | callLog_id | caller_name | caller_pic | receiver_name | receiver_pic | call_status | timestamp        |
  // |------------|-------------|------------|---------------|--------------|-------------|------------------|
  // | 1          | John        | john.jpg   | Alice         | alice.jpg    | answered    | 2024-02-22 10:15 |
  // | 2          | Bob         | bob.jpg    | Carol         | carol.jpg    | missed      | 2024-02-22 10:30 |
  // | 3          | Alice       | alice.jpg  | John          | john.jpg     | answered    | 2024-02-22 11:00 |

  @override
  Future<List<CallLogModel>> getLogs() async{
    var dbClient = await db;
    //List<Map> tabledataMap = await dbClient.rawQuery("SELECT * FROM $tableName");
    //It will hold the result of the query, where each element in the list represents a row from the database, and each row is represented as a map where the keys are column names and the values are the corresponding column values.
    List<Map> tableDataMap = await dbClient.query(tableName,columns: [callLogId,callerName,callerPic,receiverName,receiverPic,callStatus,timestamp,callType]); //The columns list specify which columns to return.
    List<CallLogModel> callLogModelList = [];
    if(tableDataMap.isNotEmpty){
      for(Map map in tableDataMap){
        callLogModelList.add(CallLogModel.fromMap(map));
      }
    }
    return callLogModelList;
  }

  @override
  deleteLogs(int logId) async{
    var dbClient = await db;
    return await dbClient.delete(tableName,where: '$callLogId = ?',whereArgs: [logId]);
    // it's 'callLog_id = ?', where callLog_id is the column name and ? is a placeholder for the value to be provided later.
    //whereArgs: This is an optional parameter that provides the values to substitute for the ? placeholders in the where clause. In this case, it's [logId], where logId is the value used to identify the row to be deleted
  }

  updateLogs(CallLogModel callLogModel) async{
    var dbClient = await db;
    await dbClient.update(tableName, callLogModel.toMap(callLogModel),where: '$callLogId =?',whereArgs: [callLogModel.callLogId]);
  }

  @override
  close() async{
    var dbClient = await db;
    dbClient.close();

  }


}