import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final Widget child;

  const ProfileCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ProfileStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const ProfileStatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileContactLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const ProfileContactLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class ProfileShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ProfileShortcutCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF003580), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileFormLabel extends StatelessWidget {
  final String label;
  final bool isEditable;

  const ProfileFormLabel({
    super.key,
    required this.label,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isEditable)
          const Text(
            'Có thể chỉnh sửa',
            style: TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class ProfileReadOnlyValue extends StatelessWidget {
  final String value;
  final IconData? leading;
  final String? trailing;
  final bool verified;

  const ProfileReadOnlyValue({
    super.key,
    required this.value,
    this.leading,
    this.trailing,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 15, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Icon(
              verified ? Icons.check_circle_outline : Icons.info_outline,
              size: 14,
              color: verified
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              trailing!,
              style: TextStyle(
                color: verified
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfilePasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const ProfilePasswordField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFormLabel(label: label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: false,
          decoration: profileInputDecoration(hint).copyWith(
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileInlineMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const ProfileInlineMessage({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    final background = isError
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 12, height: 1.4),
      ),
    );
  }
}

InputDecoration profileInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
  ),
);
