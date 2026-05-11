import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductUtils {
  static Color getStatusColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return AppColors.urgent;   // Vencido
    if (daysLeft <= 2) return AppColors.urgent;   // Crítico (0-2 días)
    if (daysLeft <= 5) return AppColors.warning;  // Atención (3-5 días)
    return AppColors.safe;                        // Fresco (+5 días)
  }

  /// Devuelve un texto descriptivo del estado de expiración
  static String getStatusText(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Vencido';
    if (daysLeft == 0) return 'Hoy';
    if (daysLeft <= 2) return 'Crítico';
    if (daysLeft <= 5) return 'Atención';
    return 'Fresco';
  }

  /// Devuelve los días restantes como texto legible
  static String getDaysLeftText(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return '${daysLeft.abs()}d vencido';
    if (daysLeft == 0) return 'Hoy';
    if (daysLeft == 1) return '1 día';
    return '$daysLeft días';
  }
}
