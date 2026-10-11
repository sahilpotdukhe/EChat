import 'package:echat/models/user_model.dart';
import 'package:echat/utils/utilities.dart';

/// One phone contact, reduced to what the Contacts tab shows.
typedef PhoneContact = ({String name, String phone});

/// A phone contact who has an EChat account.
typedef MatchedContact = ({String name, String phone, UserModel user});

/// Splits phone contacts into people already on EChat and people to invite.
///
/// Numbers are compared by their last 10 digits ([Utils.phoneKey]), so
/// country codes and formatting don't matter. Each number appears once (the
/// first contact with it wins), the signed-in user is left out, contacts
/// with no usable number are dropped, and both lists are sorted by name.
({List<MatchedContact> onEchat, List<PhoneContact> toInvite}) matchContacts({
  required List<PhoneContact> contacts,
  required List<UserModel> users,
  required String myUid,
}) {
  final usersByPhone = <String, UserModel>{
    for (final u in users)
      if (u.uid != myUid && Utils.phoneKey(u.phoneNumber).isNotEmpty) Utils.phoneKey(u.phoneNumber): u,
  };

  final seen = <String>{};
  final onEchat = <MatchedContact>[];
  final toInvite = <PhoneContact>[];
  for (final c in contacts) {
    final key = Utils.phoneKey(c.phone);
    if (key.isEmpty || !seen.add(key)) continue;
    final name = c.name.trim().isEmpty ? c.phone : c.name.trim();
    final user = usersByPhone[key];
    if (user != null) {
      onEchat.add((name: name, phone: c.phone, user: user));
    } else {
      toInvite.add((name: name, phone: c.phone));
    }
  }

  int byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  onEchat.sort((a, b) => byName(a.name, b.name));
  toInvite.sort((a, b) => byName(a.name, b.name));
  return (onEchat: onEchat, toInvite: toInvite);
}
