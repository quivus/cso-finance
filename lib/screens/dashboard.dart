import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../auditing/audit_form.dart';
import '../services/finance_store.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAllocations();
    _loadPersistedData();
  }

  void _initializeAllocations() {
    _allocations = {
      'Event Operations & Materials': {'pct': 0.30, 'remaining': 0.0},
      'Promotional Material': {'pct': 0.10, 'remaining': 0.0},
      'Guest Tokens & Recognition': {'pct': 0.10, 'remaining': 0.0},
      'Organizational Supplies': {'pct': 0.10, 'remaining': 0.0},
      'Emergency & Contingency Fund': {'pct': 0.10, 'remaining': 0.0},
      'Training & Officer Development': {'pct': 0.15, 'remaining': 0.0},
      'Documentation': {'pct': 0.05, 'remaining': 0.0},
      'Savings & Future Projects': {'pct': 0.10, 'remaining': 0.0},
    };
  }

  Future<void> _loadPersistedData() async {
    final data = await FinanceStore.load();
    if (!mounted) return;

    setState(() {
      totalFunds = data['totalFunds'] as double;

      final remaining = data['remaining'] as Map<String, double>?;
      if (remaining != null) {
        remaining.forEach((key, value) {
          if (_allocations.containsKey(key)) {
            _allocations[key]!['remaining'] = value;
          }
        });
      }

      _history
        ..clear()
        ..addAll(data['history'] as List<Map<String, dynamic>>);

      _isLoading = false;
    });
  }

  Future<void> _persist() {
    return FinanceStore.save(
      totalFunds: totalFunds,
      allocations: _allocations,
      history: _history,
    );
  }

  void _addFunds(String source, double amount, {String? notes}) {
    setState(() {
      totalFunds += amount;
      _history.insert(0, {
        'type': 'INCOME',
        'desc': source,
        'amount': amount,
        'time': DateTime.now(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
      _allocations.forEach((key, val) {
        val['remaining'] += (amount * val['pct']);
      });
    });
    _persist();
  }

  void _addExpense(String category, String product, double amount) {
    setState(() {
      _allocations[category]!['remaining'] -= amount;
      totalFunds -= amount;
      _history.insert(0, {
        'type': 'EXPENSE',
        'category': category,
        'desc': product,
        'amount': amount,
        'time': DateTime.now(),
      });
    });
    _persist();
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
                            allocations: _allocations,
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
                    label: 'Reset Local Data',
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
              Text(
                'TOTAL FUNDS',
                style: AppText.caption(
                  context,
                ).copyWith(color: palette.accentCyan),
              ),
              Row(
                children: [
                  _heroIconButton(
                    context,
                    icon: Icons.history_rounded,
                    onTap: () => _showFundingHistory(context),
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
          const SizedBox(height: 14),
          Text(
            formatCurrency(totalFunds),
            style: AppText.numericLarge(
              context,
            ).copyWith(color: palette.success),
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
          onTap: () => _showCategoryHistory(context, key),
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

  void _showAddFundsDialog(BuildContext context) {
    final palette = context.colors;
    final desc = TextEditingController();
    final amt = TextEditingController();
    final notes = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => appThemeScope(
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
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. CS/IT ₱10',
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: palette.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel(
                  'Amount',
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                ),
                TextField(
                  controller: amt,
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
                    hintText: 'Add any extra detail about this funding source',
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      color: palette.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amt.text) ?? 0;
                if (amount <= 0 || desc.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a description and a valid amount'),
                    ),
                  );
                  return;
                }
                _addFunds(desc.text.trim(), amount, notes: notes.text);
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFundingHistory(BuildContext context) {
    final palette = context.colors;
    final logs = _history.where((h) => h['type'] == 'INCOME').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => appThemeScope(
        palette,
        Builder(
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
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
                            'Funding Sources',
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
                              'No funds added yet',
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
                              final noteText = log['notes'] as String?;
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
                                                formatDateTime(
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
                                          '+${formatCurrency(log['amount'] as double)}',
                                          style: AppText.numeric(
                                            context,
                                          ).copyWith(color: palette.success),
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

  void _confirmResetData(BuildContext context) {
    Navigator.pop(context);
    final palette = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => appThemeScope(
        palette,
        AlertDialog(
          title: const Text('Reset Local Data'),
          content: const Text(
            'This will permanently delete all funds, allocations, and '
            'history saved on this device. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.danger),
              onPressed: () async {
                await FinanceStore.clearAll();
                if (!mounted) return;
                setState(() {
                  totalFunds = 0.0;
                  _history.clear();
                  _initializeAllocations();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryHistory(BuildContext context, String category) {
    final palette = context.colors;
    final logs = _history.where((h) => h['category'] == category).toList();
    final index = _allocations.keys.toList().indexOf(category);
    final color = categoryColor(context, index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => appThemeScope(
        palette,
        Builder(
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
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
                            color: color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            categoryIcon(category),
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(category, style: AppText.title(context)),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: palette.divider),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'No expenses logged yet',
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
                              return AppCard(
                                color: palette.bgSurfaceAlt,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['desc'] as String,
                                            style: AppText.body(context),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            formatDateTime(
                                              log['time'] as DateTime,
                                            ),
                                            style: AppText.bodyMuted(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-${formatCurrency(log['amount'] as double)}',
                                      style: AppText.numeric(
                                        context,
                                      ).copyWith(color: palette.danger),
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
          ),
        ),
      ),
    );
  }
}
