import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier{
  UserModel? _userModel;
  AuthMethods authMethods = AuthMethods();

  UserModel? get getUser => _userModel;

  Future<void> refreshUser() async{
    UserModel user = await authMethods.getUserDetails();
    _userModel = user;
    print(_userModel);
    notifyListeners();
  }
}