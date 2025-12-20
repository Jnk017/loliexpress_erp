import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Horizontal scrollable category filter for notifications
class CategoryFilterWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilterWidget({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.all_inbox;
      case 'Orders':
        return Icons.shopping_cart;
      case 'Inventory':
        return Icons.inventory_2;
      case 'Payments':
        return Icons.payment;
      case 'System':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    category,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) => onCategorySelected(category),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            ),
          );
        },
      ),
    );
  }
}
