import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class PrintedViewScreen extends StatefulWidget {
  final double totalFunds;
  final String officerRole;
  final List<Map<String, dynamic>> history;

  const PrintedViewScreen({
    super.key,
    required this.totalFunds,
    required this.officerRole,
    required this.history,
  });

  @override
  State<PrintedViewScreen> createState() => _PrintedViewScreenState();
}

class _PrintedViewScreenState extends State<PrintedViewScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSaving = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.history.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(widget.history)
        ..sort(
          (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
        );
      _selectedDate = sorted.first['time'] as DateTime;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  List<Map<String, dynamic>> get _logsForSelectedDate {
    final logs = widget.history.where((h) {
      final t = h['time'] as DateTime;
      return t.year == _selectedDate.year &&
          t.month == _selectedDate.month &&
          t.day == _selectedDate.day;
    }).toList();
    logs.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );
    return logs;
  }

  Future<void> _pickDate() async {
    final palette = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: buildAppTheme(palette), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
      await Share.shareXFiles([xFile], text: 'CSO Finance — Fund Summary');

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
                  GestureDetector(
                    onTap: _pickDate,
                    child: AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: palette.accentCyan,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text('Report Date', style: AppText.body(context)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _formatFullDate(_selectedDate),
                                style: AppText.body(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: palette.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _buildReceipt(context),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Please ensure that the information is accurate and complete before sharing.',
                    style: AppText.body(context),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: _isSaving ? 'Saving…' : 'Save and Share Receipt',
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
    final logs = _logsForSelectedDate;

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
          _plainRow(
            'Date Issued:',
            formatDateTime(DateTime.now()),
            Colors.black12,
          ),
          _plainRow('Officer:', widget.officerRole, Colors.black12),
          _plainRow(
            'Fund Money Left',
            formatCurrency(widget.totalFunds),
            Colors.black12,
            bold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Center(
            child: _plainRow(
              'Record Date:',
              _formatFullDate(_selectedDate),
              Colors.black12,
              bold: true,
            ),
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No transactions recorded for this date.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...logs.map((log) => _historyEntry(log)),
        ],
      ),
    );
  }

  Widget _historyEntry(Map<String, dynamic> log) {
    final isExpense = log['type'] == 'EXPENSE';
    final time = log['time'] as DateTime;
    final desc = log['desc'] as String;
    final amount = log['amount'] as double;
    final notes = log['notes'] as String?;
    final photoPath = log['photoPath'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
              const SizedBox(width: 10),
              if (photoPath != null && photoPath.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(photoPath),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${formatCurrency(amount)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isExpense
                      ? const Color(0xFFD8453F)
                      : const Color(0xFF1F9D57),
                ),
              ),
            ],
          ),
          if (notes != null && notes.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 46),
              child: Text(
                'Notes: $notes',
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _plainRow(
    String label,
    String value,
    ui.Color black12, {
    bool bold = false,
  }) {
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

String _formatFullDate(DateTime dt) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final day = dt.day.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} $day, ${dt.year}';
}

String _formatTime(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}
