import 'package:flutter/material.dart';

class DropdownSection extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String?> onChanged;

  const DropdownSection({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedType,
      onChanged: onChanged,
      items: ['Mammal', 'Plant'].map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
    );
  }
}
