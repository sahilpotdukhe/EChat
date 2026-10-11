import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
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