import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final String? iconName;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final bool compact;

  const CategoryChip({
    super.key,
    required this.category,
    this.iconName,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.compact = false,
  });

  IconData _iconForCategory() {
    switch (iconName?.toLowerCase() ?? category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
      case 'medical':
        return Icons.favorite_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'rent':
      case 'housing':
        return Icons.home_rounded;
      case 'subscriptions':
        return Icons.subscriptions_rounded;
      case 'salary':
      case 'income':
        return Icons.account_balance_wallet_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'pets':
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _colorForCategory() {
    if (color != null) return color!;
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return const Color(0xFFFF7043);
      case 'transport':
        return const Color(0xFF42A5F5);
      case 'shopping':
        return const Color(0xFFAB47BC);
      case 'entertainment':
        return const Color(0xFFFFCA28);
      case 'health':
        return const Color(0xFFEF5350);
      case 'bills':
        return const Color(0xFF78909C);
      case 'education':
        return const Color(0xFF26C6DA);
      case 'groceries':
        return const Color(0xFF66BB6A);
      case 'rent':
        return const Color(0xFF8D6E63);
      case 'salary':
        return const Color(0xFF00C896);
      case 'subscriptions':
        return const Color(0xFF7E57C2);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _colorForCategory();
    final icon = _iconForCategory();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.25)
              : chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: chipColor,
            ),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                color: isSelected
                    ? chipColor
                    : theme.colorScheme.onSurface.withOpacity(0.85),
                fontSize: compact ? 11 : 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of category chips for selection
class CategorySelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Education',
    'Groceries',
    'Rent',
    'Subscriptions',
    'Personal',
    'Gifts',
    'Pets',
    'Savings',
    'Investment',
  ];

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        return CategoryChip(
          category: cat,
          isSelected: selected == cat,
          onTap: () => onSelected(cat),
        );
      }).toList(),
    );
  }
}
