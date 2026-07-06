import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_upload_field.dart';
import '../widgets/currency_input_formatter.dart';

class AuditFormScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> allocations;
  final Function(
    String category,
    String product,
    double amount,
    String photoPath,
  )
  onSave;

  const AuditFormScreen({
    super.key,
    required this.allocations,
    required this.onSave,
  });

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  String? _category;
  String? _photoPath;
  final _product = TextEditingController();
  final _amount = TextEditingController();

  bool _categoryError = false;
  bool _productError = false;
  String _productErrorText = 'Enter a product name';
  bool _amountError = false;
  String _amountErrorText = 'Enter a valid amount';
  bool _photoError = false;

  @override
  void dispose() {
    _product.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await pickAndStorePhoto(context);
    if (path != null) {
      setState(() {
        _photoPath = path;
        _photoError = false;
      });
    }
  }

  InputDecoration _decoration({
    required bool hasError,
    String? hintText,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    final palette = context.colors;
    final borderColor = hasError ? palette.danger : palette.divider;
    final focusColor = hasError ? palette.danger : palette.primary;
    final prefixColor = Theme.of(context).brightness == Brightness.dark
        ? palette.textPrimary
        : palette.primary;
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      prefix: prefixText == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                prefixText,
                style: TextStyle(
                  color: prefixColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1,
                ),
              ),
            ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: hasError ? 1.8 : 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focusColor, width: 1.8),
      ),
    );
  }

  void _submit() {
    final category = _category;
    final product = _product.text.trim();
    final amt = parseCurrencyInput(_amount.text);

    final categoryInvalid =
        category == null || !isValidTextEntry(category, minLength: 1);
    final productEmpty = product.isEmpty;
    final productInvalid = productEmpty || !isValidTextEntry(product);
    final amountInvalid = amt <= 0;
    final photoInvalid = _photoPath == null || _photoPath!.isEmpty;

    if (categoryInvalid || productInvalid || amountInvalid || photoInvalid) {
      setState(() {
        _categoryError = categoryInvalid;
        _productError = productInvalid;
        if (productInvalid) {
          _productErrorText = productEmpty
              ? 'Enter a product name'
              : 'Enter a valid product name';
        }
        _amountError = amountInvalid;
        if (amountInvalid) _amountErrorText = 'Enter a valid amount';
        _photoError = photoInvalid;
      });
      return;
    }

    final remaining = widget.allocations[category]!['remaining'] as double;

    if (amt > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient funds! Current balance: ${formatCurrency(remaining)}',
          ),
        ),
      );
      return;
    }

    final palette = context.colors;

    if (amt == remaining) {
      showDialog(
        context: context,
        builder: (dialogContext) => appThemeScope(
          palette,
          AlertDialog(
            title: const Text('Heads up'),
            content: Text(
              'This leaves a 0 balance. Current balance: ${formatCurrency(remaining)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Discard'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSave(category, product, amt, _photoPath!);
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      );
    } else {
      widget.onSave(category, product, amt, _photoPath!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Builder(
        builder: (context) {
          final palette = context.colors;
          final categories = widget.allocations.keys.toList();
          final selectedIndex = _category == null
              ? -1
              : categories.indexOf(_category!);
          final selectedRemaining = _category == null
              ? null
              : widget.allocations[_category!]!['remaining'] as double;
          final color = selectedIndex >= 0
              ? categoryColor(context, selectedIndex)
              : palette.primary;

          return Scaffold(
            backgroundColor: palette.bgDeep,
            appBar: AppBar(title: const Text('Particulars')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Category'),
                  DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: palette.bgSurfaceAlt,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: palette.textPrimary,
                    ),
                    items: categories
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Row(
                              children: [
                                Icon(
                                  categoryIcon(k),
                                  size: 18,
                                  color: palette.textPrimary,
                                ),
                                const SizedBox(width: 10),
                                Text(k),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _category = v;
                      _categoryError = false;
                    }),
                    decoration: _decoration(
                      hasError: _categoryError,
                      hintText: 'Choose a folder',
                    ),
                  ),
                  if (selectedRemaining != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      color: color.withOpacity(0.10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Available balance',
                            style: AppText.bodyMuted(context),
                          ),
                          const Spacer(),
                          Text(
                            formatCurrency(selectedRemaining),
                            style: AppText.numeric(
                              context,
                            ).copyWith(color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionLabel('Product Name'),
                  TextField(
                    controller: _product,
                    onChanged: (_) {
                      if (_productError) setState(() => _productError = false);
                    },
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _decoration(
                      hasError: _productError,
                      hintText: 'What did you buy?',
                    ),
                  ),
                  if (_productError) ...[
                    const SizedBox(height: 6),
                    Text(
                      _productErrorText,
                      style: TextStyle(
                        color: palette.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionLabel('Amount'),
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      CurrencyInputFormatter(
                        onReject: () => setState(() {
                          _amountError = true;
                          _amountErrorText = 'Please input only a number';
                        }),
                        onValid: () {
                          if (_amountError) {
                            setState(() => _amountError = false);
                          }
                        },
                      ),
                    ],
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _decoration(
                      hasError: _amountError,
                      hintText: '0.00',
                      prefixText: '₱ ',
                    ),
                  ),
                  if (_amountError) ...[
                    const SizedBox(height: 6),
                    Text(
                      _amountErrorText,
                      style: TextStyle(
                        color: palette.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionLabel('Proof of Purchase'),
                  PhotoUploadField(
                    photoPath: _photoPath,
                    onTap: _pickPhoto,
                    label: 'proof of purchase',
                    hasError: _photoError,
                  ),
                  const SizedBox(height: 36),
                  GradientButton(label: 'Save Expense', onPressed: _submit),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
