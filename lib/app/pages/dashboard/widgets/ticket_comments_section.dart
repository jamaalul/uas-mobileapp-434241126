import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/tickets/domain/entities/comment.dart';
import '../../../../features/tickets/presentation/providers/comment_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';

/// A shared comment thread section used across all ticket detail pages.
///
/// Renders a list of top-level comments with nested replies, and a
/// compose bar for posting new comments / replies.
class TicketCommentsSection extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketCommentsSection({super.key, required this.ticketId});

  @override
  ConsumerState<TicketCommentsSection> createState() =>
      _TicketCommentsSectionState();
}

class _TicketCommentsSectionState extends ConsumerState<TicketCommentsSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setReply(String parentId, String parentName) {
    setState(() {
      _replyToId = parentId;
      _replyToName = parentName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    _controller.clear();
    final parentId = _replyToId;
    _cancelReply();

    try {
      await ref.read(addCommentProvider.notifier).addComment(
            ticketId: widget.ticketId,
            content: text,
            userName: authState.user.name,
            parentId: parentId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final commentsAsync = ref.watch(ticketCommentsProvider(widget.ticketId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Text(
          'Komentar',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Comment list
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: cs.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }


            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                // Find parent author name for replies
                String? replyToName;
                if (comment.parentId != null) {
                  final parent = comments
                      .where((c) => c.id == comment.parentId)
                      .firstOrNull;
                  replyToName = parent?.userName;
                }
                return _CommentBubble(
                  comment: comment,
                  replyToName: replyToName,
                  onReply: () => _setReply(
                    comment.parentId ?? comment.id,
                    comment.userName,
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Gagal memuat komentar: $error',
              style: TextStyle(color: cs.error),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Reply banner
        if (_replyToName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(80),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Membalas $_replyToName',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: _cancelReply,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(Icons.close_rounded, size: 18, color: cs.primary),
                ),
              ],
            ),
          ),

        // Input bar
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: _replyToName != null
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withAlpha(100)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: _sendComment,
                icon: Icon(Icons.send_rounded, color: cs.primary),
                tooltip: 'Kirim',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single comment bubble with optional "replying to" label.
class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final String? replyToName;
  final VoidCallback onReply;

  const _CommentBubble({
    required this.comment,
    required this.onReply,
    this.replyToName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(comment.createdAt);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Replying to ..." label
          if (replyToName != null) ...[
            Row(
              children: [
                Icon(Icons.reply_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Membalas $replyToName',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onReply,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Balas',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
