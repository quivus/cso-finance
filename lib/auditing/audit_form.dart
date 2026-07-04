import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuditFormScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> allocations;
  final Function(String, String, double) onSave;

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
  final _product = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _product.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    if (_product.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a product or expense name')),
      );
      return;
    }

    double amt = double.tryParse(_amount.text) ?? 0;
    double remaining = widget.allocations[_category!]!['remaining'];

    if (amt <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

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
                  widget.onSave(_category!, _product.text.trim(), amt);
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
      widget.onSave(_category!, _product.text.trim(), amt);
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
                    onChanged: (v) => setState(() => _category = v),
                    decoration: const InputDecoration(
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
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'What did you buy?',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Amount'),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '₱ ',
                    ),
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
