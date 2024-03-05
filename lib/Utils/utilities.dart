import 'dart:io';

import 'package:echat/enum/UserState.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
class Utils{

  // Example email = sahilpotdukhe.ssp@gmail.com
  // email.split('@') => [sahilpotdukhe.ssp, gmail.com] we want first one so [0]
  static String getUsername(String email){
    return "echat:${email.split('@')[0]}";
  }

  static String getInitials(String? displayName) {
    // Suppose the name is Sahil Potdukhe
    List<String> nameSplit = displayName!.split(" ");
    // list will contain [Sahil,Potdukhe]
    String firstNameInitial = nameSplit[0][0];// List's first index first letter that is "S"
    if(nameSplit.length > 1){
      String lastNameInitial = nameSplit[1][0];// List's second index first letter that is "P"
      return firstNameInitial + lastNameInitial;//It will form "SP"
    }
    return firstNameInitial;
  }

  static int stateToNum(UserState userState){
    switch(userState){
      case UserState.Offline:
        return 0;

      case UserState.Online:
        return 1;

      default:
        return 2;
    }
  }

  static UserState numToState(int number){
    switch(number){
      case 0:
        return UserState.Offline;
      case 1:
        return UserState.Online;
      default:
        return UserState.Waiting;
    }
  }
  
  static String formatDateString(String dateString){
    DateTime dateTime = DateTime.parse(dateString);
    var formatter = DateFormat('dd/MM/yy');
    return formatter.format(dateTime);
  }


  // static Future<File> loadPdfFromNetwork(String pdfUrl) async{
  //   final response =await http.get(Uri.parse(pdfUrl));
  //   final bytes = response.bodyBytes;
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}');
  //   await file.writeAsBytes(bytes,flush: true);
  //   return file;
  // }
}