import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 16 : 28,
        horizontal: 12,
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(
                compact ? AppRadii.control : AppRadii.card,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            body,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[SizedBox(height: compact ? 10 : 16), action!],
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.textInputAction,
    this.requiredField = false,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool requiredField;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requiredField ? '$label *' : label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          textInputAction: textInputAction,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hint, errorText: errorText),
        ),
      ],
    );
  }
}

class CharacterHint extends StatelessWidget {
  const CharacterHint({super.key, required this.length, required this.label});

  final int length;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (length < 280) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
