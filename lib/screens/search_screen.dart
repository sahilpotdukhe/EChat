import 'package:echat/enums/user_state.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/utils/utilities.dart';
import 'package:echat/widgets/common/app_search_field.dart';
import 'package:echat/widgets/common/skeleton.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Find someone on EChat by name or username and start chatting.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<UserModel>? _users;
  bool _failed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _users = null;
    });
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    try {
      final list = await AuthMethods().fetchAllUsers(me);
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _users = list);
    } catch (e) {
      debugPrint('$e');
      if (mounted) setState(() => _failed = true);
    }
  }

  List<UserModel> get _matches {
    final q = _query.trim().toLowerCase();
    final users = _users ?? const [];
    if (q.isEmpty) return users;
    return users
        .where((u) => u.name.toLowerCase().contains(q) || u.username.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: ShadcnSpacing.lg),
          child: ResponsiveCenter(
            child: AppSearchField(
              controller: _controller,
              hint: 'Search by name or username',
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_failed) {
      return ShadcnEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load people',
        description: 'Check your internet connection and try again.',
        action: ShadcnButton(
          variant: ShadcnButtonVariant.outline,
          leading: const Icon(Icons.refresh_rounded),
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    }
    if (_users == null) return const SkeletonList();

    final matches = _matches;
    if (matches.isEmpty) {
      return _query.trim().isEmpty
          ? const ShadcnEmptyState(
              icon: Icons.group_outlined,
              title: 'No one here yet',
              description: 'When your friends join EChat, they\'ll show up here.',
            )
          : ShadcnEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results',
              description: 'No one matches "${_query.trim()}". Check the spelling or try a username.',
            );
    }

    final shadcn = context.shadcn;
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: ShadcnSpacing.xl2),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(ShadcnSpacing.lg, ShadcnSpacing.lg, ShadcnSpacing.lg, ShadcnSpacing.sm),
            child: ShadcnText(
              _query.trim().isEmpty ? 'PEOPLE ON ECHAT' : '${matches.length} ${matches.length == 1 ? 'RESULT' : 'RESULTS'}',
              variant: ShadcnTextVariant.muted,
              style: const ShadcnTextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
          );
        }
        final user = matches[index - 1];
        return ShadcnListTile(
          leading: UserAvatar(
            name: user.name,
            imageUrl: user.profilePhoto,
            isOnline: Utils.numToState(user.state) == UserState.online,
          ),
          title: _Highlighted(text: user.name.isEmpty ? 'EChat user' : user.name, query: _query),
          subtitle: Text(user.username.replaceFirst('echat:', '@')),
          trailing: Icon(Icons.chat_bubble_outline_rounded, color: shadcn.primary, size: 22),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(receiver: user)),
          ),
        );
      },
    );
  }
}

/// Text with the part matching [query] in the brand color.
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;

  const _Highlighted({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final start = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (start < 0) return Text(text);
    final end = start + q.length;
    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, start)),
      TextSpan(
        text: text.substring(start, end),
        style: TextStyle(color: context.shadcn.primary, fontWeight: FontWeight.w700),
      ),
      TextSpan(text: text.substring(end)),
    ]));
  }
}
