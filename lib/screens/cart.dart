import 'package:flutter/material.dart';
import '../models/book.dart';
import 'user_session.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function(String shippingAddress, double total) onPlaceOrder;
  final VoidCallback onQuantityChanged;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onPlaceOrder,
    required this.onQuantityChanged,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController promoController = TextEditingController();

  double discount = 0.0;
  String promoStatus = '';

  void applyPromo() {
    if (promoController.text.trim().toUpperCase() == 'SAVE10') {
      setState(() {
        discount = 0.10;
        promoStatus = '10% Promo discount applied!';
      });
    } else {
      setState(() {
        discount = 0.0;
        promoStatus = 'Invalid promo code (Try "SAVE10")';
      });
    }
  }

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  void openCheckout(double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CheckoutSheet(
          total: total,
          onOrderPlaced: (shippingAddress) {
            widget.onPlaceOrder(shippingAddress, total);

            Navigator.pop(context); // Close checkout
            Navigator.pop(context); // Back from cart
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = widget.cartItems.fold(
      0,
      (sum, item) => sum + (item.book.price * item.quantity),
    );

    double discountAmount = subtotal * discount;
    double total = subtotal - discountAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: widget.cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.book.imageUrl,
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 60,
                                      height: 80,
                                      color: const Color(0xFFF5F5F0),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.menu_book,
                                        color: Colors.black45,
                                        size: 24,
                                      ),
                                    ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.book.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    '\$${item.book.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1E4D3B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      widget.cartItems.removeAt(index);
                                    }

                                    widget.onQuantityChanged();
                                    setState(() {});
                                  },
                                ),

                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    item.quantity++;

                                    widget.onQuantityChanged();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: promoController,
                                decoration: InputDecoration(
                                  hintText: 'Promo code e.g. SAVE10',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            ElevatedButton(
                              onPressed: applyPromo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E4D3B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 16,
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        if (promoStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                promoStatus,
                                style: TextStyle(
                                  color: discount > 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('\$${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),

                        if (discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount (10%)',
                                  style: TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '-\$${discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E4D3B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => openCheckout(total),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E4D3B),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Checkout Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
}

// ============================================================
// CHECKOUT SHEET
// ============================================================

class CheckoutSheet extends StatefulWidget {
  final double total;
  final void Function(String shippingAddress) onOrderPlaced;

  const CheckoutSheet({
    super.key,
    required this.total,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  int currentStep = 0;

  final _addressFormKey = GlobalKey<FormState>();
  final _cardFormKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final areaController = TextEditingController();

  final cardHolderController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  String paymentMethod = 'Card';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    areaController.dispose();

    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();

    super.dispose();
  }

  void nextStep() {
    if (currentStep == 0) {
      if (_addressFormKey.currentState!.validate()) {
        setState(() {
          currentStep = 1;
        });
      }
      return;
    }

    if (currentStep == 1) {
      if (paymentMethod == 'Card') {
        if (!_cardFormKey.currentState!.validate()) {
          return;
        }
      }

      showOrderConfirmation();
    }
  }

  void showOrderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Order Confirmed')),
            ],
          ),
          content: Text(
            'Your order has been placed successfully.\n\n'
            'Total: \$${widget.total.toStringAsFixed(2)}\n\n'
            'Delivery to:\n'
            '${addressController.text}, '
            '${areaController.text}, '
            '${cityController.text}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onOrderPlaced(
                  '${addressController.text}, '
                  '${areaController.text}, '
                  '${cityController.text}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4D3B),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 45,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  if (currentStep > 0)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentStep--;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),

                  Expanded(
                    child: Text(
                      currentStep == 0 ? 'Delivery Details' : 'Payment Method',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    '${currentStep + 1}/2',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: currentStep == 0
                    ? buildDeliveryForm()
                    : buildPaymentForm(),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '\$${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4D3B),
                    ),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4D3B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      currentStep == 0 ? 'Continue' : 'Place Order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PICK SAVED ADDRESS
  // ==========================================================

  void _pickSavedAddress() {
    showModalBottomSheet(
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
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved addresses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...UserSession.shippingAddresses.map(
              (addr) => ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF1E4D3B),
                ),
                title: Text(addr['address'] ?? ''),
                subtitle: Text('${addr['area']}, ${addr['city']}'),
                onTap: () {
                  setState(() {
                    nameController.text = addr['name'] ?? '';
                    phoneController.text = addr['phone'] ?? '';
                    addressController.text = addr['address'] ?? '';
                    areaController.text = addr['area'] ?? '';
                    cityController.text = addr['city'] ?? '';
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DELIVERY FORM
  // ==========================================================

  Widget buildDeliveryForm() {
    return Form(
      key: _addressFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckoutInfoCard(
            icon: Icons.location_on_outlined,
            title: 'Where should we deliver?',
            subtitle: 'Enter your delivery details below.',
          ),

          const SizedBox(height: 20),

          if (UserSession.shippingAddresses.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickSavedAddress,
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF1E4D3B),
                ),
                label: const Text(
                  'Use a saved address',
                  style: TextStyle(color: Color(0xFF1E4D3B)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E4D3B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],

          const Text(
            'Contact information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildTextField(
            controller: nameController,
            label: 'Full Name',
            hint: 'e.g. Muhammad Asim',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          buildTextField(
            controller: phoneController,
            label: 'Phone Number',
            hint: 'e.g. 03001234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }

              if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter a valid phone number';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),

          const Text(
            'Delivery address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildTextField(
            controller: addressController,
            label: 'Street / House Address',
            hint: 'House no, street, building etc.',
            icon: Icons.home_outlined,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          buildTextField(
            controller: areaController,
            label: 'Area / Town',
            hint: 'e.g. Gulshan-e-Iqbal',
            icon: Icons.location_city_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your area';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          buildTextField(
            controller: cityController,
            label: 'City',
            hint: 'e.g. Karachi',
            icon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1E4D3B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Make sure your delivery address and phone number are correct.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E4D3B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAYMENT FORM
  // ==========================================================

  Widget buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CheckoutInfoCard(
          icon: Icons.payment_outlined,
          title: 'Choose payment method',
          subtitle: 'Select how you want to pay for your order.',
        ),

        const SizedBox(height: 18),

        paymentOption(
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard and other cards',
          icon: Icons.credit_card,
          value: 'Card',
        ),

        const SizedBox(height: 10),

        paymentOption(
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
          icon: Icons.payments_outlined,
          value: 'Cash',
        ),

        if (paymentMethod == 'Card') ...[
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Form(
              key: _cardFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Color(0xFF1E4D3B)),
                      SizedBox(width: 8),
                      Text(
                        'Card Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  buildTextField(
                    controller: cardHolderController,
                    label: 'Card Holder Name',
                    hint: 'Name as shown on card',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter card holder name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  buildTextField(
                    controller: cardNumberController,
                    label: 'Card Number',
                    hint: '1234 5678 9012 3456',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter card number';
                      }

                      String digits = value.replaceAll(' ', '');

                      if (digits.length < 13 || digits.length > 19) {
                        return 'Enter a valid card number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: buildTextField(
                          controller: expiryController,
                          label: 'Expiry Date',
                          hint: 'MM/YY',
                          icon: Icons.calendar_month_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter expiry';
                            }

                            if (!RegExp(
                              r'^(0[1-9]|1[0-2])\/\d{2}$',
                            ).hasMatch(value.trim())) {
                              return 'Use MM/YY';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: buildTextField(
                          controller: cvvController,
                          label: 'CVV / CVC',
                          hint: '123',
                          icon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter CVV';
                            }

                            if (value.length < 3 || value.length > 4) {
                              return 'Invalid CVV';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.black54),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your card details should be handled securely. For a real payment system, connect this form to a PCI-compliant payment provider instead of storing raw card details.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF1E4D3B)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivering to',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${addressController.text}, '
                      '${areaController.text}, '
                      '${cityController.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PAYMENT OPTION
  // ==========================================================

  Widget paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    bool selected = paymentMethod == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1E4D3B) : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE8F1EC)
                    : const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E4D3B)),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),

            Radio<String>(
              value: value,
              groupValue: paymentMethod,
              activeColor: const Color(0xFF1E4D3B),
              onChanged: (value) {
                setState(() {
                  paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E4D3B), width: 1.5),
        ),
      ),
    );
  }
}

// ============================================================
// INFO CARD
// ============================================================

class CheckoutInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CheckoutInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E4D3B)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
