import 'package:flutter/material.dart';
import '../../models/book.dart';

class ManageOrdersScreen extends StatefulWidget {
  final List<Order> orders;

  const ManageOrdersScreen({super.key, required this.orders});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  int _filterIdx = 0;
  final List<String> _filters = ['All', 'Processing', 'Shipped', 'Delivered'];

  // filter is index-based, all is 0 so keep a special case
  List<Order> get _vis {
    if (_filterIdx == 0) return widget.orders;
    var sel = _filters[_filterIdx];
    var out = <Order>[];
    var i = 0;
    while (i < widget.orders.length) {
      if (widget.orders[i].status == sel) out.add(widget.orders[i]);
      i++;
    }
    return out;
  }

  Color _statClr(String s) {
    switch (s) {
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Processing':
        return Colors.orange;
    }
    return Colors.grey;
  }

  Future<void> _swapStatus(int idx) async {
    var o = widget.orders[idx];
    var opts = ['Processing', 'Shipped', 'Delivered'];
    var picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change status — ${o.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...opts.map(
              (s) => ListTile(
                leading: Icon(Icons.circle, size: 12, color: _statClr(s)),
                title: Text(s),
                trailing: o.status == s
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => widget.orders[idx].status = picked);
    _toast('${o.id} → $picked');
  }

  void _toast(String m) {
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
          'Orders',
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (idx) {
                  var on = _filterIdx == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterIdx = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: on ? const Color(0xFF1F3A2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: on
                                ? const Color(0xFF1F3A2E)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _filters[idx],
                          style: TextStyle(
                            color: on ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No orders here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      var o = items[i];
                      var realIdx = widget.orders.indexOf(o);
                      var c = _statClr(o.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  o.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    o.status,
                                    style: TextStyle(
                                      color: c,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${o.shippingAddress} · ${o.items.length} items',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _swapStatus(realIdx),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text(
                                    'Change status',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${o.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
