import 'package:echat/enums/user_state.dart';
import 'package:intl/intl.dart';
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
      case UserState.offline:
        return 0;

      case UserState.online:
        return 1;

      default:
        return 2;
    }
  }

  static UserState numToState(int number){
    switch(number){
      case 0:
        return UserState.offline;
      case 1:
        return UserState.online;
      default:
        return UserState.waiting;
    }
  }
  
  static String formatDateString(String dateString){
    DateTime dateTime = DateTime.parse(dateString);
    var formatter = DateFormat('dd/MM/yy   ....  hh:mm a');
    return formatter.format(dateTime);
  }

}