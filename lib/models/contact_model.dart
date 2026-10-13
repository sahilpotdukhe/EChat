import 'package:cloud_firestore/cloud_firestore.dart';

/// One row of the chat list: Users/{me}/Contacts/{them}.
class ContactModel{

  String uid ="";
  Timestamp? addedOn;
  // When the newest message in this chat was sent; sorts the chat list.
  // Null on chats from before this was stored.
  Timestamp? lastMessageAt;
  // Messages (and missed calls) from them I haven't opened yet.
  int unreadCount = 0;

  ContactModel({
    required this.uid,
    this.addedOn,
    this.lastMessageAt,
    this.unreadCount = 0,
});

  Map toMap(ContactModel contactModel){
    final data = <String, dynamic>{};
    data['contact_id'] = contactModel.uid;
    data['added_on'] = contactModel.addedOn;
    data['last_message_at'] = contactModel.lastMessageAt;
    data['unread_count'] = contactModel.unreadCount;
    return data;
  }

  ContactModel.fromMap(Map<String,dynamic> mapData){
    uid = mapData['contact_id'] ?? '';
    addedOn = mapData['added_on'] is Timestamp ? mapData['added_on'] : null;
    lastMessageAt = mapData['last_message_at'] is Timestamp ? mapData['last_message_at'] : null;
    unreadCount = (mapData['unread_count'] as num?)?.toInt() ?? 0;
    if (unreadCount < 0) unreadCount = 0;
  }

  /// Newest chat first; chats with no time yet fall back to when they were
  /// added, and go last if they have neither.
  static int newestFirst(ContactModel a, ContactModel b) {
    final ta = a.lastMessageAt ?? a.addedOn;
    final tb = b.lastMessageAt ?? b.addedOn;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return tb.compareTo(ta);
  }
}
