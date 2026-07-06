import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/domain/entities/user_entity.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class ManageUsersPage extends ConsumerWidget {
  const ManageUsersPage({super.key});

  static const _tabs = [
    (label: 'Admin', role: 'admin'),
    (label: 'Helpdesk', role: 'helpdesk'),
    (label: 'User', role: 'user'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kelola Pengguna",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (users) {
              return DefaultTabController(
                length: _tabs.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: false,
                      tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: _tabs.map((t) {
                          final filtered = users
                              .where((u) => u.role == t.role)
                              .toList();
                          return _buildUserList(filtered);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserEntity> users) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada pengguna', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserTile(context, user);
      },
    );
  }

  Widget _buildUserTile(BuildContext context, UserEntity user) {
    final nameTrimmed = user.name.trim();
    final initials = nameTrimmed.isNotEmpty
        ? nameTrimmed
            .split(RegExp(r'\s+'))
            .map((l) => l.isNotEmpty ? l[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final colorScheme = Theme.of(context).colorScheme;
    final avatarColor = switch (user.role) {
      'admin' => colorScheme.error,
      'helpdesk' => colorScheme.primary,
      _ => colorScheme.secondary,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: avatarColor.withAlpha(40),
        child: Text(
          initials.isNotEmpty ? initials : 'U',
          style: TextStyle(
            color: avatarColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
