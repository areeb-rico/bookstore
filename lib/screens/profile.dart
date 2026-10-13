import '../widgets/payment_method_editor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import 'user_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.orders, this.orderUpdates});
  final List<Order> orders;
  final Listenable? orderUpdates;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final service = UserDataService.instance;
  bool busy = false;
  void message(String value) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<bool> save(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      final detail = e is ArgumentError
          ? e.message.toString()
          : e is FirebaseAuthException
          ? switch (e.code) {
              'invalid-credential' ||
              'wrong-password' => 'The current password is incorrect.',
              'email-already-in-use' =>
                'That email is already used by another account.',
              'too-many-requests' =>
                'Too many attempts. Please try again later.',
              'network-request-failed' =>
                'Check your connection and try again.',
              _ => 'Could not update your account. Sign in again and retry.',
            }
          : 'Could not save changes. Check your input and connection, then try again.';
      message(detail);
      return false;
    }
  }

  InputDecoration field(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  Future<void> editProfile() async {
    final name = TextEditingController(text: UserSession.name);
    final phone = TextEditingController(text: UserSession.phone);
    final form = GlobalKey<FormState>();
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: name,
                    maxLength: 120,
                    decoration: field('Full name'),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Enter at least two characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    maxLength: 30,
                    keyboardType: TextInputType.phone,
                    decoration: field('Phone number'),
                  ),
                  const SizedBox(height: 12),
                  Text(UserSession.email),
                  TextButton(
                    onPressed: saving ? null : changeEmail,
                    child: const Text('Change email'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            update(() => saving = true);
                            final ok = await save(
                              () => service.saveProfile(name.text, phone.text),
                            );
                            if (!sheet.mounted) return;
                            update(() => saving = false);
                            if (ok) {
                              Navigator.pop(sheet);
                              message('Profile saved.');
                            }
                          },
                    child: Text(saving ? 'Saving...' : 'Save profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Dispose after the route's closing transition has finished.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    name.dispose();
    phone.dispose();
  }

  Future<void> changeEmail() async {
    final email = TextEditingController();
    final password = TextEditingController();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Change email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirm your password. A verification link will be sent to the new email.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: field('New email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: field('Current password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (email.text.trim().isEmpty || password.text.isEmpty)
                        return;
                      update(() => saving = true);
                      final ok = await save(
                        () => service.requestEmailChange(
                          email.text,
                          password.text,
                        ),
                      );
                      if (!dialog.mounted) return;
                      update(() => saving = false);
                      if (ok) {
                        Navigator.pop(dialog);
                        message(
                          'Verify the new email, then sign out and log in again.',
                        );
                      }
                    },
              child: Text(saving ? 'Sending...' : 'Send verification'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    email.dispose();
    password.dispose();
  }

  Future<void> addressForm({Map<String, String>? existing}) async {
    const labels = {
      'name': 'Recipient name',
      'phone': 'Phone number',
      'address': 'Street / house address',
      'area': 'Area / town',
      'city': 'City',
    };
    final fields = {
      for (final key in labels.keys)
        key: TextEditingController(text: existing?[key] ?? ''),
    };
    final form = GlobalKey<FormState>();
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Add address' : 'Edit address',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final key in labels.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: fields[key],
                        maxLength: key == 'address'
                            ? 300
                            : key == 'phone'
                            ? 30
                            : 120,
                        keyboardType: key == 'phone'
                            ? TextInputType.phone
                            : TextInputType.text,
                        decoration: field(labels[key]!),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required'
                            : key == 'phone' &&
                                  v.replaceAll(RegExp(r'\D'), '').length < 10
                            ? 'Enter a valid phone'
                            : null,
                      ),
                    ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            update(() => saving = true);
                            final ok = await save(
                              () => service.saveAddress({
                                for (final key in fields.keys)
                                  key: fields[key]!.text,
                              }, id: existing?['id']),
                            );
                            if (!sheet.mounted) return;
                            update(() => saving = false);
                            if (ok) {
                              Navigator.pop(sheet);
                              message('Address saved.');
                            }
                          },
                    child: Text(saving ? 'Saving...' : 'Save address'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (final ctl in fields.values) {
      ctl.dispose();
    }
  }

  Future<void> confirmRemove(
    String title,
    Future<void> Function() action,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (accepted == true && await save(action)) message('Removed.');
  }

  void addresses() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * .75,
      child: AnimatedBuilder(
        animation: UserSession.profileChanges,
        builder: (context, _) => Column(
          children: [
            ListTile(
              title: const Text('Shipping addresses'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => addressForm(),
              ),
            ),
            Expanded(
              child: UserSession.shippingAddresses.isEmpty
                  ? const Center(child: Text('No saved addresses'))
                  : ListView(
                      children: [
                        for (final address in UserSession.shippingAddresses)
                          ListTile(
                            title: Text(
                              '${address['name']} — ${address['address']}',
                            ),
                            subtitle: Text(
                              '${address['area']}, ${address['city']}\n${address['phone']}',
                            ),
                            isThreeLine: true,
                            onTap: () => addressForm(existing: address),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => confirmRemove(
                                'Remove address?',
                                () => service.deleteAddress(address['id']!),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> addPayment() async {
    final card = await showPaymentMethodEditor(context);
    if (mounted && card != null) message('Payment method saved.');
  }

  void payments() => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SizedBox(
      height: 420,
      child: AnimatedBuilder(
        animation: UserSession.profileChanges,
        builder: (context, _) => Column(
          children: [
            ListTile(
              title: const Text('Payment methods'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: addPayment,
              ),
            ),
            Expanded(
              child: UserSession.paymentMethods.isEmpty
                  ? const Center(child: Text('No saved cards'))
                  : ListView(
                      children: [
                        for (final card in UserSession.paymentMethods)
                          ListTile(
                            leading: const Icon(Icons.credit_card),
                            title: Text(
                              '${card['brand']} •••• ${card['last4']}',
                            ),
                            subtitle: Text('Expires ${card['expiry']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => confirmRemove(
                                'Remove payment method?',
                                () =>
                                    service.deletePaymentMetadata(card['id']!),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> preference(String key, bool value) async {
    if (busy) return;
    setState(() => busy = true);
    await save(() => service.savePreference(key, value));
    if (mounted) setState(() => busy = false);
  }

  void settings() => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => AnimatedBuilder(
      animation: Listenable.merge([service, UserSession.profileChanges]),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Settings')),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: UserSession.darkMode.value,
            onChanged: (v) => preference('darkMode', v),
          ),
          SwitchListTile(
            title: const Text('In-app order alerts'),
            subtitle: const Text(
              'Show order status alerts while using the app',
            ),
            value: UserSession.pushNotifications,
            onChanged: (v) => preference('pushNotifications', v),
          ),
          SwitchListTile(
            title: const Text('Email offers'),
            value: UserSession.emailOffers,
            onChanged: (v) => preference('emailOffers', v),
          ),
        ],
      ),
    ),
  );

  void orders() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * .75,
      child: AnimatedBuilder(
        animation: widget.orderUpdates ?? UserSession.profileChanges,
        builder: (context, _) => Column(
          children: [
            const ListTile(title: Text('Your order history')),
            Expanded(
              child: widget.orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : ListView(
                      children: [
                        for (final order in widget.orders)
                          ListTile(
                            title: Text(order.id),
                            subtitle: Text(
                              '${order.status} • \$${order.total.toStringAsFixed(2)}\n${order.date.toLocal().toString().split(' ').first}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => orderDetails(order),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
  void orderDetails(Order order) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * .8,
      child: AnimatedBuilder(
        animation: widget.orderUpdates ?? UserSession.profileChanges,
        builder: (context, _) {
          final current =
              widget.orders.where((o) => o.id == order.id).firstOrNull ?? order;
          final index = Order.statuses.indexOf(current.status);
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
                    i <= index
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
  void help() => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => const SingleChildScrollView(
      child: Column(
        children: [
          ListTile(title: Text('Help & FAQ')),
          ExpansionTile(
            title: Text('How can I track an order?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Open Your Orders and tap an order to see its latest status.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How do promo codes work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Enter SAVE10 in your cart for the available 10% promotion.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How can I change my email?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Use Change email in Edit Profile, verify the new address, then sign in again.',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> logout() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await AuthService.instance.signOut();
      UserSession.logout();
      if (mounted) navigator.pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (_) {
      message('Could not sign out. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([service, UserSession.profileChanges]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 38,
            child: Text(
              UserSession.name.isEmpty
                  ? 'U'
                  : UserSession.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            UserSession.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(UserSession.email, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (service.loading) const LinearProgressIndicator(),
          if (service.error != null)
            ListTile(
              title: Text(service.error!),
              trailing: TextButton(
                onPressed: () => service.bind(UserSession.uid),
                child: const Text('Retry'),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            subtitle: const Text('Name, phone and verified email changes'),
            onTap: editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Your Orders'),
            subtitle: Text('${widget.orders.length} orders'),
            onTap: orders,
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Shipping Addresses'),
            subtitle: Text('${UserSession.shippingAddresses.length} saved'),
            onTap: addresses,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Order notifications'),
            subtitle: Text(
              '${widget.orders.where((order) => order.userId == UserSession.uid && UserSession.orderReadStatus[order.id] != order.status).length} unread updates',
            ),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment Methods'),
            subtitle: Text('${UserSession.paymentMethods.length} saved cards'),
            onTap: payments,
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: settings,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & FAQ'),
            onTap: help,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: logout,
          ),
        ],
      ),
    ),
  );
}
