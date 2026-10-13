import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/screens/chat_list/widgets/contact_tile_view.dart';
import 'package:echat/screens/search_screen.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/app_search_field.dart';
import 'package:echat/widgets/common/skeleton.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:echat/widgets/new_user_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

class ChatListScreen extends StatefulWidget {
  /// Switches the home screen to the Profile tab. When null, the profile
  /// opens as its own page instead.
  final VoidCallback? onOpenProfile;

  const ChatListScreen({super.key, this.onOpenProfile});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _streamUserId;
  Stream<QuerySnapshot>? _contacts;

  // Re-created only if the signed-in user changes, not on every rebuild.
  Stream<QuerySnapshot> _contactsFor(String uid) {
    if (_streamUserId != uid || _contacts == null) {
      _streamUserId = uid;
      _contacts = ChatFirebaseMethods().fetchContacts(userId: uid);
    }
    return _contacts!;
  }

  void _openSearch() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _openProfile() {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewUserDetails()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;
    // Keeps the list a comfortable width on tablets.
    final side = ((context.screenWidth - Breakpoints.contentMaxWidth) / 2).clamp(0.0, double.infinity);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-chat',
        onPressed: _openSearch,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New chat'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: ShadcnSpacing.lg + side,
            title: const Text('Chats'),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: ShadcnSpacing.lg + side),
                child: Tooltip(
                  message: 'Your profile',
                  child: InkResponse(
                    onTap: _openProfile,
                    radius: 24,
                    child: UserAvatar(name: user?.name ?? '', imageUrl: user?.profilePhoto, size: 36),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(ShadcnSpacing.lg + side, ShadcnSpacing.sm, ShadcnSpacing.lg + side, ShadcnSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: AppSearchField(
                hint: 'Search people',
                readOnly: true,
                onTap: _openSearch,
              ),
            ),
          ),
          if (user == null)
            const SliverFillRemaining(hasScrollBody: true, child: SkeletonList())
          else
            StreamBuilder<QuerySnapshot>(
              stream: _contactsFor(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    // ShadcnEmptyState scrolls itself when space is short.
                    hasScrollBody: true,
                    child: ShadcnEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Couldn\'t load your chats',
                      description: 'Check your internet connection and try again.',
                      action: ShadcnButton(
                        variant: ShadcnButtonVariant.outline,
                        leading: const Icon(Icons.refresh_rounded),
                        onPressed: () => setState(() => _contacts = null),
                        child: const Text('Retry'),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(hasScrollBody: true, child: SkeletonList());
                }
                // Newest conversation first, like WhatsApp.
                final contacts = [
                  for (final doc in snapshot.data!.docs) ContactModel.fromMap(doc.data() as Map<String, dynamic>),
                ]
                  ..removeWhere((c) => c.uid.isEmpty)
                  ..sort(ContactModel.newestFirst);
                if (contacts.isEmpty) {
                  return SliverFillRemaining(
                    // ShadcnEmptyState scrolls itself when space is short.
                    hasScrollBody: true,
                    child: ShadcnEmptyState(
                      illustration: Image.asset('assets/nomessage.png'),
                      title: 'No chats yet',
                      description: 'Find your friends and family on EChat to start a conversation.',
                      action: ShadcnButton(
                        size: ShadcnButtonSize.lg,
                        leading: const Icon(Icons.person_search_outlined),
                        onPressed: _openSearch,
                        child: const Text('Find people'),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  // Room at the bottom so the last chat isn't hidden behind
                  // the New chat button.
                  padding: EdgeInsets.fromLTRB(side, ShadcnSpacing.sm, side, 96),
                  sliver: SliverList.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ContactTileView(
                        key: ValueKey(contact.uid),
                        contactModel: contact,
                        currentUserId: user.uid,
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
