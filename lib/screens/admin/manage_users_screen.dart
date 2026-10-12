import 'package:flutter/material.dart';
import '../user_session.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchCtl = TextEditingController();
  String _q = '';

  final List<Color> _palette = [
    Colors.green,
    Colors.brown,
    Colors.blue,
    Colors.red,
  ];

  List<Map<String, String>> get _users => UserSession.users;

  List<Map<String, String>> get _vis {
    if (_q.isEmpty) return _users;
    var needle = _q.toLowerCase();
    var out = <Map<String, String>>[];
    var i = 0;
    while (i < _users.length) {
      var u = _users[i];
      var n = u['name'].toString().toLowerCase();
      var e = u['email'].toString().toLowerCase();
      if (n.contains(needle) || e.contains(needle)) out.add(u);
      i++;
    }
    return out;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _confirmDelete(int idx) {
    var u = _users[idx];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove user?'),
        content: Text('Remove ${u['name']} from the platform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _users.removeAt(idx));
              Navigator.pop(context);
              _snack('${u['name']} removed');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleRole(int idx) {
    setState(() {
      _users[idx]['role'] = _users[idx]['role'] == 'Admin'
          ? 'Customer'
          : 'Admin';
    });
    _snack('Role changed to ${_users[idx]['role']}');
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var items = _vis;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Users',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Search users',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      var u = items[i];
                      var realIdx = _users.indexOf(u);
                      var isAdm = u['role'] == 'Admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  _palette[realIdx % _palette.length],
                              child: Text(
                                u['name'].toString().substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    u['email'].toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleRole(realIdx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdm
                                      ? const Color(0xFF1F3A2E)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  u['role'].toString(),
                                  style: TextStyle(
                                    color: isAdm
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () => _confirmDelete(realIdx),
                            ),
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
