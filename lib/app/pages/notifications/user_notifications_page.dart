import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/tickets/domain/entities/ticket.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../routes/app_router.dart';

/// A flat entry representing a single status change event across any ticket.
class _NotificationEntry {
  final Ticket ticket;
  final String status;
  final DateTime timestamp;
  final String updatedBy;
  final String? note;

  const _NotificationEntry({
    required this.ticket,
    required this.status,
    required this.timestamp,
    required this.updatedBy,
    this.note,
  });
}

/// Derives a flat, time-sorted list of status-change notifications from
/// the current user's tickets (most recent first).
final userNotificationsProvider =
    Provider<AsyncValue<List<_NotificationEntry>>>((ref) {
  final ticketsAsync = ref.watch(userTicketsProvider);
  return ticketsAsync.whenData((tickets) {
    final entries = <_NotificationEntry>[];

    for (final ticket in tickets) {
      if (ticket.statusLogs == null) continue;
      for (final log in ticket.statusLogs!) {
        entries.add(
          _NotificationEntry(
            ticket: ticket,
            status: log.status,
            timestamp: log.timestamp,
            updatedBy: log.updatedBy,
            note: log.note,
          ),
        );
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  });
});

class UserNotificationsPage extends ConsumerWidget {
  const UserNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 72,
                    color: cs.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perubahan status tiket Anda akan\nmuncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _NotificationCard(
                entry: entry,
                onTap: () => context.pushNamed(
                  AppRoutes.userTicketDetail,
                  extra: entry.ticket,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationEntry entry;
  final VoidCallback onTap;

  const _NotificationCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusColor, _, statusLabel) = _statusStyle(context, entry.status);
    final timeStr =
        DateFormat('dd MMM yyyy, HH:mm').format(entry.timestamp);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(entry.status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket issue title
                    Text(
                      entry.ticket.issue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status change description
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Status berubah menjadi '),
                          TextSpan(
                            text: statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${entry.note}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant.withAlpha(150),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'open' => Icons.hourglass_empty_rounded,
      'diproses' => Icons.pending_actions_rounded,
      'selesai' => Icons.check_circle_rounded,
      'ditolak' => Icons.cancel_rounded,
      _ => Icons.help_outline_rounded,
    };
  }

  (Color, Color, String) _statusStyle(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'open' => (cs.primary, cs.onPrimary, 'Menunggu'),
      'diproses' => (cs.secondary, cs.onSecondary, 'Diproses'),
      'selesai' => (cs.tertiary, cs.onTertiary, 'Selesai'),
      'ditolak' => (cs.error, cs.onError, 'Ditolak'),
      _ => (cs.outline, cs.surface, status),
    };
  }
}
