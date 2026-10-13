import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../screens/user_session.dart';
import '../services/user_data_service.dart';

Future<SavedPaymentMethod?> showPaymentMethodEditor(BuildContext context) =>
    showDialog<SavedPaymentMethod>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PaymentMethodEditor(),
    );

class _PaymentMethodEditor extends StatefulWidget {
  const _PaymentMethodEditor();
  @override
  State<_PaymentMethodEditor> createState() => _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends State<_PaymentMethodEditor> {
  final form = GlobalKey<FormState>();
  final last4 = TextEditingController(), expiry = TextEditingController();
  final uid = UserSession.uid;
  String brand = 'Visa';
  String? error;
  bool saving = false;
  @override
  void dispose() {
    last4.dispose();
    expiry.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (uid != UserSession.uid)
        throw StateError('Account changed. Sign in again.');
      final data = await UserDataService.instance.savePaymentMetadata(
        brand,
        last4.text.trim(),
        expiry.text.trim(),
      );
      if (!mounted) return;
      if (uid != UserSession.uid)
        throw StateError('Account changed. Sign in again.');
      setState(() => saving = false);
      Navigator.pop(context, SavedPaymentMethod.fromMap(data));
    } catch (failure) {
      if (mounted)
        setState(() {
          saving = false;
          error = failure is ArgumentError
              ? failure.message.toString()
              : failure is StateError
              ? failure.message.toString()
              : 'Payment method could not be saved. Please retry.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: const Text('Create payment method'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: brand,
                decoration: const InputDecoration(labelText: 'Card brand'),
                items: ['Visa', 'Mastercard', 'American Express']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: saving ? null : (value) => brand = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: last4,
                enabled: !saving,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Last 4 digits'),
                validator: (value) => RegExp(r'^\d{4}$').hasMatch(value ?? '')
                    ? null
                    : 'Enter exactly four digits',
              ),
              TextFormField(
                controller: expiry,
                enabled: !saving,
                maxLength: 5,
                decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                validator: (value) =>
                    RegExp(
                      r'^(0[1-9]|1[0-2])/\d{2}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Use MM/YY',
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
  );
}
