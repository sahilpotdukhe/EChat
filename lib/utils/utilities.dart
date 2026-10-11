import 'package:echat/enums/user_state.dart';
import 'package:intl/intl.dart';
class Utils{

  // Example email = sahilpotdukhe.ssp@gmail.com
  // email.split('@') => [sahilpotdukhe.ssp, gmail.com] we want first one so [0]
  static String getUsername(String email){
    return "echat:${email.split('@')[0]}";
  }

  /// Up to two capital letters from a name: "Sahil Potdukhe" -> "SP".
  /// Empty or blank names give "?" instead of crashing.
  static String getInitials(String? displayName) {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }

  /// A phone number reduced to its last 10 digits, so "+91 98765-43210",
  /// "098765 43210" and "9876543210" all match. Fewer than 10 digits gives
  /// "" (too short to match safely).
  static String phoneKey(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 ? '' : digits.substring(digits.length - 10);
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