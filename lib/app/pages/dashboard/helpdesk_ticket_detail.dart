import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/tickets/domain/entities/ticket.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';

class HelpdeskTicketDetailPage extends ConsumerStatefulWidget {
  final Ticket ticket;

  const HelpdeskTicketDetailPage({super.key, required this.ticket});

  @override
  ConsumerState<HelpdeskTicketDetailPage> createState() =>
      _HelpdeskTicketDetailPageState();
}

class _HelpdeskTicketDetailPageState extends ConsumerState<HelpdeskTicketDetailPage> {
  bool _isLoading = false;

  Future<void> _completeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Tiket'),
        content: const Text(
          'Apakah Anda yakin ingin menandai tiket ini sebagai Selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(ticketUpdateProvider.notifier).updateTicket(
            ticketId: widget.ticket.id,
            status: 'selesai',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan tiket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(ticket.createdAt);
    final (statusColor, _, statusLabel) = _statusStyle(ticket.status);
    final showCompleteButton = ticket.status == 'diproses';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Tiket',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (showCompleteButton)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _completeTicket,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Selesaikan'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.tertiary,
                  foregroundColor: cs.onTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status Badge ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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

                    // ── Information List ────────────────────────────────
                    _InfoDisplayTile(
                      label: 'Judul Kendala',
                      value: ticket.issue,
                    ),
                    const _CustomDivider(),

                    _InfoDisplayTile(
                      label: 'Deskripsi',
                      value: ticket.description,
                    ),
                    const _CustomDivider(),

                    ref.watch(ticketUserProvider(ticket.userId)).when(
                          data: (user) => _InfoDisplayTile(
                            label: 'Pengirim',
                            value: user != null
                                ? (user['name'] ?? ticket.userId)
                                : ticket.userId,
                          ),
                          loading: () => const _InfoDisplayTile(
                            label: 'Pengirim',
                            value: 'Memuat...',
                          ),
                          error: (error, _) => _InfoDisplayTile(
                            label: 'Pengirim',
                            value: 'Error: $error',
                          ),
                        ),
                    const _CustomDivider(),

                    _InfoDisplayTile(label: 'Dibuat pada', value: dateStr),

                    if (ticket.helpdesk != null) ...[
                      const _CustomDivider(),
                      _InfoDisplayTile(
                        label: 'Helpdesk Ditugaskan',
                        value: ticket.helpdesk!,
                      ),
                    ],

                    // ── Attachment Section ───────────────────────────────
                    if (ticket.attachmentUrl != null &&
                        ticket.attachmentUrl!.isNotEmpty) ...[
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: cs.onErrorContainer,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── Timeline Section ─────────────────────────────────
                    if (ticket.statusLogs != null &&
                        ticket.statusLogs!.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      Text(
                        'Riwayat Status',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          final isLast =
                              index == ticket.statusLogs!.length - 1;
                          return _buildTimelineTile(context, log, isLast);
                        },
                      ),
                    ],


                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, dynamic log, bool isLast) {
    final cs = Theme.of(context).colorScheme;
    final (logColor, _, logLabel) = _statusStyle(log.status);
    final logDate = DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

  (Color, Color, String) _statusStyle(String status) {
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
