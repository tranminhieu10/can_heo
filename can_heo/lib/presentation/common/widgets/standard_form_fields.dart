import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget TextField chuẩn cho form nhập liệu trong các màn hình phiếu
/// Có icon, label, và style đồng bộ
class StandardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final double fontSize;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? hintText;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;

  const StandardTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.fontSize = 13,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.hintText,
    this.enabled = true,
    this.inputFormatters,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(fontSize: fontSize - 1),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// Widget Dropdown chuẩn cho form nhập liệu
class StandardDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final double fontSize;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? hintText;
  final bool enabled;

  const StandardDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.fontSize = 13,
    this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      style: TextStyle(fontSize: fontSize, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(fontSize: fontSize - 1),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
      ),
    );
  }
}

/// Widget hiển thị giá trị readonly với icon
class StandardReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isBold;

  const StandardReadonlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.fontSize = 13,
    this.backgroundColor,
    this.textColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize - 1),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: backgroundColor ?? Colors.grey[100],
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? Colors.black87,
        ),
      ),
    );
  }
}

/// Header section chuẩn cho các form phiếu
class StandardFormHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double fontSize;
  final Widget? trailing;

  const StandardFormHeader({
    super.key,
    required this.title,
    this.icon = Icons.receipt_long,
    this.color = Colors.teal,
    this.fontSize = 13,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
