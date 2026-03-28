import 'package:flutter/material.dart';

class NoteColorFilter extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const NoteColorFilter({
    Key? key,
    required this.selectedColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const colors = [
      ('all', Colors.grey, 'All'),
      ('yellow', Colors.yellow, 'Yellow'),
      ('blue', Colors.blue, 'Blue'),
      ('red', Colors.red, 'Red'),
      ('green', Colors.green, 'Green'),
      ('purple', Colors.purple, 'Purple'),
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colors.map((color) {
          final isSelected = selectedColor == color.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(color.$3),
              selected: isSelected,
              onSelected: (_) => onColorSelected(color.$1),
              backgroundColor: color.$2.withOpacity(0.3),
              selectedColor: color.$2,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
