import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau d'en-tête de la page Facturation.
///
/// Remplace le breadcrumb générique en apportant contexte, icône et
/// indicateurs visuels des trois actions possibles sur la page.
/// Aucune logique BLoC — widget purement présentatif.
class FacturationPageHeader extends StatelessWidget {
  const FacturationPageHeader({super.key});

  // ─── Palette interne ────────────────────────────────────────────────────────
  // Fond : bleu très clair → indigo très clair (cohérent avec le gradient page)
  static const _bgStart = Color(0xFFEFF6FF);
  static const _bgEnd = Color(0xFFEEF2FF);
  static const _border = Color(0xFFBFD7F7);

  // Badge icône : cercle bleu primaire avec fond clair
  static const _iconBadgeBg = Color(0xFFDCEAFE);

  // Chips feature : fond très léger teinté selon la nature
  static const _chipNameBg = Color(0xFFE0F2FE);    // bleu ciel clair
  static const _chipNameFg = Color(0xFF0369A1);    // bleu ciel foncé
  static const _chipLevelBg = Color(0xFFEDE9FE);   // violet clair
  static const _chipLevelFg = Color(0xFF6D28D9);   // violet foncé
  static const _chipChargesBg = Color(0xFFD1FAE5); // vert menthe clair
  static const _chipChargesFg = Color(0xFF065F46); // vert foncé

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_bgStart, _bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          return isWide
              ? _WideLayout(l10n: l10n)
              : _CompactLayout(l10n: l10n);
        },
      ),
    );
  }
}

// ─── Layout large (≥ 640 px) ─────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final AppLocalizations l10n;
  const _WideLayout({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _TextContent(l10n: l10n)),
        const SizedBox(width: 24),
        const _IconBadge(),
      ],
    );
  }
}

// ─── Layout compact (< 640 px) ───────────────────────────────────────────────

class _CompactLayout extends StatelessWidget {
  final AppLocalizations l10n;
  const _CompactLayout({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IconBadge(),
        const SizedBox(height: 14),
        _TextContent(l10n: l10n),
      ],
    );
  }
}

// ─── Bloc texte (titre + sous-titre + chips) ──────────────────────────────────

class _TextContent extends StatelessWidget {
  final AppLocalizations l10n;
  const _TextContent({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.facturationPageHeaderTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.facturationPageHeaderSubtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _FeatureChip(
              icon: Icons.person_search_outlined,
              label: l10n.facturationPageHeaderChipByName,
              bg: FacturationPageHeader._chipNameBg,
              fg: FacturationPageHeader._chipNameFg,
            ),
            _FeatureChip(
              icon: Icons.school_outlined,
              label: l10n.facturationPageHeaderChipByLevel,
              bg: FacturationPageHeader._chipLevelBg,
              fg: FacturationPageHeader._chipLevelFg,
            ),
            _FeatureChip(
              icon: Icons.receipt_long_outlined,
              label: l10n.facturationPageHeaderChipViewCharges,
              bg: FacturationPageHeader._chipChargesBg,
              fg: FacturationPageHeader._chipChargesFg,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Badge icône ──────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: FacturationPageHeader._iconBadgeBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        size: 30,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

// ─── Chip feature ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
