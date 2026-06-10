import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// primary · secondary · ghost · danger
enum EteeloButtonVariant { primary, secondary, ghost, danger }

/// compact (sm) · regular (md)
enum EteeloButtonSize { compact, regular }

/// Bouton design-system Eteelo — 4 variantes sémantiques, 2 tailles.
/// Tokens : primary=terreCuite · secondary=outlined bleuArdoise 1.5px ·
/// ghost=texte bleuArdoise sans bordure · danger=error.
/// Focus ring via BoxShadow ; hover simulation via overlayColor.
class EteeloButton extends StatefulWidget {
  const EteeloButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.size = EteeloButtonSize.compact,
    this.fullWidth = true,
    this.tooltip,
  }) : _variant = EteeloButtonVariant.primary;

  const EteeloButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.size = EteeloButtonSize.compact,
    this.fullWidth = true,
    this.tooltip,
  }) : _variant = EteeloButtonVariant.secondary;

  const EteeloButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.size = EteeloButtonSize.compact,
    this.fullWidth = true,
    this.tooltip,
  }) : _variant = EteeloButtonVariant.ghost;

  const EteeloButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.size = EteeloButtonSize.compact,
    this.fullWidth = true,
    this.tooltip,
  }) : _variant = EteeloButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Libellé affiché à côté du spinner pendant le chargement (ex. « Connexion… »).
  /// Si `null`, seul le spinner est montré (comportement par défaut).
  final String? loadingLabel;
  final EteeloButtonSize size;
  final bool fullWidth;

  /// Obligatoire pour les boutons icône seule (accessibilité 4.1.2).
  final String? tooltip;
  final EteeloButtonVariant _variant;

  @override
  State<EteeloButton> createState() => _EteeloButtonState();
}

class _EteeloButtonState extends State<EteeloButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  // No-op pendant le chargement → conserve l'apparence "active".
  VoidCallback? get _effectiveOnPressed =>
      widget.isLoading ? () {} : widget.onPressed;

  bool get _isFilledVariant =>
      widget._variant == EteeloButtonVariant.primary ||
      widget._variant == EteeloButtonVariant.danger;

  BorderRadius get _focusBorderRadius => AppRadius.brPill;

  @override
  Widget build(BuildContext context) {
    final core = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      decoration: BoxDecoration(
        borderRadius: _focusBorderRadius,
        boxShadow: _isFocused
            ? const [
                BoxShadow(
                  color: AppColors.stateFocus,
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Semantics(
        button: true,
        label: widget.tooltip ?? widget.label,
        enabled: !widget.isLoading && widget.onPressed != null,
        child: _buildByVariant(),
      ),
    );
    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: core)
        : core;
  }

  Widget _buildByVariant() => switch (widget._variant) {
    EteeloButtonVariant.primary ||
    EteeloButtonVariant.danger => _buildElevatedButton(),
    EteeloButtonVariant.secondary => _buildOutlinedButton(),
    EteeloButtonVariant.ghost => _buildTextButton(),
  };

  Widget _buildElevatedButton() {
    final bg = widget._variant == EteeloButtonVariant.primary
        ? AppColors.terreCuite
        : AppColors.error;
    return _wrapWidth(
      ElevatedButton(
        focusNode: _focusNode,
        onPressed: _effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: AppColors.blancCasse,
          disabledBackgroundColor: AppColors.stateDisabled,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: _padding(),
          minimumSize: _minimumSize(),
          shape: _shape(),
          textStyle: _textStyle(),
        ).copyWith(overlayColor: _darkenOverlay()),
        child: _child(),
      ),
    );
  }

  Widget _buildOutlinedButton() => _wrapWidth(
    OutlinedButton(
      focusNode: _focusNode,
      onPressed: _effectiveOnPressed,
      style:
          OutlinedButton.styleFrom(
            foregroundColor: AppColors.bleuArdoise,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            padding: _padding(),
            minimumSize: _minimumSize(),
            shape: _shape(),
            textStyle: _textStyle(),
          ).copyWith(
            overlayColor: _tintOverlay(AppColors.bleuArdoise),
            side: WidgetStateProperty.resolveWith<BorderSide?>(
              (states) => states.contains(WidgetState.disabled)
                  ? const BorderSide(color: AppColors.stateDisabled)
                  : const BorderSide(color: AppColors.bleuArdoise, width: 1.5),
            ),
          ),
      child: _child(),
    ),
  );

  Widget _buildTextButton() => _wrapWidth(
    TextButton(
      focusNode: _focusNode,
      onPressed: _effectiveOnPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.bleuArdoise,
        disabledForegroundColor: AppColors.textMuted,
        padding: _padding(),
        minimumSize: _minimumSize(),
        shape: _shape(),
        textStyle: _textStyle(),
      ).copyWith(overlayColor: _tintOverlay(AppColors.bleuArdoise)),
      child: _child(),
    ),
  );

  Widget _child() {
    final iconSize = _iconSize();
    final spinnerSize = _iconSize();
    if (widget.isLoading) {
      final spinner = SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _isFilledVariant ? AppColors.blancCasse : AppColors.bleuArdoise,
          ),
        ),
      );
      if (widget.loadingLabel == null) return spinner;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.loadingLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: iconSize),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  // Hover/pressed sombre — primary, danger (fond foncé).
  WidgetStateProperty<Color?> _darkenOverlay() =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.black.withValues(alpha: 0.06);
        }
        return null;
      });

  // Hover/pressed teinte — secondary, ghost (fond clair).
  WidgetStateProperty<Color?> _tintOverlay(Color base) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return base.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return base.withValues(alpha: 0.06);
        }
        return null;
      });

  Widget _wrapWidth(Widget child) =>
      widget.size == EteeloButtonSize.regular && widget.fullWidth
      ? SizedBox(width: double.infinity, child: child)
      : child;

  EdgeInsets _padding() =>
      EdgeInsets.symmetric(horizontal: _horizontalPadding(), vertical: 0);

  double _horizontalPadding() {
    if (widget._variant == EteeloButtonVariant.ghost) {
      return 8;
    }
    return widget.size == EteeloButtonSize.regular ? 22 : 16;
  }

  double _iconSize() => widget.size == EteeloButtonSize.regular ? 18 : 16;

  Size _minimumSize() => widget.size == EteeloButtonSize.regular
      ? const Size(0, AppDimensions.minTouchTarget)
      : const Size(112, 40);

  OutlinedBorder _shape() => const StadiumBorder();

  TextStyle _textStyle() => AppTypography.labelLarge.copyWith(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.2,
  );
}
