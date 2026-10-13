import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/user_data_service.dart';
import 'user_session.dart';

/// The latest real order status is the notification; only read acknowledgements
/// are stored separately. No push service or server sender is required.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.orders,
    required this.updates,
  });
  final List<Order> orders;
  final Listenable updates;
  Future<void> open(BuildContext context, Order order) async {
    try {
      await UserDataService.instance.markOrderRead(order.id, order.status);
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not mark this update as read. The order may have changed; please retry.',
            ),
          ),
        );
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: AnimatedBuilder(
          animation: updates,
          builder: (context, _) {
            final current = orders
                .where((o) => o.id == order.id && o.userId == UserSession.uid)
                .firstOrNull;
            if (current == null)
              return const Center(
                child: Text('This order is no longer available.'),
              );
            final stage = Order.statuses.indexOf(current.status);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(current.id, style: Theme.of(context).textTheme.titleLarge),
                Text(current.shippingAddress),
                if (current.deliveryContact != null)
                  Text(
                    '${current.deliveryContact!.name} • ${current.deliveryContact!.phone}',
                  ),
                const Divider(),
                for (var i = 0; i < Order.statuses.length; i++)
                  ListTile(
                    leading: Icon(
                      i <= stage
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(Order.statuses[i]),
                  ),
                const Divider(),
                for (final item in current.items)
                  ListTile(
                    title: Text(item.book.title),
                    subtitle: Text(
                      '${item.quantity} × \$${item.book.price.toStringAsFixed(2)}',
                    ),
                  ),
                Text(
                  'Total: \$${current.total.toStringAsFixed(2)} • ${current.paymentLabel}',
                ),
                if (current.cardLabel != null) Text(current.cardLabel!),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([updates, UserSession.profileChanges]),
    builder: (context, _) {
      final mine = orders
          .where((order) => order.userId == UserSession.uid)
          .toList();
      mine.sort((a, b) {
        final aUnread = UserSession.orderReadStatus[a.id] != a.status;
        final bUnread = UserSession.orderReadStatus[b.id] != b.status;
        if (aUnread != bUnread) return aUnread ? -1 : 1;
        return b.date.compareTo(a.date);
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Order notifications')),
        body: mine.isEmpty
            ? const Center(
                child: Text('No orders yet. Updates will appear here.'),
              )
            : ListView.builder(
                itemCount: mine.length,
                itemBuilder: (context, index) {
                  final order = mine[index];
                  final unread =
                      UserSession.orderReadStatus[order.id] != order.status;
                  return ListTile(
                    leading: Icon(
                      unread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none,
                    ),
                    title: Text(
                      order.status,
                      style: TextStyle(
                        fontWeight: unread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${order.id}\n${order.date.toLocal().toString().split(' ').first} • \$${order.total.toStringAsFixed(2)}',
                    ),
                    isThreeLine: true,
                    trailing: unread
                        ? const Icon(Icons.circle, size: 10)
                        : null,
                    onTap: () => open(context, order),
                  );
                },
              ),
      );
    },
  );
}
