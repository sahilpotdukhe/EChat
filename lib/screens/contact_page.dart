import 'package:echat/models/user_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/utils/contact_matching.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/app_search_field.dart';
import 'package:echat/widgets/common/skeleton.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Status { checking, needsPermission, blocked, loading, ready, failed }

/// The Contacts tab: phone contacts who are already on EChat (tap to chat)
/// and everyone else (invite by SMS).
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _search = TextEditingController();
  _Status _status = _Status.checking;
  List<MatchedContact> _onEchat = const [];
  List<PhoneContact> _toInvite = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Explain first and only ask when the user taps "Allow access", rather
  // than popping the system prompt as soon as the tab opens.
  Future<void> _checkPermission() async {
    final status = await Permission.contacts.status;
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      await _load();
    } else {
      setState(() => _status = status.isPermanentlyDenied ? _Status.blocked : _Status.needsPermission);
    }
  }

  Future<void> _requestPermission() async {
    if (_status == _Status.blocked) {
      await openAppSettings();
      return;
    }
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      await _load();
    } else {
      setState(() => _status = status.isPermanentlyDenied ? _Status.blocked : _Status.needsPermission);
    }
  }

  Future<void> _load() async {
    if (_status != _Status.ready) setState(() => _status = _Status.loading);
    try {
      final me = FirebaseAuth.instance.currentUser;
      final results = await Future.wait([
        FastContacts.getAllContacts(),
        if (me != null) AuthMethods().fetchAllUsers(me),
      ]);
      final contacts = results[0] as List<Contact>;
      final split = matchContacts(
        contacts: [
          for (final c in contacts)
            for (final p in c.phones) (name: c.displayName, phone: p.number),
        ],
        users: me == null ? const [] : (results[1] as List).cast<UserModel>(),
        myUid: me?.uid ?? '',
      );
      if (!mounted) return;
      setState(() {
        _onEchat = split.onEchat;
        _toInvite = split.toInvite;
        _status = _Status.ready;
      });
    } catch (e) {
      debugPrint('Couldn\'t load contacts: $e');
      if (mounted) setState(() => _status = _Status.failed);
    }
  }

  Future<void> _invite(PhoneContact contact) async {
    final me = Provider.of<UserProvider>(context, listen: false).getUser;
    final from = me?.name.isNotEmpty == true ? '${me!.name} is' : "I'm";
    final message = '$from on EChat — free messaging and voice & video calls. '
        'Join me so we can chat!';
    final uri = Uri.parse('sms:${contact.phone}?body=${Uri.encodeComponent(message)}');
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      // Reported below.
    }
    if (!opened && mounted) {
      showShadcnToast(context, title: 'No messaging app found', variant: ShadcnToastVariant.destructive);
    }
  }

  bool _matches(String name, String phone) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || name.toLowerCase().contains(q) || phone.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: ResponsiveCenter(child: _body()),
    );
  }

  Widget _body() {
    switch (_status) {
      case _Status.checking:
      case _Status.loading:
        return const SkeletonList(count: 8);
      case _Status.needsPermission:
      case _Status.blocked:
        final blocked = _status == _Status.blocked;
        return ShadcnEmptyState(
          icon: Icons.contacts_outlined,
          title: 'Find friends from your contacts',
          description: blocked
              ? 'Contacts access is turned off for EChat. Turn it on in Settings to see who\'s here.'
              : 'Allow access to see which of your contacts are on EChat and invite the rest. '
                  'Your contacts aren\'t uploaded.',
          action: ShadcnButton(
            size: ShadcnButtonSize.lg,
            leading: Icon(blocked ? Icons.settings_outlined : Icons.lock_open_rounded),
            onPressed: _requestPermission,
            child: Text(blocked ? 'Open Settings' : 'Allow access'),
          ),
        );
      case _Status.failed:
        return ShadcnEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Couldn\'t load your contacts',
          description: 'Check your internet connection and try again.',
          action: ShadcnButton(
            variant: ShadcnButtonVariant.outline,
            leading: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            child: const Text('Retry'),
          ),
        );
      case _Status.ready:
        return _list();
    }
  }

  Widget _list() {
    if (_onEchat.isEmpty && _toInvite.isEmpty) {
      return const ShadcnEmptyState(
        icon: Icons.contact_phone_outlined,
        title: 'No contacts with phone numbers',
        description: 'Contacts you save with a phone number will show up here.',
      );
    }
    final onEchat = _onEchat.where((c) => _matches(c.name, c.phone)).toList();
    final toInvite = _toInvite.where((c) => _matches(c.name, c.phone)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ShadcnSpacing.lg, ShadcnSpacing.xs, ShadcnSpacing.lg, 0),
          child: AppSearchField(
            controller: _search,
            hint: 'Search contacts',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: onEchat.isEmpty && toInvite.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 320,
                        child: ShadcnEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                          description: 'No contact matches "${_query.trim()}".',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: ShadcnSpacing.xl3),
                    children: [
                      if (onEchat.isNotEmpty) ...[
                        _SectionHeader('On EChat · ${onEchat.length}'),
                        for (final c in onEchat)
                          ShadcnListTile(
                            leading: UserAvatar(name: c.name, imageUrl: c.user.profilePhoto),
                            title: Text(c.name),
                            subtitle: Text(c.user.username.isNotEmpty
                                ? c.user.username.replaceFirst('echat:', '@')
                                : c.phone),
                            trailing: ShadcnButton(
                              size: ShadcnButtonSize.sm,
                              variant: ShadcnButtonVariant.secondary,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ChatScreen(receiver: c.user)),
                              ),
                              child: const Text('Message'),
                            ),
                          ),
                      ],
                      if (toInvite.isNotEmpty) ...[
                        _SectionHeader('Invite to EChat · ${toInvite.length}'),
                        for (final c in toInvite)
                          ShadcnListTile(
                            leading: UserAvatar(name: c.name),
                            title: Text(c.name),
                            subtitle: Text(c.phone),
                            trailing: ShadcnButton(
                              size: ShadcnButtonSize.sm,
                              variant: ShadcnButtonVariant.outline,
                              semanticLabel: 'Invite ${c.name}',
                              onPressed: () => _invite(c),
                              child: const Text('Invite'),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ShadcnSpacing.lg, ShadcnSpacing.lg, ShadcnSpacing.lg, ShadcnSpacing.xs),
      child: ShadcnText(
        label.toUpperCase(),
        variant: ShadcnTextVariant.muted,
        style: const ShadcnTextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      ),
    );
  }
}
