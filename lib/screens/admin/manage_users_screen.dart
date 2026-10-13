import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../user_session.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final service = AdminService.instance;
  List<Map<String, dynamic>> users = [];
  String query = '';
  bool loading = true, working = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  String describe(Object e) => e is StateError
      ? e.message.toString()
      : e is FirebaseException && e.code == 'permission-denied'
      ? 'Your administrator access changed. Sign in again.'
      : 'Could not update bookstore access. Please retry.';
  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await service.listUsers();
      if (!mounted) return;
      setState(() {
        users = result;
        loading = false;
      });
      UserSession.setUsersFromRecords(result);
    } catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = describe(e);
        });
    }
  }

  Future<void> action(Map<String, dynamic> user, String selected) async {
    if (working || user['protected'] == true) return;
    final name = user['name']?.toString().isNotEmpty == true
        ? user['name']
        : user['email'];
    final verb = selected == 'delete'
        ? 'Remove bookstore access for'
        : selected == 'role'
        ? 'Change role for'
        : selected == 'restore'
        ? 'Restore bookstore access for'
        : user['disabled'] == true
        ? 'Unblock'
        : 'Block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('$verb $name?'),
        content: Text(
          selected == 'delete'
              ? 'Bookstore sign-in will be blocked and saved addresses, card references, settings, cart and wishlist will be cleared. The registration profile and order history are retained for administration. The Firebase Authentication identity remains.'
              : selected == 'role'
              ? 'Admin access allows catalog and account management. Bookstore permissions update through protected database rules.'
              : 'Bookstore access will be updated. Firebase Authentication credentials remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => working = true);
    try {
      final uid = user['uid'] as String;
      if (selected == 'delete') {
        await service.removeUser(uid);
      } else if (selected == 'restore') {
        await service.restoreUser(uid);
      } else if (selected == 'role') {
        await service.changeRole(
          uid,
          user['role'] == 'Admin' ? 'Customer' : 'Admin',
        );
      } else {
        await service.setDisabled(uid, user['disabled'] != true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account updated.')));
      await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describe(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = users
        .where(
          (u) => '${u['name']} ${u['email']}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage users'),
        actions: [
          IconButton(
            onPressed: working ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          if (working) const LinearProgressIndicator(),
          if (error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? const Center(child: Text('No users to display'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final user = visible[i];
                      final name = (user['name'] ?? '').toString();
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            name.isEmpty ? 'U' : name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          name.isEmpty ? user['email'].toString() : name,
                        ),
                        subtitle: Text(
                          '${user['email']}\n${user['role']} • ${user['removed'] == true
                              ? 'Removed from bookstore'
                              : user['disabled'] == true
                              ? 'Blocked'
                              : 'Active'}',
                        ),
                        isThreeLine: true,
                        trailing: user['protected'] == true
                            ? const Icon(
                                Icons.shield_outlined,
                                semanticLabel: 'Protected account',
                              )
                            : PopupMenuButton<String>(
                                enabled: !working,
                                onSelected: (v) => action(user, v),
                                itemBuilder: (_) => [
                                  if (user['removed'] == true)
                                    const PopupMenuItem(
                                      value: 'restore',
                                      child: Text('Restore bookstore access'),
                                    )
                                  else ...[
                                    PopupMenuItem(
                                      value: 'role',
                                      enabled: user['disabled'] != true,
                                      child: Text(
                                        user['role'] == 'Admin'
                                            ? 'Make customer'
                                            : 'Make admin',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'disable',
                                      child: Text(
                                        user['disabled'] == true
                                            ? 'Unblock bookstore access'
                                            : 'Block bookstore access',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Remove from bookstore'),
                                    ),
                                  ],
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
