import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class PrintedViewScreen extends StatefulWidget {
  final double totalFunds;
  final Map<String, Map<String, dynamic>> allocations;
  final String officerRole;
  final List<Map<String, dynamic>> history;

  const PrintedViewScreen({
    super.key,
    required this.totalFunds,
    required this.allocations,
    required this.officerRole,
    required this.history,
  });

  @override
  State<PrintedViewScreen> createState() => _PrintedViewScreenState();
}

class _PrintedViewScreenState extends State<PrintedViewScreen> {
  late double _totalFunds;
  late Map<String, Map<String, dynamic>> _allocations;
  late List<Map<String, dynamic>> _history;

  final GlobalKey _receiptKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalFunds = widget.totalFunds;
    _allocations = widget.allocations;
    _history = widget.history;
  }

  void updateSnapshot(
    double newTotal,
    Map<String, Map<String, dynamic>> newAllocations,
    List<Map<String, dynamic>> newHistory,
  ) {
    setState(() {
      _totalFunds = newTotal;
      _allocations = newAllocations;
      _history = newHistory;
    });
  }

  List<Map<String, dynamic>> _deductionsFor(String category) {
    return _history
        .where((h) => h['type'] == 'EXPENSE' && h['category'] == category)
        .toList();
  }

  Future<void> _saveAndShareImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Receipt not ready yet');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final fileName =
          'CSO_Receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      await Gal.putImageBytes(bytes, name: fileName);

      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'image/png',
      );

      if (!mounted) return;
      await Share.shareXFiles([
        xFile,
      ], text: 'CSO Finance — Fund Summary');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt saved to gallery')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save receipt: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Builder(
        builder: (context) {
          final palette = context.colors;
          return Scaffold(
            backgroundColor: palette.bgDeep,
            appBar: AppBar(title: const Text('Fund Summary')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _buildReceipt(context),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'This is a snapshot of the current fund summary. You can save it as an image for your records.',
                    style: AppText.body(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: _isSaving ? 'Saving…' : 'Save and Share Image',
                    onPressed: _isSaving ? null : _saveAndShareImage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceipt(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.all(0.5),
                child: Image.asset(
                  'assets/CSO.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.black87,
                      size: 20,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CSO Finance',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _plainRow('Generated', formatDateTime(DateTime.now())),
          _plainRow('Officer', widget.officerRole),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          _plainRow('Total Funds', formatCurrency(_totalFunds), bold: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          ..._allocations.entries.map(
            (e) => _categoryBlock(e.key, e.value['remaining'] as double),
          ),
        ],
      ),
    );
  }

  Widget _categoryBlock(String category, double remaining) {
    final deductions = _deductionsFor(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _plainRow(category, formatCurrency(remaining), bold: true),
          for (final d in deductions)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d['desc'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${formatCurrency(d['amount'] as double)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _plainRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
