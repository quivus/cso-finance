import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceStore {
  FinanceStore._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final DocumentReference<Map<String, dynamic>> _financeDoc = _db
      .collection('finance')
      .doc('main');

  static CollectionReference<Map<String, dynamic>> get _historyCol =>
      _financeDoc.collection('history');

  static const Map<String, double> defaultCategoryPercentages = {
    'Event Operations & Materials': 0.30,
    'Promotional Material': 0.10,
    'Guest Tokens & Recognition': 0.10,
    'Organizational Supplies': 0.10,
    'Emergency & Contingency Fund': 0.10,
    'Training & Officer Development': 0.15,
    'Documentation': 0.05,
    'Savings & Future Projects': 0.10,
  };

  static Map<String, Map<String, dynamic>> _zeroedAllocations() {
    return defaultCategoryPercentages.map(
      (key, pct) => MapEntry(key, {'pct': pct, 'remaining': 0.0}),
    );
  }

  static Future<void> ensureInitialized() async {
    final snap = await _financeDoc.get();
    if (!snap.exists) {
      await _financeDoc.set({
        'totalFunds': 0.0,
        'allocations': _zeroedAllocations(),
      });
    }
  }

  static Stream<Map<String, dynamic>> watchSummary() {
    return _financeDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) {
        return {'totalFunds': 0.0, 'allocations': _zeroedAllocations()};
      }
      final totalFunds = (data['totalFunds'] as num?)?.toDouble() ?? 0.0;
      final allocRaw =
          (data['allocations'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final allocations = allocRaw.map((key, value) {
        final v = Map<String, dynamic>.from(value as Map);
        return MapEntry(key, <String, dynamic>{
          'pct': (v['pct'] as num).toDouble(),
          'remaining': (v['remaining'] as num).toDouble(),
        });
      });
      return {'totalFunds': totalFunds, 'allocations': allocations};
    });
  }

  static Stream<List<Map<String, dynamic>>> watchHistory() {
    return _historyCol.orderBy('time', descending: true).snapshots().map((
      snap,
    ) {
      return snap.docs.map((doc) {
        final data = doc.data();
        final time = data['time'];
        return <String, dynamic>{
          'id': doc.id,
          'type': data['type'],
          'desc': data['desc'],
          'amount': (data['amount'] as num).toDouble(),
          'time': time is Timestamp ? time.toDate() : DateTime.now(),
          if (data['category'] != null) 'category': data['category'],
          if (data['notes'] != null) 'notes': data['notes'],

          if (data['photoPath'] != null) 'photoPath': data['photoPath'],
        };
      }).toList();
    });
  }

  static Future<void> addFunds({
    required String source,
    required double amount,
    String? notes,
    required String photoPath,
  }) async {
    final historyRef = _historyCol.doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_financeDoc);
      final data = snap.data() ?? <String, dynamic>{};
      final totalFunds = (data['totalFunds'] as num?)?.toDouble() ?? 0.0;
      final allocRaw =
          (data['allocations'] as Map<String, dynamic>?) ??
          _zeroedAllocations();

      final newAlloc = <String, dynamic>{};
      allocRaw.forEach((key, value) {
        final v = Map<String, dynamic>.from(value as Map);
        final pct = (v['pct'] as num).toDouble();
        final remaining = (v['remaining'] as num).toDouble();
        newAlloc[key] = {'pct': pct, 'remaining': remaining + amount * pct};
      });

      tx.set(_financeDoc, {
        'totalFunds': totalFunds + amount,
        'allocations': newAlloc,
      }, SetOptions(merge: true));

      tx.set(historyRef, {
        'type': 'INCOME',
        'desc': source,
        'amount': amount,
        'time': Timestamp.now(),
        'photoPath': photoPath,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
    });
  }

  static Future<void> addExpense({
    required String category,
    required String product,
    required double amount,
    required String photoPath,
  }) async {
    final historyRef = _historyCol.doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_financeDoc);
      final data = snap.data() ?? <String, dynamic>{};
      final totalFunds = (data['totalFunds'] as num?)?.toDouble() ?? 0.0;
      final allocRaw = Map<String, dynamic>.from(
        (data['allocations'] as Map<String, dynamic>?) ?? _zeroedAllocations(),
      );

      final catRaw = allocRaw[category];
      if (catRaw == null) {
        throw StateError('Unknown allocation category: $category');
      }
      final cat = Map<String, dynamic>.from(catRaw as Map);
      final pct = (cat['pct'] as num).toDouble();
      final remaining = (cat['remaining'] as num).toDouble();
      allocRaw[category] = {'pct': pct, 'remaining': remaining - amount};

      tx.set(_financeDoc, {
        'totalFunds': totalFunds - amount,
        'allocations': allocRaw,
      }, SetOptions(merge: true));

      tx.set(historyRef, {
        'type': 'EXPENSE',
        'category': category,
        'desc': product,
        'amount': amount,
        'time': Timestamp.now(),
        'photoPath': photoPath,
      });
    });
  }

  static Future<void> resetAll() async {
    final historySnap = await _historyCol.get();
    final batch = _db.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_financeDoc, {
      'totalFunds': 0.0,
      'allocations': _zeroedAllocations(),
    });
    await batch.commit();
  }
}
