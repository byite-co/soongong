// AppTextField (S05): labelled single-line field in the prototype's style
// (surface fill · 1 px line · 12 px radius · blue focus · orange when the
// current error concerns this field).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.highlightError = false,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.suffixText,
    this.trailing,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final bool highlightError;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// [S07] Hard limit (the built-in counter is hidden; show your own).
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;

  /// [S07] Right-aligned widget on the label row (e.g. a "12/40" counter).
  final Widget? trailing;

  /// [S09] Multi-line input (문의 내용); null = unbounded.
  final int? maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppTypography.caption.copyWith(color: c.tx2))),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          autofocus: autofocus,
          enabled: enabled,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: !obscure,
          style: AppTypography.body.copyWith(color: c.tx),
          decoration: InputDecoration(
            counterText: '',
            suffixText: suffixText,
            suffixStyle: AppTypography.label.copyWith(color: c.tx3),
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: c.tx3),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s14,
              vertical: AppSpacing.s14,
            ),
            enabledBorder: border(highlightError ? c.acc : c.line),
            focusedBorder: border(highlightError ? c.acc : c.pri, 1.5),
            disabledBorder: border(c.line),
          ),
        ),
      ],
    );
  }
}
