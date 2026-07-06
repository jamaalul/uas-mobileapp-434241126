import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/tickets/domain/entities/ticket.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';

class AdminTicketDetailPage extends ConsumerStatefulWidget {
  final Ticket ticket;

  const AdminTicketDetailPage({super.key, required this.ticket});

  @override
  ConsumerState<AdminTicketDetailPage> createState() =>
      _AdminTicketDetailPageState();
}

class _AdminTicketDetailPageState extends ConsumerState<AdminTicketDetailPage> {
  String? _selectedHelpdesk;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHelpdesk = widget.ticket.helpdesk;
  }

  Future<void> _assignHelpdesk() async {
    final helpdeskName = _selectedHelpdesk?.trim() ?? '';
    if (helpdeskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama helpdesk tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(ticketUpdateProvider.notifier)
          .updateTicket(
            ticketId: widget.ticket.id,
            helpdesk: helpdeskName,
            status: 'diproses',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Helpdesk berhasil ditugaskan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Tiket'),
        content: const Text(
          'Apakah Anda yakin ingin menolak tiket ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(ticketUpdateProvider.notifier)
          .updateTicket(ticketId: widget.ticket.id, status: 'ditolak');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil ditolak'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
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
    final isActionable = ticket.status == 'open' || ticket.status == 'diproses';
    final (statusColor, _, statusLabel) = _statusStyle(ticket.status);

    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Detail Tiket',
            style: TextStyle(
              fontWeight: FontWeight.w600
            ),
          ),
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

                    ref
                        .watch(ticketUserProvider(ticket.userId))
                        .when(
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

                    // ── Admin Actions Section ────────────────────────────
                    if (isActionable) ...[
                      const SizedBox(height: 40),
                      Text(
                        'Tindakan Admin',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ref
                          .watch(helpdeskUsersProvider)
                          .when(
                            data: (users) {
                              if (users.isEmpty) {
                                return const Text(
                                  'Tidak ada helpdesk yang tersedia',
                                );
                              }

                              final userNames = users
                                  .map((u) => u['name'] as String)
                                  .toList();
                              String? currentValue = _selectedHelpdesk;
                              if (currentValue != null &&
                                  !userNames.contains(currentValue)) {
                                currentValue = null;
                              }

                              return DropdownButtonFormField<String>(
                                value: currentValue,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: 'Pilih Helpdesk',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items: users.map((user) {
                                  return DropdownMenuItem<String>(
                                    value: user['name'] as String,
                                    child: Text(user['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedHelpdesk = value;
                                  });
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Text('Error: $error'),
                          ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _assignHelpdesk,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.assignment_ind_rounded),
                          label: const Text('Tugaskan & Proses Tiket'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              inherit:
                                  false, // ── Fixes the interpolation animation crash
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _rejectTicket,
                          icon: const Icon(Icons.cancel_rounded),
                          label: const Text('Tolak Tiket'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: cs.error),
                            foregroundColor: cs.error,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              inherit:
                                  false, // ── Fixes the interpolation animation crash
                            ),
                          ),
                        ),
                      ),
                    ],
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
