import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/resources/media_storage.dart';
import 'package:echat/resources/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Messages live twice: messages/{owner}/{peer}/{id} is the owner's copy of
/// their chat with peer, and both copies share the same id. Each person's
/// chat list is Users/{me}/Contacts/{them}, which also holds the chat's
/// unread count and the time of its newest message.
class ChatFirebaseMethods{
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Firestore allows 500 writes per batch.
  static const int _batchLimit = 450;

  DocumentReference _copy(String ownerId, String peerId, String messageId) =>
      firestore.collection("messages").doc(ownerId).collection(peerId).doc(messageId);

  DocumentReference _contact(String ownerId, String peerId) =>
      firestore.collection("Users").doc(ownerId).collection("Contacts").doc(peerId);

  // Saves the sender's and the receiver's copy together: both or neither.
  // Offline, Firestore shows the message right away and the returned future
  // completes once it reaches the server; it only throws on a real failure
  // (e.g. rejected by security rules).
  //
  // Then, separately, puts each person in the other's chat list and adds
  // one to the receiver's unread count. That is its own write on purpose: if
  // it is ever refused, the message must still stay sent rather than vanish
  // with it.
  //
  // [notify] asks the notification server to push it to the receiver;
  // [countAsUnread] is false for things that shouldn't light up a badge
  // (e.g. a call they answered).
  Future<void> addMessagetoDb(MessageModel messageModel, {bool notify = true, bool countAsUnread = true}) async {
    final Map<String, dynamic> map = Map<String, dynamic>.from(messageModel.toMap());
    final String senderId = messageModel.senderId;
    final String receiverId = messageModel.receiverId;

    final DocumentReference senderCopy =
        firestore.collection("messages").doc(senderId).collection(receiverId).doc();
    // Same id on both sides makes the two copies easy to match up.
    final DocumentReference receiverCopy = _copy(receiverId, senderId, senderCopy.id);

    final WriteBatch messageBatch = firestore.batch();
    messageBatch.set(senderCopy, map);
    messageBatch.set(receiverCopy, map);
    final Future<void> saved = messageBatch.commit();

    // Merged, so an existing chat keeps its other fields (and a chat either
    // person deleted comes back, like WhatsApp).
    final WriteBatch listBatch = firestore.batch();
    listBatch.set(_contact(senderId, receiverId), {
      'contact_id': receiverId,
      'last_message_at': messageModel.timestamp,
    }, SetOptions(merge: true));
    listBatch.set(_contact(receiverId, senderId), {
      'contact_id': senderId,
      'last_message_at': messageModel.timestamp,
      if (countAsUnread) 'unread_count': FieldValue.increment(1),
      // Sending ends "typing…" on their side straight away.
      'typing_at': FieldValue.delete(),
    }, SetOptions(merge: true));
    listBatch.commit().catchError((Object e) => debugPrint('Chat list not updated: $e'));

    await saved;

    // Not awaited: a slow or unreachable notification server must not delay
    // or fail the message itself.
    if (notify) NotificationService.notifyMessage(messageId: senderCopy.id, receiverId: receiverId);
  }

  /// My chat-list entry for [peerId]: their unread count and whether they
  /// are typing to me.
  Stream<DocumentSnapshot> contactStream({required String myId, required String peerId}) =>
      _contact(myId, peerId).snapshots();

  /// Shows (or stops showing) "typing…" to [peerId]. Written on their
  /// chat-list entry for me; skipped quietly if they don't have one yet (a
  /// brand-new chat) or the write fails.
  Future<void> setTyping({required String myId, required String peerId, required bool typing}) async {
    try {
      await _contact(peerId, myId)
          .update({'typing_at': typing ? FieldValue.serverTimestamp() : FieldValue.delete()});
    } catch (e) {
      debugPrint('Typing status skipped: $e');
    }
  }

  Stream<QuerySnapshot> fetchContacts({required String userId}) =>
      firestore.collection("Users").doc(userId).collection("Contacts").snapshots();

  /// Chats with messages I haven't opened yet (drives the badges).
  Stream<QuerySnapshot> fetchUnreadContacts({required String userId}) => firestore
      .collection("Users")
      .doc(userId)
      .collection("Contacts")
      .where("unread_count", isGreaterThan: 0)
      .snapshots();

  // Only the newest message, for the chat list preview.
  Stream<QuerySnapshot> fetchLastMessageBetween({required String senderId, required String receiverId}) =>
      firestore.collection("messages").doc(senderId).collection(receiverId)
          .orderBy("timestamp", descending: true).limit(1).snapshots();

  // ---------------------------------------------------------------- ticks

  /// Moves [peerId]'s messages to me from "sent" to "delivered" (two grey
  /// ticks on their side). Called whenever this phone learns of new messages.
  Future<void> markDelivered({required String myId, required String peerId}) async {
    final QuerySnapshot pending = await firestore
        .collection("messages")
        .doc(myId)
        .collection(peerId)
        .where("senderId", isEqualTo: peerId)
        .where("status", isEqualTo: MessageStatus.sent)
        .get();
    await _setStatus(myId, peerId, pending.docs.map((d) => d.id), MessageStatus.delivered);
  }

  /// One message reached this phone (from a push notification).
  Future<void> markDeliveredById({required String myId, required String peerId, required String messageId}) =>
      _setStatus(myId, peerId, [messageId], MessageStatus.delivered);

  /// [messageIds] (from [peerId]) were seen in the open chat: blue ticks.
  Future<void> markRead({required String myId, required String peerId, required Iterable<String> messageIds}) =>
      _setStatus(myId, peerId, messageIds, MessageStatus.read);

  // Writes the status on my copy and on the sender's. Each write stands
  // alone: the sender may have deleted their copy, and the rules refuse to
  // move a status backwards (e.g. "delivered" arriving after "read"); either
  // only means that one write is skipped.
  Future<void> _setStatus(String myId, String peerId, Iterable<String> messageIds, String status) async {
    final writes = <Future<void>>[];
    for (final id in messageIds) {
      for (final ref in [_copy(myId, peerId, id), _copy(peerId, myId, id)]) {
        writes.add(ref.update({'status': status}).catchError((Object e) {
          debugPrint('Status $status for $id skipped: $e');
        }));
      }
    }
    await Future.wait(writes);
  }

  /// I opened the chat with [peerId]: clear its unread badge.
  Future<void> clearUnread({required String myId, required String peerId}) async {
    try {
      await _contact(myId, peerId).update({'unread_count': 0});
    } catch (e) {
      // No chat-list entry yet (e.g. a brand-new chat): nothing to clear.
      debugPrint('Clear unread skipped: $e');
    }
  }

  // ------------------------------------------------------------- deleting

  /// Removes one message from my side of the chat only.
  Future<void> deleteMessageForMe({required String myId, required String peerId, required String messageId}) =>
      _copy(myId, peerId, messageId).delete();

  /// Replaces one of my messages with "This message was deleted" on both
  /// sides, and removes its file from storage. The other person may already
  /// have deleted their copy, so each side is updated on its own.
  Future<void> deleteMessageForEveryone({required String myId, required String peerId, required String messageId, required MessageModel message}) async {
    await _copy(myId, peerId, messageId).update(MessageModel.deletedFields);
    await _copy(peerId, myId, messageId)
        .update(MessageModel.deletedFields)
        .catchError((Object e) => debugPrint('Their copy was already gone: $e'));
    for (final url in {message.photoUrl, message.thumbnailUrl, message.pdfUrl, message.videoUrl}) {
      if (url.isNotEmpty) MediaStorage.removeByUrl(url);
    }
  }

  /// Deletes the whole chat with [peerId]: every message on my side and the
  /// chat-list entry. With [forEveryone], the other person's side goes too.
  /// If they message again later, the chat starts afresh (like WhatsApp).
  Future<void> deleteChat({required String myId, required String peerId, required bool forEveryone}) async {
    await _deleteAll(firestore.collection("messages").doc(myId).collection(peerId));
    if (forEveryone) {
      await _deleteAll(firestore.collection("messages").doc(peerId).collection(myId));
      await _contact(peerId, myId).delete();
    }
    await _contact(myId, peerId).delete();
  }

  Future<void> _deleteAll(CollectionReference collection) async {
    while (true) {
      final QuerySnapshot page = await collection.limit(_batchLimit).get();
      if (page.docs.isEmpty) return;
      final WriteBatch batch = firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      // Offline, commit() only completes once back online, but the deletes
      // are already applied locally (the next page skips them) and are sent
      // later, so don't wait for it.
      await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});
      if (page.docs.length < _batchLimit) return;
    }
  }
}
