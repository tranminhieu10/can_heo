import 'package:flutter/material.dart';

/// Common text field for grid layout
class GridTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final bool enabled;
  final void Function(String)? onChanged;

  const GridTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        border: const OutlineInputBorder(),
        isDense: true,
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}

/// Locked field for readonly display
class GridLockedField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const GridLockedField({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(
          color: highlight ? Colors.blue : Colors.grey[400]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.blue[700] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: highlight ? Colors.blue[800] : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Inventory display container
class InventoryContainer extends StatelessWidget {
  final int quantity;
  final bool isValid;

  const InventoryContainer({
    super.key,
    required this.quantity,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tồn kho',
            style: TextStyle(
              fontSize: 10,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            '$quantity con',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// Field with increment/decrement buttons
class FieldWithButtons extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(String)? onChanged;

  const FieldWithButtons({
    super.key,
    required this.controller,
    required this.label,
    required this.onIncrement,
    required this.onDecrement,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 10),
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onIncrement,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_up, size: 12),
                  ),
                ),
              ),
              InkWell(
                onTap: onDecrement,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_down, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
