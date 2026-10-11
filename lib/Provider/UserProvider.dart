import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier{
  UserModel? _userModel;
  AuthMethods authMethods = AuthMethods();

  UserModel? get getUser => _userModel;

  Future<void> refreshUser() async{
    _userModel = await authMethods.getUserDetails();
    debugPrint('$_userModel');
    notifyListeners();
  }
}