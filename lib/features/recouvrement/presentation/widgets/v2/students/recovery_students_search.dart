import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La recherche de la liste (I10) : nom, matricule ou parent, rendue au
/// parent après une pause de frappe. Sans capitalisation : un matricule se
/// cherche tel quel.
class RecoveryStudentsSearch extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;

  const RecoveryStudentsSearch({
    super.key,
    required this.search,
    required this.onSearchChanged,
  });

  /// La pause de frappe avant de relire la liste.
  static const debounce = Duration(milliseconds: 300);

  @override
  State<RecoveryStudentsSearch> createState() => _RecoveryStudentsSearchState();
}

class _RecoveryStudentsSearchState extends State<RecoveryStudentsSearch> {
  late final _controller = TextEditingController(text: widget.search);
  Timer? _timer;

  @override
  void didUpdateWidget(RecoveryStudentsSearch old) {
    super.didUpdateWidget(old);
    // La recherche reprise de l'adresse ou effacée par la page : le champ
    // la suit, sauf pendant une frappe pas encore rendue.
    if (_timer == null && widget.search != _controller.text) {
      _controller.text = widget.search;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(RecoveryStudentsSearch.debounce, () {
      _timer = null;
      if (!mounted) return;
      widget.onSearchChanged(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloTextInput(
      controller: _controller,
      label: l10n.recoveryStudentsSearch,
      placeholder: l10n.recoveryStudentsSearch,
      hideLabel: true,
      capitalization: EteeloTextCapitalization.none,
      textInputAction: TextInputAction.search,
      prefix: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(
          Icons.search,
          size: AppSpacing.lg,
          color: AppColors.textMuted,
        ),
      ),
      onChanged: _onChanged,
      onSubmitted: (text) {
        _timer?.cancel();
        _timer = null;
        widget.onSearchChanged(text);
      },
    );
  }
}
