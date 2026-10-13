import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import 'user_session.dart';

class ProfileScreen extends StatefulWidget {
  final List<Order> orders;

  const ProfileScreen({super.key, required this.orders});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color green = Color(0xFF1E4D3B);

  // =========================================================
  // USER PROFILE
  // =========================================================

  late String userName;
  late String userEmail;
  late String userPhone;

  // =========================================================
  // APP SETTINGS
  // =========================================================

  bool pushNotifications = true;
  bool emailOffers = true;

  // =========================================================
  // PAYMENT METHODS
  // =========================================================

  List<Map<String, String>> paymentMethods = [
    {"type": "Visa", "number": "**** **** **** 4242", "expiry": "08/26"},
    {"type": "Mastercard", "number": "**** **** **** 8899", "expiry": "11/25"},
  ];

  // =========================================================
  // ORDER HISTORY
  // =========================================================

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  void initState() {
    super.initState();

    // Get currently logged-in user's data
    userName = UserSession.name.isNotEmpty ? UserSession.name : 'Reader';

    userEmail = UserSession.email.isNotEmpty
        ? UserSession.email
        : 'reader@gmail.com';

    userPhone = UserSession.phone;
  }

  // =========================================================
  // PROFILE OPTION
  // =========================================================

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.35),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: green),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: userName);
    final emailCtrl = TextEditingController(text: userEmail);
    final phoneCtrl = TextEditingController(text: userPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  final newEmail = emailCtrl.text.trim();
                  final newPhone = phoneCtrl.text.trim();

                  if (newName.isEmpty || newEmail.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name and email are required.'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    userName = newName;
                    userEmail = newEmail;
                    userPhone = newPhone;
                  });

                  // Update shared user session
                  UserSession.updateProfile(
                    userName: newName,
                    userEmail: newEmail,
                    userPhone: newPhone,
                  );

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                    ),
                  );
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // YOUR ORDERS
  // =========================================================

  void _showOrdersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Order History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.orders.length,
                itemBuilder: (context, index) {
                  final order = widget.orders[index];
                  return GestureDetector(
                    onTap: () => _showOrderTracking(order),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date: ${_formatDate(order.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          'Items: ${order.items.map((e) => e.book.title).join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ADD NEW PAYMENT CARD DIALOG
  // =========================================================

  void _showAddCardDialog(BuildContext modalCtx, VoidCallback refreshModal) {
    final cardNumberCtrl = TextEditingController();
    final cardHolderCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    String selectedCardType = 'Visa';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add New Card',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCardType,
                      decoration: const InputDecoration(
                        labelText: 'Card Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: ['Visa', 'Mastercard', 'American Express']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCardType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardHolderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter cardholder name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      decoration: const InputDecoration(
                        labelText: 'Card Number (16 Digits)',
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 12) {
                          return 'Enter valid card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expiryCtrl,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (MM/YY)',
                        hintText: '08/28',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) {
                        if (val == null ||
                            !val.contains('/') ||
                            val.trim().length < 5) {
                          return 'Enter valid expiry (MM/YY)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final rawNum = cardNumberCtrl.text.trim();
                    final last4 = rawNum.length >= 4
                        ? rawNum.substring(rawNum.length - 4)
                        : rawNum;
                    final maskedNum = '**** **** **** $last4';

                    setState(() {
                      paymentMethods.add({
                        "type": selectedCardType,
                        "number": maskedNum,
                        "expiry": expiryCtrl.text.trim(),
                      });
                    });

                    refreshModal();
                    Navigator.pop(dialogCtx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment card added successfully!'),
                        backgroundColor: green,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Add Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // PAYMENT METHODS MODAL
  // =========================================================

  void _showPaymentMethodsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PAYMENT HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Payment Methods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: green),
                      onPressed: () {
                        _showAddCardDialog(ctx, () {
                          setModalState(() {});
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // PAYMENT CARDS LIST
                Expanded(
                  child: paymentMethods.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_off_outlined,
                                size: 48,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No payment methods saved',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+" above to add a new card.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: paymentMethods.length,
                          itemBuilder: (context, index) {
                            final card = paymentMethods[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.credit_card,
                                  color: green,
                                ),
                                title: Text(
                                  '${card['type']} - ${card['number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text('Expires ${card['expiry']}'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      paymentMethods.removeAt(index);
                                    });
                                    setModalState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Card removed successfully',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // ADD NEW SHIPPING ADDRESS DIALOG
  // =========================================================

  void _showAddAddressDialog(BuildContext modalCtx, VoidCallback refreshModal) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add New Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter full name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Street / House Address',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter address'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Area / Town',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter area'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter city'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      UserSession.shippingAddresses.add({
                        "name": nameCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim(),
                        "address": addressCtrl.text.trim(),
                        "area": areaCtrl.text.trim(),
                        "city": cityCtrl.text.trim(),
                      });
                    });

                    refreshModal();
                    Navigator.pop(dialogCtx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address added successfully!'),
                        backgroundColor: green,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Add Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // SHIPPING ADDRESSES MODAL
  // =========================================================

  void _showAddressesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ADDRESS HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Shipping Addresses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: green),
                      onPressed: () {
                        _showAddAddressDialog(ctx, () {
                          setModalState(() {});
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ADDRESS LIST
                Expanded(
                  child: UserSession.shippingAddresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 48,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No addresses saved',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+" above to add a new address.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: UserSession.shippingAddresses.length,
                          itemBuilder: (context, index) {
                            final addr =
                                UserSession.shippingAddresses[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  color: green,
                                ),
                                title: Text(
                                  addr['address'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${addr['area']}, ${addr['city']}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      UserSession.shippingAddresses.removeAt(
                                        index,
                                      );
                                    });
                                    setModalState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Address removed successfully',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // ORDER TRACKING
  // =========================================================

  void _showOrderTracking(Order order) {
    const steps = ['Ordered', 'Shipped', 'Out for delivery', 'Delivered'];
    final currentIndex = steps.indexOf(order.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Tracking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.id,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final completed = index <= currentIndex;
                  final isLast = index == steps.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(
                              completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: completed
                                  ? green
                                  : Theme.of(context).disabledColor,
                              size: 24,
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: completed
                                      ? green
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: completed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: completed
                                  ? Theme.of(context).textTheme.titleMedium?.color
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SETTINGS
  // =========================================================

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // PUSH NOTIFICATIONS
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Order updates and recommended books'),
                  value: pushNotifications,
                  activeColor: green,
                  onChanged: (val) {
                    setState(() {
                      pushNotifications = val;
                    });
                    setModalState(() {});
                  },
                ),

                // EMAIL OFFERS
                SwitchListTile(
                  title: const Text('Email Deals & Promotions'),
                  subtitle: const Text('Get discount coupons via email'),
                  value: emailOffers,
                  activeColor: green,
                  onChanged: (val) {
                    setState(() {
                      emailOffers = val;
                    });
                    setModalState(() {});
                  },
                ),

                // DARK MODE
                ValueListenableBuilder<bool>(
                  valueListenable: UserSession.darkMode,
                  builder: (context, isDark, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: Text(
                        isDark
                            ? 'Dark theme is ON'
                            : 'Enable dark color palette',
                      ),
                      value: isDark,
                      activeColor: green,
                      onChanged: (val) {
                        UserSession.setDarkMode(val);
                        setModalState(() {});
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // HELP & FAQ
  // =========================================================

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const ExpansionTile(
              title: Text('How long does shipping take?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Standard shipping takes 3-5 business days.'),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Can I return a book?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Yes, returns are accepted within 30 days of receipt.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('How do promo codes work?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Apply promo codes like "SAVE10" during checkout.',
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.email_outlined, color: green),
                label: const Text(
                  'Contact Customer Care',
                  style: TextStyle(color: green),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support request sent!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // Capture navigator before the async gap.
              final rootNavigator = Navigator.of(context);

              // Sign out of Firebase and clear the local session.
              await AuthService.instance.signOut();
              UserSession.logout();

              if (ctx.mounted) Navigator.pop(ctx);

              rootNavigator.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : 'Reader';
    final displayEmail = userEmail.isNotEmpty ? userEmail : 'reader@gmail.com';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // PROFILE HEADER
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: green,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showEditProfileModal,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16, color: green),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),

                Text(
                  displayEmail,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 28),

                // OPTIONS
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Name, email, and phone number',
                  onTap: _showEditProfileModal,
                ),

                _buildProfileOption(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your Orders',
                  subtitle: '${widget.orders.length} past orders',
                  onTap: _showOrdersModal,
                ),

                _buildProfileOption(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  subtitle: '${paymentMethods.length} cards saved',
                  onTap: _showPaymentMethodsModal,
                ),

                _buildProfileOption(
                  icon: Icons.location_on_outlined,
                  title: 'Shipping Addresses',
                  subtitle: '${UserSession.shippingAddresses.length} saved',
                  onTap: _showAddressesModal,
                ),

                _buildProfileOption(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Notifications & preferences',
                  onTap: _showSettingsModal,
                ),

                _buildProfileOption(
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  subtitle: 'Support & terms',
                  onTap: _showHelpModal,
                ),

                const SizedBox(height: 20),

                // LOGOUT
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _logout,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
