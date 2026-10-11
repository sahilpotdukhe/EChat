import 'package:echat/models/call_log_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/screens/search_screen.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/call_utilities.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/skeleton.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The Calls tab: this phone's call history, newest first, grouped by day.
class CallLogsScreen extends StatefulWidget {
  /// True while this tab is the one on screen. The home screen keeps tabs
  /// alive, so the list reloads each time the tab is shown again.
  final bool isActive;

  const CallLogsScreen({super.key, this.isActive = true});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

/// A log plus its position in storage, which is what deleting needs. The
/// list is shown newest-first, so the on-screen position is different.
typedef _Entry = ({int storageIndex, CallLogModel log});

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<_Entry>? _entries;
  bool _failed = false;
  bool _missedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CallLogsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  Future<void> _load() async {
    try {
      final logs = (await LogRepository.getLogs() as List).cast<CallLogModel>();
      if (!mounted) return;
      setState(() {
        _failed = false;
        _entries = [
          for (final (i, log) in logs.indexed) (storageIndex: i, log: log),
        ].reversed.toList();
      });
    } catch (e) {
      debugPrint('Couldn\'t load call logs: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _delete(_Entry entry) async {
    final confirmed = await showShadcnAlertDialog(
      context,
      title: 'Delete this call?',
      description: 'It will be removed from your call history on this phone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    // Hive (the store the app uses) deletes by position in storage.
    await LogRepository.deleteLogs(entry.storageIndex);
    await _load();
    if (mounted) showShadcnToast(context, title: 'Call deleted', variant: ShadcnToastVariant.success);
  }

  Future<void> _openChat(CallLogModel log) async {
    final peer = await AuthMethods().getUserDetailsById(log.peerId);
    if (!mounted) return;
    if (peer == null) {
      showShadcnToast(context, title: 'This account no longer exists', variant: ShadcnToastVariant.destructive);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(receiver: peer)));
  }

  Future<void> _callBack(CallLogModel log) async {
    final me = Provider.of<UserProvider>(context, listen: false).getUser;
    final peer = await AuthMethods().getUserDetailsById(log.peerId);
    if (!mounted || me == null) return;
    if (peer == null) {
      showShadcnToast(context, title: 'This account no longer exists', variant: ShadcnToastVariant.destructive);
      return;
    }
    await CallUtilities.dial(
      fromCaller: me,
      toReceiver: peer,
      context: context,
      callType: log.isVideo ? 'videoCall' : 'audioCall',
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final side = ((context.screenWidth - (context.isCompact ? 0 : 81) - Breakpoints.contentMaxWidth) / 2)
        .clamp(0.0, double.infinity);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(pinned: true, titleSpacing: ShadcnSpacing.lg + side, title: const Text('Calls')),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(ShadcnSpacing.lg + side, ShadcnSpacing.xs, ShadcnSpacing.lg + side, ShadcnSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: ShadcnTabs(
                  fullWidth: true,
                  contentSpacing: 0,
                  initialValue: 'all',
                  onChanged: (value) => setState(() => _missedOnly = value == 'missed'),
                  items: const [
                    ShadcnTabItem(value: 'all', label: 'All', content: SizedBox.shrink()),
                    ShadcnTabItem(value: 'missed', label: 'Missed', content: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            ..._content(side),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(double side) {
    if (_failed) {
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: ShadcnEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Couldn\'t load your calls',
            description: 'Something went wrong reading your call history.',
            action: ShadcnButton(
              variant: ShadcnButtonVariant.outline,
              leading: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ),
      ];
    }
    final entries = _entries;
    if (entries == null) {
      return const [SliverFillRemaining(hasScrollBody: true, child: SkeletonList(count: 6))];
    }
    final shown = _missedOnly ? entries.where((e) => e.log.isMissed).toList() : entries;
    if (shown.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: _missedOnly
              ? const ShadcnEmptyState(
                  icon: Icons.phone_missed_outlined,
                  title: 'No missed calls',
                  description: 'Calls you miss will show up here.',
                )
              : ShadcnEmptyState(
                  illustration: Image.asset('assets/logs.png'),
                  title: 'No calls yet',
                  description: 'Open a chat and tap the phone or video button to start a call.',
                  action: ShadcnButton(
                    leading: const Icon(Icons.person_search_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: const Text('Find people'),
                  ),
                ),
        ),
      ];
    }

    // Day headings are worked out here, in order, rather than while the
    // list builds rows lazily (which made them unreliable).
    final now = DateTime.now();
    final rows = <Widget>[];
    String? lastDay;
    for (final entry in shown) {
      final time = entry.log.time;
      final day = time == null ? 'Earlier' : MessageUtils.chatDateLabel(time, now);
      if (day != lastDay) {
        rows.add(_DayHeader(label: day));
        lastDay = day;
      }
      rows.add(_CallRow(
        log: entry.log,
        onTap: entry.log.peerId.isEmpty ? null : () => _openChat(entry.log),
        onCallBack: entry.log.peerId.isEmpty ? null : () => _callBack(entry.log),
        onLongPress: () => _delete(entry),
      ));
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(side, 0, side, ShadcnSpacing.xl3),
        sliver: SliverList.list(children: rows),
      ),
    ];
  }
}

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader({required this.label});

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

class _CallRow extends StatelessWidget {
  final CallLogModel log;
  final VoidCallback? onTap;
  final VoidCallback? onCallBack;
  final VoidCallback onLongPress;

  const _CallRow({required this.log, required this.onTap, required this.onCallBack, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    final colors = context.colors;
    final name = log.peerName.isEmpty ? 'EChat user' : log.peerName;
    final time = log.time == null ? '' : DateFormat.jm().format(log.time!);

    final (IconData directionIcon, Color directionColor, String direction) = log.isOutgoing
        ? (Icons.call_made_rounded, t.mutedForeground, 'Outgoing')
        : log.isMissed
            ? (Icons.call_missed_rounded, t.destructive, 'Missed')
            : (Icons.call_received_rounded, colors.success, 'Incoming');
    final kind = log.isVideo ? 'video' : 'voice';

    return ShadcnListTile(
      leading: UserAvatar(name: log.peerName, imageUrl: log.peerPic, size: 48),
      title: Text(name, style: log.isMissed ? TextStyle(color: t.destructive) : null),
      subtitle: Row(
        children: [
          Icon(directionIcon, size: 16, color: directionColor),
          const SizedBox(width: 4),
          Flexible(child: Text([direction, if (time.isNotEmpty) time].join(' · '))),
        ],
      ),
      trailing: onCallBack == null
          ? Icon(log.isVideo ? Icons.videocam_outlined : Icons.call_outlined, size: 20)
          : ShadcnButton(
              variant: ShadcnButtonVariant.ghost,
              size: ShadcnButtonSize.icon,
              tooltip: 'Call back',
              semanticLabel: 'Call $name back, $kind call',
              onPressed: onCallBack,
              child: Icon(log.isVideo ? Icons.videocam_outlined : Icons.call_outlined, size: 22, color: t.primary),
            ),
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: '$direction $kind call, $name, $time. Long press to delete',
    );
  }
}
