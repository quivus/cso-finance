import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final VoidCallback? onReject;
  final VoidCallback? onValid;

  CurrencyInputFormatter({this.onReject, this.onValid});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(',', '');

    if (digitsOnly.isEmpty) {
      onValid?.call();
      return newValue.copyWith(text: '');
    }

    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(digitsOnly)) {
      onReject?.call();
      return oldValue;
    }

    onValid?.call();

    final parts = digitsOnly.split('.');
    final wholePart = parts[0];
    final hasDot = digitsOnly.contains('.');
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      final posFromEnd = wholePart.length - i;
      buffer.write(wholePart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }

    var formatted = buffer.toString();
    if (hasDot) {
      formatted = '$formatted.$decimalPart';
    }

    final rawCursor = newValue.selection.end < 0
        ? newValue.text.length
        : newValue.selection.end.clamp(0, newValue.text.length);
    final significantBeforeCursor = newValue.text
        .substring(0, rawCursor)
        .replaceAll(',', '')
        .length;
    final newOffset = _offsetForSignificantCount(
      formatted,
      significantBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  int _offsetForSignificantCount(String formatted, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',') {
        seen++;
        if (seen == count) return i + 1;
      }
    }
    return formatted.length;
  }
}

bool isValidTextEntry(String value, {int minLength = 2}) {
  final trimmed = value.trim();
  if (trimmed.length < minLength) return false;
  return RegExp(r'[A-Za-z]').hasMatch(trimmed);
}

double parseCurrencyInput(String text) {
  final cleaned = text.replaceAll(',', '');
  return double.tryParse(cleaned) ?? 0;
}
