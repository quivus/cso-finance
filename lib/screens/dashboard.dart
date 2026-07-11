import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../auditing/audit_form.dart';
import '../services/finance_store.dart';
import '../widgets/photo_upload_field.dart';
import '../widgets/currency_input_formatter.dart';
import 'login.dart';
import 'printed_view.dart';

class DashboardScreen extends StatefulWidget {
  final String officerRole;

  const DashboardScreen({super.key, this.officerRole = 'Treasurer'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalFunds = 0.00;
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  late Map<String, Map<String, dynamic>> _allocations;

  StreamSubscription<Map<String, dynamic>>? _summarySub;
  StreamSubscription<List<Map<String, dynamic>>>? _historySub;

  @override
  void initState() {
    super.initState();
    _initializeAllocations();
    _initFirestoreSync();
  }

  @override
  void dispose() {
    _summarySub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  void _initializeAllocations() {
    _allocations = FinanceStore.defaultCategoryPercentages.map(
      (key, pct) => MapEntry(key, {'pct': pct, 'remaining': 0.0}),
    );
  }

  Future<void> _initFirestoreSync() async {
    await FinanceStore.ensureInitialized();
    if (!mounted) return;

    _summarySub = FinanceStore.watchSummary().listen((data) {
      if (!mounted) return;
      setState(() {
        totalFunds = data['totalFunds'] as double;
        final allocations =
            data['allocations'] as Map<String, Map<String, dynamic>>;
        allocations.forEach((key, value) {
          if (_allocations.containsKey(key)) {
            _allocations[key]!['remaining'] = value['remaining'];
          }
        });
        _isLoading = false;
      });
    });

    _historySub = FinanceStore.watchHistory().listen((history) {
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(history);
      });
    });
  }

  Future<void> _addFunds(
    String source,
    double amount, {
    String? notes,
    required String photoPath,
  }) async {
    await FinanceStore.addFunds(
      source: source,
      amount: amount,
      notes: notes,
      photoPath: photoPath,
    );
  }

  Future<void> _addExpense(
    String category,
    String product,
    double amount,
    String photoPath,
  ) async {
    await FinanceStore.addExpense(
      category: category,
      product: product,
      amount: amount,
      photoPath: photoPath,
    );
  }

  double _spentFor(String category) {
    return _history
        .where((h) => h['type'] == 'EXPENSE' && h['category'] == category)
        .fold(0.0, (sum, h) => sum + (h['amount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Builder(
        builder: (context) {
          final palette = context.colors;

          if (_isLoading) {
            return Scaffold(
              backgroundColor: palette.bgDeep,
              body: Center(
                child: CircularProgressIndicator(color: palette.primary),
              ),
            );
          }

          return Scaffold(
            backgroundColor: palette.bgDeep,
            appBar: AppBar(
              toolbarHeight: 76,
              titleSpacing: 12,
              title: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.bgSurfaceAlt,
                      border: Border.all(color: palette.divider, width: 1),
                    ),
                    padding: const EdgeInsets.all(0.5),
                    child: Image.asset(
                      'assets/CSO.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_balance_rounded,
                          size: 24,
                          color: palette.accentCyan,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'CSO FINANCE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            drawer: _buildDrawer(context),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 28),
                const SectionLabel('Allocations'),
                ..._buildAllocationTiles(context),
              ],
            ),
            floatingActionButton: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuditFormScreen(
                      allocations: _allocations,
                      onSave: _addExpense,
                    ),
                  ),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final palette = context.colors;
    return Drawer(
      backgroundColor: palette.bgSurface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CSO OFFICER',
                    style: AppText.caption(
                      context,
                    ).copyWith(color: palette.accentCyan),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.officerRole.toUpperCase(),
                    style: AppText.title(context),
                  ),
                ],
              ),
            ),
            Divider(color: palette.divider, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _drawerTile(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    label: 'Export Receipt',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrintedViewScreen(
                            totalFunds: totalFunds,
                            officerRole: widget.officerRole,
                            history: _history,
                          ),
                        ),
                      );
                    },
                  ),
                  _themeToggleTile(context),
                  _drawerTile(
                    context: context,
                    icon: Icons.delete_outline_rounded,
                    label: 'Reset Shared Data',
                    danger: true,
                    onTap: () => _confirmResetData(context),
                  ),
                ],
              ),
            ),
            Divider(color: palette.divider, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _drawerTile(
                context: context,
                icon: Icons.logout_rounded,
                label: 'Log Out',
                danger: true,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final palette = context.colors;
    final color = danger ? palette.danger : palette.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              if (!danger)
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeToggleTile(BuildContext context) {
    final palette = context.colors;
    return ValueListenableBuilder<bool?>(
      valueListenable: AppThemeController.isDark,
      builder: (context, override, _) {
        final isDark =
            override ??
            (MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
                color: palette.textPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: AppText.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: isDark,
                activeColor: palette.primary,
                onChanged: (value) => AppThemeController.set(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool showBackground = true,
  }) {
    final palette = context.colors;
    final iconColor = color ?? palette.accentCyan;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: showBackground
                ? iconColor.withOpacity(0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final palette = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: palette.accentCyan.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: palette.accentCyan,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TOTAL FUNDS',
                    style: AppText.caption(
                      context,
                    ).copyWith(color: palette.accentCyan, letterSpacing: 0.6),
                  ),
                ],
              ),
              Row(
                children: [
                  _heroIconButton(
                    context,
                    icon: Icons.history_rounded,
                    onTap: () => _showAllHistory(context),
                    color: palette.textSecondary,
                    showBackground: false,
                  ),
                  const SizedBox(width: 8),
                  _heroIconButton(
                    context,
                    icon: Icons.add_rounded,
                    onTap: () => _showAddFundsDialog(context),
                    color: palette.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatCurrency(totalFunds),
              style: AppText.numericLarge(
                context,
              ).copyWith(color: palette.success, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Available balance', style: AppText.bodyMuted(context)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllocationTiles(BuildContext context) {
    final keys = _allocations.keys.toList();
    return List.generate(keys.length, (index) {
      final key = keys[index];
      final data = _allocations[key]!;
      final remaining = data['remaining'] as double;
      final spent = _spentFor(key);
      final original = remaining + spent;
      final progress = original > 0
          ? (remaining / original).clamp(0.0, 1.0)
          : 0.0;
      final color = categoryColor(context, index);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(key), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: AppText.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(data['pct'] * 100).toStringAsFixed(0)}% of every deposit',
                      style: AppText.bodyMuted(context),
                    ),
                    const SizedBox(height: 12),
                    CategoryProgressBar(progress: progress, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(formatCurrency(remaining), style: AppText.numeric(context)),
            ],
          ),
        ),
      );
    });
  }

  InputDecoration _dialogDecoration(
    BuildContext context, {
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

  void _showAddFundsDialog(BuildContext context) {
    final palette = context.colors;
    final desc = TextEditingController();
    final amt = TextEditingController();
    final notes = TextEditingController();
    String? photoPath;
    bool descError = false;
    String descErrorText = 'Enter a funding source';
    bool amountError = false;
    String amountErrorText = 'Enter a valid amount';
    bool photoError = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => appThemeScope(
          palette,
          AlertDialog(
            title: const Text('Funding Source'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel(
                    'Source',
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                  ),
                  TextField(
                    controller: desc,
                    onChanged: (_) {
                      if (descError) setDialogState(() => descError = false);
                    },
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _dialogDecoration(
                      dialogContext,
                      hasError: descError,
                      hintText: 'e.g. CS/IT ₱10',
                      prefixIcon: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: palette.accentCyan,
                      ),
                    ),
                  ),
                  if (descError) ...[
                    const SizedBox(height: 6),
                    Text(
                      descErrorText,
                      style: TextStyle(
                        color: palette.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SectionLabel(
                    'Amount',
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                  ),
                  TextField(
                    controller: amt,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      CurrencyInputFormatter(
                        onReject: () => setDialogState(() {
                          amountError = true;
                          amountErrorText = 'Please input only a number';
                        }),
                        onValid: () {
                          if (amountError) {
                            setDialogState(() => amountError = false);
                          }
                        },
                      ),
                    ],
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _dialogDecoration(
                      dialogContext,
                      hasError: amountError,
                      hintText: '0.00',
                      prefixText: '₱ ',
                    ),
                  ),
                  if (amountError) ...[
                    const SizedBox(height: 6),
                    Text(
                      amountErrorText,
                      style: TextStyle(
                        color: palette.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SectionLabel(
                    'Notes (optional)',
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                  ),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 3,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Add any extra detail about this funding source',
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        color: palette.accentCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel(
                    'Proof of Source',
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                  ),
                  PhotoUploadField(
                    photoPath: photoPath,
                    label: 'proof of source',
                    hasError: photoError,
                    onTap: () async {
                      final path = await pickAndStorePhoto(dialogContext);
                      if (path != null) {
                        setDialogState(() {
                          photoPath = path;
                          photoError = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amount = parseCurrencyInput(amt.text);
                        final descEmpty = desc.text.trim().isEmpty;
                        final descInvalid =
                            descEmpty || !isValidTextEntry(desc.text);
                        final amountInvalid = amount <= 0;
                        final photoInvalid =
                            photoPath == null || photoPath!.isEmpty;

                        if (descInvalid || amountInvalid || photoInvalid) {
                          setDialogState(() {
                            descError = descInvalid;
                            if (descInvalid) {
                              descErrorText = descEmpty
                                  ? 'Enter a funding source'
                                  : 'Enter a valid funding source';
                            }
                            amountError = amountInvalid;
                            if (amountInvalid) {
                              amountErrorText = 'Enter a valid amount';
                            }
                            photoError = photoInvalid;
                          });
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await _addFunds(
                            desc.text.trim(),
                            amount,
                            notes: notes.text,
                            photoPath: photoPath!,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Could not save: $e')),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllHistory(BuildContext context) {
    final palette = context.colors;
    final logs = List<Map<String, dynamic>>.from(_history);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => appThemeScope(
        palette,
        Builder(
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: palette.bgSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: palette.accentCyan.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: palette.accentCyan,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Funds History',
                            style: AppText.title(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: palette.divider),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'No history yet',
                              style: AppText.bodyMuted(context),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final log = logs[i];
                              final isExpense = log['type'] == 'EXPENSE';
                              final noteText = log['notes'] as String?;
                              final photoPath = log['photoPath'] as String?;
                              final category = log['category'] as String?;

                              return AppCard(
                                color: palette.bgSurfaceAlt,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (photoPath != null &&
                                            photoPath.isNotEmpty) ...[
                                          GestureDetector(
                                            onTap: () =>
                                                _viewPhoto(context, photoPath),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(photoPath),
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stack,
                                                    ) => const SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        size: 18,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log['desc'] as String,
                                                style: AppText.body(context)
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                isExpense && category != null
                                                    ? '$category · ${formatDateTime(log['time'] as DateTime)}'
                                                    : formatDateTime(
                                                        log['time'] as DateTime,
                                                      ),
                                                style: AppText.bodyMuted(
                                                  context,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${isExpense ? '-' : '+'}${formatCurrency(log['amount'] as double)}',
                                          style: AppText.numeric(context)
                                              .copyWith(
                                                color: isExpense
                                                    ? palette.danger
                                                    : palette.success,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (noteText != null &&
                                        noteText.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        noteText,
                                        style: AppText.bodyMuted(context),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _viewPhoto(BuildContext context, String photoPath) {
    final palette = context.colors;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => appThemeScope(
          palette,
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(File(photoPath)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    Navigator.pop(context);
    final palette = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => appThemeScope(
        palette,
        AlertDialog(
          title: const Text('Reset Shared Data'),
          content: const Text(
            'This will permanently delete all funds, allocations, and '
            'history for every officer — this data is now shared in the '
            'cloud. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.danger),
              onPressed: () async {
                await FinanceStore.resetAll();
                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
