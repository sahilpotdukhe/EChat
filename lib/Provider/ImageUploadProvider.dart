import 'package:flutter/material.dart';
import 'package:echat/enum/ViewState.dart';

// Provider is useful in situations like if the state changes of a particular variable in one file all other files using the same variable will see
// changes but if we use setState function it will reflect changes to that screen itself if we come again back to that screen it will once again behave
// as per the default value of the variable

//Refer to Skype Video Clone(watch from 20 min) : https://www.youtube.com/watch?v=khspvcbS7qE&list=PLTHrJfrjCyJDlOLSIT3bm2xCCuPanUNX4&index=11

class ImageUploadProvider with ChangeNotifier{
  // So, in summary, the first line initializes a private variable _viewState with an initial state of IDLE, and the second line provides a getter method
  // getViewState to retrieve the current state of the view. This setup allows external code to access the view state while keeping the internal _viewState
  // variable private to the class.
  ViewState _viewState = ViewState.IDLE;
  String _thumbnail = "";

  ViewState get getViewState => _viewState;
  String get thumbnail => _thumbnail;

  void getThumbnail(){
      _thumbnail = thumbnail;
      notifyListeners();
  }

  void setToLoading(){
    _viewState = ViewState.LOADING;
    notifyListeners();
  }

  void setToIdle(){
    _viewState = ViewState.IDLE;
    notifyListeners();
  }
}