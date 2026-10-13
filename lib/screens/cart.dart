import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/checkout.dart';
import '../services/user_data_service.dart';
import '../widgets/payment_method_editor.dart';
import 'user_session.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.cartItems,
    required this.currentQuote,
    required this.onPlaceOrder,
    required this.onQuantityChanged,
    required this.updates,
    required this.unavailableCartIds,
    required this.onRemoveUnavailable,
  });
  final List<CartItem> cartItems;
  final CheckoutQuote Function(String promoCode) currentQuote;
  final Future<Order> Function(CheckoutRequest) onPlaceOrder;
  final Future<void> Function(Book, int) onQuantityChanged;
  final Listenable updates;
  final List<String> unavailableCartIds;
  final Future<void> Function() onRemoveUnavailable;
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final promo = TextEditingController();
  String promoCode = '', promoMessage = '';
  bool updating = false, checkoutOpen = false;
  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> change(Future<void> Function() action) async {
    if (updating || checkoutOpen) return;
    setState(() => updating = true);
    try {
      await action();
    } catch (_) {
      if (mounted) message('Cart could not be updated. Please retry.');
    } finally {
      if (mounted) setState(() => updating = false);
    }
  }

  void applyPromo() => setState(() {
    promoCode = promo.text.trim().toUpperCase() == 'SAVE10' ? 'SAVE10' : '';
    promoMessage = promoCode.isEmpty
        ? 'Use SAVE10 for 10% off, or checkout without a promo.'
        : 'SAVE10 applied: 10% off.';
  });
  Future<void> openCheckout() async {
    if (checkoutOpen || updating) return;
    if (widget.unavailableCartIds.isNotEmpty) {
      message('Remove unavailable books before checkout.');
      return;
    }
    final quote = widget.currentQuote(promoCode);
    try {
      quote.validate();
    } on StateError catch (e) {
      message(e.message.toString());
      return;
    }
    setState(() => checkoutOpen = true);
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => CheckoutSheet(
        quote: quote,
        updates: widget.updates,
        latestQuote: () => widget.currentQuote(promoCode),
        onOrderPlaced: widget.onPlaceOrder,
      ),
    );
    if (!mounted) return;
    setState(() => checkoutOpen = false);
    if (done == true) Navigator.pop(context);
  }

  @override
  void dispose() {
    promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.currentQuote(promoCode);
    final unavailable = widget.unavailableCartIds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: Column(
        children: [
          if (unavailable)
            MaterialBanner(
              content: const Text(
                'Some books in your cart are no longer available.',
              ),
              actions: [
                TextButton(
                  onPressed: updating
                      ? null
                      : () => change(widget.onRemoveUnavailable),
                  child: const Text('Remove unavailable'),
                ),
              ],
            ),
          Expanded(
            child: widget.cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.book.imageUrl,
                                  width: 55,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) =>
                                      const SizedBox(
                                        width: 55,
                                        height: 75,
                                        child: Icon(Icons.menu_book),
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '\$${(item.book.priceMinor / 100).toStringAsFixed(2)} each',
                                    ),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        IconButton(
                                          tooltip: item.quantity == 1
                                              ? 'Remove book'
                                              : 'Decrease quantity',
                                          onPressed: updating || checkoutOpen
                                              ? null
                                              : () => change(
                                                  () =>
                                                      widget.onQuantityChanged(
                                                        item.book,
                                                        item.quantity - 1,
                                                      ),
                                                ),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text('${item.quantity}'),
                                        IconButton(
                                          tooltip: 'Increase quantity',
                                          onPressed:
                                              updating ||
                                                  checkoutOpen ||
                                                  item.quantity >= 99
                                              ? null
                                              : () => change(
                                                  () =>
                                                      widget.onQuantityChanged(
                                                        item.book,
                                                        item.quantity + 1,
                                                      ),
                                                ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(item.book.priceMinor * item.quantity / 100).toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.cartItems.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promo,
                            enabled: !checkoutOpen,
                            decoration: const InputDecoration(
                              labelText: 'Promo code',
                              hintText: 'SAVE10',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: checkoutOpen ? null : applyPromo,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (promoMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(promoMessage),
                      ),
                    const SizedBox(height: 10),
                    _amount('Subtotal', quote.subtotalMinor),
                    if (promoCode.isNotEmpty)
                      _amount(
                        'Discount (10%)',
                        quote.subtotalMinor - quote.totalMinor,
                        discount: true,
                      ),
                    _amount('Total', quote.totalMinor),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: updating || checkoutOpen || unavailable
                            ? null
                            : openCheckout,
                        child: const Text('Checkout Now'),
                      ),
                    ),
                    const Text(
                      'Cash or card • Up to 20 different books per order',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amount(String label, int amount, {bool discount = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text('${discount ? '-' : ''}\$${(amount / 100).toStringAsFixed(2)}'),
      ],
    ),
  );
}

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.quote,
    required this.onOrderPlaced,
    required this.updates,
    required this.latestQuote,
  });
  final CheckoutQuote quote;
  final Future<Order> Function(CheckoutRequest) onOrderPlaced;
  final Listenable updates;
  final CheckoutQuote Function() latestQuote;
  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final form = GlobalKey<FormState>();
  SavedPaymentMethod? selectedCard;
  String? newlySavedCardId;
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      area = TextEditingController(),
      city = TextEditingController();
  int step = 0;
  String? selectedPaymentMethod;
  bool submitting = false, waiting = false, saveAddress = false;
  String? error, addressSaveMessage;
  Timer? waitTimer;
  CheckoutRequest? attempt;
  Order? confirmed;
  bool get stale =>
      widget.latestQuote().fingerprint != widget.quote.fingerprint;
  DeliveryContact get delivery => DeliveryContact(
    name: name.text.trim(),
    phone: phone.text.trim(),
    address: address.text.trim(),
    area: area.text.trim(),
    city: city.text.trim(),
  );
  @override
  void initState() {
    super.initState();
    name.text = UserSession.name;
    phone.text = UserSession.phone;
    widget.updates.addListener(changed);
    UserSession.profileChanges.addListener(changed);
  }

  void changed() {
    if (mounted)
      setState(() {
        final ids = UserSession.paymentMethods.map((card) => card['id']);
        if (ids.contains(newlySavedCardId)) newlySavedCardId = null;
        if (attempt == null &&
            selectedCard != null &&
            !ids.contains(selectedCard!.id) &&
            selectedCard!.id != newlySavedCardId) {
          selectedCard = null;
        }
      });
  }

  @override
  void dispose() {
    waitTimer?.cancel();
    widget.updates.removeListener(changed);
    UserSession.profileChanges.removeListener(changed);
    for (final controller in [name, phone, address, area, city]) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> next() async {
    if (submitting || confirmed != null) return;
    if (step == 0) {
      if (stale) return;
      if (form.currentState!.validate()) {
        FocusScope.of(context).unfocus();
        setState(() {
          step = 1;
          error = null;
        });
      }
      return;
    }
    if (step == 1) {
      if (stale) return;
      if (!['Cash', 'Card'].contains(selectedPaymentMethod)) {
        setState(() => error = 'Select a payment method to continue.');
        return;
      }
      if (selectedPaymentMethod == 'Card') {
        try {
          if (selectedCard == null)
            throw StateError('Create or select a payment method to continue.');
          selectedCard!.validate();
        } on StateError catch (failure) {
          setState(() => error = failure.message.toString());
          return;
        }
      }
      FocusScope.of(context).unfocus();
      setState(() {
        step = 2;
        error = null;
      });
      return;
    }
    if (stale && attempt == null) return;
    setState(() {
      submitting = true;
      error = null;
      waiting = false;
    });
    waitTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && submitting) setState(() => waiting = true);
    });
    try {
      attempt ??= CheckoutRequest(
        quote: widget.quote,
        delivery: delivery,
        paymentMethod: selectedPaymentMethod!,
        cardPayment: selectedPaymentMethod == 'Card' ? selectedCard : null,
      );
      final receipt = await widget.onOrderPlaced(attempt!);
      if (!mounted || widget.quote.uid != UserSession.uid) return;
      setState(() => confirmed = receipt);
      if (saveAddress) {
        final data = receipt.deliveryContact?.toMap();
        if (data != null &&
            !UserSession.shippingAddresses.any(
              (saved) => data.entries.every((e) => saved[e.key] == e.value),
            )) {
          try {
            await UserDataService.instance.saveAddress(data);
          } catch (_) {
            if (mounted)
              setState(
                () => addressSaveMessage =
                    'Order saved. The address could not be added to your profile.',
              );
          }
        }
      }
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is CheckoutException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : 'Order confirmation could not be received. Retry the same order or check your order history.',
        );
    } finally {
      waitTimer?.cancel();
      if (mounted)
        setState(() {
          submitting = false;
        });
    }
  }

  Future<void> pickAddress() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Saved addresses')),
            for (final saved in UserSession.shippingAddresses)
              ListTile(
                title: Text('${saved['name']} • ${saved['phone']}'),
                subtitle: Text(
                  '${saved['address']}, ${saved['area']}, ${saved['city']}',
                ),
                onTap: () => Navigator.pop(context, saved),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      name.text = selected['name'] ?? '';
      phone.text = selected['phone'] ?? '';
      address.text = selected['address'] ?? '';
      area.text = selected['area'] ?? '';
      city.text = selected['city'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final receipt = confirmed;
    return PopScope(
      canPop: !submitting,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  receipt != null
                      ? 'Order Confirmed'
                      : step == 0
                      ? 'Delivery Details'
                      : step == 1
                      ? 'Payment Method'
                      : 'Review your order',
                ),
                subtitle: receipt == null
                    ? Text('Step ${step + 1} of 3')
                    : null,
                trailing: IconButton(
                  tooltip: 'Close checkout',
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(context, receipt != null),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 20,
                  ),
                  child: receipt != null
                      ? confirmation(receipt)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (stale && !submitting)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    attempt == null
                                        ? 'Your cart or catalog changed. Return to the cart to review the latest prices and quantities.'
                                        : 'The cart changed. Retry checks whether this order was already saved; it will not place a second order.',
                                  ),
                                ),
                              ),
                            if (step == 0)
                              deliveryForm()
                            else if (step == 1)
                              paymentSelection()
                            else
                              review(),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            if (waiting && submitting)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text(
                                  'Waiting for online confirmation. Keep this screen open; do not place the order again.',
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total: \$${((receipt?.totalMinor ?? widget.quote.totalMinor) / 100).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (receipt != null)
                      FilledButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.pop(context, true),
                        child: const Text('Done'),
                      )
                    else
                      Row(
                        children: [
                          if (step > 0 && attempt == null)
                            TextButton(
                              onPressed: submitting
                                  ? null
                                  : () => setState(() {
                                      step--;
                                      error = null;
                                    }),
                              child: const Text('Back'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed:
                                submitting ||
                                    (stale && attempt == null) ||
                                    (step == 1 && selectedPaymentMethod == null)
                                ? null
                                : next,
                            child: Text(
                              submitting
                                  ? 'Saving order...'
                                  : step < 2
                                  ? 'Continue'
                                  : attempt == null
                                  ? 'Place Order'
                                  : 'Retry same order',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget deliveryForm() => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter the delivery contact and complete shipping address.'),
        if (UserSession.shippingAddresses.isNotEmpty)
          OutlinedButton.icon(
            onPressed: pickAddress,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Use a saved address'),
          ),
        field(name, 'Full name', 120, minimum: 2),
        field(phone, 'Phone number', 30, phoneField: true),
        field(address, 'House / street address', 300),
        field(area, 'Area', 120),
        field(city, 'City', 120),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Save this address to my profile'),
          value: saveAddress,
          onChanged: (value) => setState(() => saveAddress = value == true),
        ),
      ],
    ),
  );
  Widget field(
    TextEditingController controller,
    String label,
    int limit, {
    int minimum = 1,
    bool phoneField = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: TextFormField(
      controller: controller,
      maxLength: limit,
      keyboardType: phoneField ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.length < minimum || text.length > limit)
          return 'Enter a valid ${label.toLowerCase()}';
        if (phoneField &&
            (!RegExp(r'^\+?[0-9 ()-]{10,30}$').hasMatch(text) ||
                text.replaceAll(RegExp(r'\D'), '').length < 10 ||
                text.replaceAll(RegExp(r'\D'), '').length > 15))
          return 'Enter a valid phone number';
        return null;
      },
    ),
  );
  Future<void> createPaymentMethod() async {
    if (submitting || attempt != null) return;
    final card = await showPaymentMethodEditor(context);
    if (!mounted || card == null || widget.quote.uid != UserSession.uid) return;
    setState(() {
      selectedCard = card;
      newlySavedCardId =
          UserSession.paymentMethods.any((saved) => saved['id'] == card.id)
          ? null
          : card.id;
      error = null;
    });
  }

  bool usable(SavedPaymentMethod card) {
    try {
      card.validate();
      return true;
    } on StateError {
      return false;
    }
  }

  Widget paymentSelection() {
    final cards = UserSession.paymentMethods
        .map(SavedPaymentMethod.fromMap)
        .toList();
    // Acknowledged saves are selectable even before the profile stream catches up.
    if (selectedCard != null &&
        newlySavedCardId == selectedCard!.id &&
        !cards.any((card) => card.id == selectedCard!.id)) {
      cards.add(selectedCard!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select how you would like to pay.'),
        const SizedBox(height: 16),
        RadioGroup<String>(
          groupValue: selectedPaymentMethod,
          onChanged: (value) {
            if (submitting ||
                attempt != null ||
                !['Cash', 'Card'].contains(value))
              return;
            setState(() {
              selectedPaymentMethod = value;
              error = null;
            });
          },
          child: Column(
            children: [
              Card(
                child: RadioListTile<String>(
                  value: 'Cash',
                  enabled: !submitting && attempt == null,
                  selected: selectedPaymentMethod == 'Cash',
                  secondary: const Icon(Icons.payments_outlined),
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text('Pay when your order arrives.'),
                ),
              ),
              Card(
                child: RadioListTile<String>(
                  value: 'Card',
                  enabled: !submitting && attempt == null,
                  selected: selectedPaymentMethod == 'Card',
                  secondary: const Icon(Icons.credit_card_outlined),
                  title: const Text('Credit / Debit Card'),
                  subtitle: const Text('Select a saved payment method.'),
                ),
              ),
            ],
          ),
        ),
        if (selectedPaymentMethod == 'Card') ...[
          const SizedBox(height: 12),
          if (cards.isNotEmpty)
            RadioGroup<String>(
              groupValue: selectedCard?.id,
              onChanged: (id) {
                if (submitting || attempt != null) return;
                setState(() {
                  selectedCard = cards.firstWhere((card) => card.id == id);
                  error = null;
                });
              },
              child: Column(
                children: [
                  for (final card in cards)
                    RadioListTile<String>(
                      value: card.id,
                      enabled: usable(card) && !submitting && attempt == null,
                      title: Text(card.label),
                      subtitle: Text(
                        usable(card)
                            ? 'Expires ${card.expiry}'
                            : 'Expired — create another payment method',
                      ),
                    ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: submitting || attempt != null
                ? null
                : createPaymentMethod,
            icon: const Icon(Icons.add_card),
            label: const Text('Create payment method'),
          ),
        ],
      ],
    );
  }

  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        selectedPaymentMethod == 'Card'
            ? 'Payment: Credit / Debit Card'
            : 'Payment: Cash on Delivery',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (selectedPaymentMethod == 'Card' && selectedCard != null)
        Text(selectedCard!.label)
      else
        const Text('Pay when your order arrives.'),
      const SizedBox(height: 16),
      Text('${delivery.name} • ${delivery.phone}'),
      Text(delivery.formattedAddress),
      const Divider(),
      for (final item in widget.quote.items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.book.title),
          subtitle: Text(
            '${item.quantity} × \$${(item.book.priceMinor / 100).toStringAsFixed(2)}',
          ),
          trailing: Text(
            '\$${(item.book.priceMinor * item.quantity / 100).toStringAsFixed(2)}',
          ),
        ),
      if (widget.quote.promoCode.isNotEmpty)
        const Text('SAVE10: 10% off applied'),
    ],
  );
  Widget confirmation(Order order) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
      const SizedBox(height: 16),
      Text('Order: ${order.id}'),
      Text('Status: ${order.status}'),
      if (order.deliveryContact != null)
        Text(
          '${order.deliveryContact!.name} • ${order.deliveryContact!.phone}',
        ),
      Text(order.shippingAddress),
      Text('Payment: ${order.paymentLabel}'),
      if (order.cardLabel != null) Text(order.cardLabel!),
      const SizedBox(height: 16),
      const Text(
        'Track delivery in Profile → Your orders. Order updates are also available in Notifications.',
      ),
      if (addressSaveMessage != null) Text(addressSaveMessage!),
    ],
  );
}
