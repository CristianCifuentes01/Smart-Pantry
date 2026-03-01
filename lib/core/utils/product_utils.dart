import 'package:flutter/material.dart';

class ProductUtils {
  static Color getStatusColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red; // Vencido
    if (daysLeft <= 2) return Colors.orange; // Crítico (0-2 días)
    if (daysLeft <= 5) return Colors.yellow; // Atención (3-5 días)
    return Colors.green; // Fresco (+5 días)
  }
}
