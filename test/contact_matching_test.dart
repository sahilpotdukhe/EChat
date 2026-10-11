import 'package:echat/models/user_model.dart';
import 'package:echat/utils/contact_matching.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel user(String uid, String phone) => UserModel(
    uid: uid, name: uid, email: '', username: '', status: '', state: 0, gender: '',
    phoneNumber: phone, profilePhoto: '', authType: '', notificationToken: '');

void main() {
  final users = [user('me', '9000000000'), user('priya', '9876543210'), user('noPhone', '')];

  test('splits contacts into on EChat and to invite, sorted by name', () {
    final r = matchContacts(
      users: users,
      myUid: 'me',
      contacts: [
        (name: 'zara', phone: '9111111111'),
        (name: 'Priya S', phone: '+91 98765-43210'),
        (name: 'adam', phone: '9222222222'),
      ],
    );
    expect(r.onEchat.map((c) => (c.name, c.user.uid)), [('Priya S', 'priya')]);
    expect(r.toInvite.map((c) => c.name), ['adam', 'zara']);
  });

  test('my own number is not shown as a match', () {
    final r = matchContacts(users: users, myUid: 'me', contacts: [(name: 'Me', phone: '9000000000')]);
    expect(r.onEchat, isEmpty);
    expect(r.toInvite.map((c) => c.name), ['Me']);
  });

  test('the same number listed twice appears once', () {
    final r = matchContacts(users: users, myUid: 'me', contacts: [
      (name: 'Mom', phone: '9333333333'),
      (name: 'Mom (home)', phone: '+91 93333 33333'),
    ]);
    expect(r.toInvite.map((c) => c.name), ['Mom']);
  });

  test('numbers too short to match are dropped', () {
    final r = matchContacts(users: users, myUid: 'me', contacts: [(name: 'Pizza', phone: '1234')]);
    expect(r.onEchat, isEmpty);
    expect(r.toInvite, isEmpty);
  });

  test('a contact with no name shows the number', () {
    final r = matchContacts(users: users, myUid: 'me', contacts: [(name: '  ', phone: '9444444444')]);
    expect(r.toInvite.single.name, '9444444444');
  });
}
