import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/tickets/domain/entities/ticket.dart';
import '../dashboard/widgets/ticket_comments_section.dart';

class UserTicketDetailPage extends ConsumerWidget {
  final Ticket ticket;

  const UserTicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(ticket.createdAt);
    final (statusColor, _, statusLabel) = _statusStyle(context, ticket.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Tiket',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(ticket.status),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Information List
              _InfoDisplayTile(label: 'Judul Kendala', value: ticket.issue),
              const _CustomDivider(),

              _InfoDisplayTile(label: 'Deskripsi', value: ticket.description),
              const _CustomDivider(),

              _InfoDisplayTile(label: 'Dibuat pada', value: dateStr),

              if (ticket.helpdesk != null) ...[
                const _CustomDivider(),
                _InfoDisplayTile(
                  label: 'Helpdesk Ditugaskan',
                  value: ticket.helpdesk!,
                ),
              ],

              // Attachment Section
              if (ticket.attachmentUrl != null && ticket.attachmentUrl!.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Lampiran Gambar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    ticket.attachmentUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.broken_image, color: cs.onErrorContainer),
                          const SizedBox(width: 12),
                          Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: cs.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Status Change Log Timeline
              if (ticket.statusLogs != null && ticket.statusLogs!.isNotEmpty) ...[
                const SizedBox(height: 40),
                Text(
                  'Riwayat Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ticket.statusLogs!.length,
                  itemBuilder: (context, index) {
                    final log = ticket.statusLogs![index];
                    final isLast = index == ticket.statusLogs!.length - 1;
                    return _buildTimelineTile(context, log, isLast);
                  },
                ),
              ],

              // Comments Section
              TicketCommentsSection(ticketId: ticket.id),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, dynamic log, bool isLast) {
    final cs = Theme.of(context).colorScheme;
    final (logColor, _, logLabel) = _statusStyle(context, log.status);
    final logDate = DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: logColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Timeline content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: logColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    logDate,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _InfoDisplayTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoDisplayTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _CustomDivider extends StatelessWidget {
  const _CustomDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
      thickness: 0.8,
    );
  }
}
