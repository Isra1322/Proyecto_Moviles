import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final all = [null, ...categories.map((c) => c.id)];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final id = all[index];
          final label = id == null
              ? 'Todos'
              : categories.firstWhere((c) => c.id == id).name;
          final isSelected = selectedCategoryId == id;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(id),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

