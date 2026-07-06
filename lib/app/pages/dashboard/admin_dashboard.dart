import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/tickets/domain/entities/ticket.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../routes/app_router.dart';
import 'admin_ticket_detail.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  static const _tabs = [
    (label: 'Menunggu', status: 'open'),
    (label: 'Diproses', status: 'diproses'),
    (label: 'Selesai', status: 'selesai'),
    (label: 'Ditolak', status: 'ditolak'),
  ];

  @override
  Widget build(BuildContext context) {
    final ticketCounts = ref.watch(allTicketCountsProvider);
    final userTickets = ref.watch(allTicketsProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.goNamed(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 400,
                child: ticketCounts.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (counts) => GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildStatusCard(
                        context: context,
                        label: 'Menunggu',
                        status: 'open',
                        count: counts['open'] ?? 0,
                        icon: Icons.hourglass_empty_rounded,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        onColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                      _buildStatusCard(
                        context: context,
                        label: 'Diproses',
                        status: 'diproses',
                        count: counts['diproses'] ?? 0,
                        icon: Icons.pending_actions_rounded,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        onColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      _buildStatusCard(
                        context: context,
                        label: 'Selesai',
                        status: 'selesai',
                        count: counts['selesai'] ?? 0,
                        icon: Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        onColor: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                      _buildStatusCard(
                        context: context,
                        label: 'Ditolak',
                        status: 'ditolak',
                        count: counts['ditolak'] ?? 0,
                        icon: Icons.cancel_rounded,
                        color: Theme.of(context).colorScheme.errorContainer,
                        onColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Daftar tiket",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DefaultTabController(
                  length: _tabs.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: false,
                        tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                      ),
                      Expanded(
                        child: userTickets.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) =>
                              Center(child: Text('Error: $e')),
                          data: (tickets) => TabBarView(
                            children: _tabs.map((t) {
                              final filtered = tickets
                                  .where((tk) => tk.status == t.status)
                                  .toList();
                              return _buildTicketList(filtered);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.userCreateTicket),
        child: const Icon(Icons.add),
      ),
      // bottomNavigationBar: NavigationBar(
      //   selectedIndex: _selectedIndex,
      //   onDestinationSelected: (int index) {
      //     setState(() {
      //       _selectedIndex = index;
      //     });
      //   },
      //   destinations: const [
      //     NavigationDestination(
      //       icon: Icon(Icons.dashboard_outlined),
      //       selectedIcon: Icon(Icons.dashboard),
      //       label: 'Dashboard',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.confirmation_number_outlined),
      //       selectedIcon: Icon(Icons.confirmation_number),
      //       label: 'Tiket',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.person_outline),
      //       selectedIcon: Icon(Icons.person),
      //       label: 'Profil',
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Belum ada tiket',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketTile(ticket);
      },
    );
  }

  Widget _buildTicketTile(Ticket ticket) {
    final (chipColor, _, __) = _statusStyle(ticket.status);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt);

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: chipColor.withAlpha(40),
        child: Icon(
          _statusIcon(ticket.status),
          color: chipColor,
          size: 22,
        ),
      ),
      title: Text(
        ticket.issue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        dateStr,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminTicketDetailPage(ticket: ticket),
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

  Widget _buildStatusCard({
    required BuildContext context,
    required String label,
    required String status,
    required int count,
    required IconData icon,
    required Color color,
    required Color onColor,
  }) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 44, color: onColor),
              const Spacer(),
              Text(
                '$count',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: onColor.withAlpha(200),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
