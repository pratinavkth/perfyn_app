import 'package:flutter/material.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class TransactionCategories {
  const TransactionCategories._();

  static const List<TransactionCategory> expense = [
    TransactionCategory(
      label: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF8A65),
    ),
    TransactionCategory(
      label: 'Travel',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF4DB6AC),
    ),
    TransactionCategory(
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFF06292),
    ),
    TransactionCategory(
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF7986CB),
    ),
    TransactionCategory(
      label: 'Health',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE57373),
    ),
    TransactionCategory(
      label: 'Entertainment',
      icon: Icons.movie_creation_outlined,
      color: Color(0xFFFFB74D),
    ),
  ];

  static const List<TransactionCategory> income = [
    TransactionCategory(
      label: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF26A69A),
    ),
    TransactionCategory(
      label: 'Freelance',
      icon: Icons.laptop_chromebook_rounded,
      color: Color(0xFF42A5F5),
    ),
    TransactionCategory(
      label: 'Gift',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFAB47BC),
    ),
    TransactionCategory(
      label: 'Refund',
      icon: Icons.replay_rounded,
      color: Color(0xFFFF7043),
    ),
    TransactionCategory(
      label: 'Investment',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF66BB6A),
    ),
    TransactionCategory(
      label: 'Other',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF8D6E63),
    ),
  ];
}
