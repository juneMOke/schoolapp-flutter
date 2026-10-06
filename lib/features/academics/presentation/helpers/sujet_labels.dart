import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_duree.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résumé d'un sujet : « 3 questions · 20 / 20 pts · 30 min ».
String sujetSummary(
  AppLocalizations l10n, {
  required int questionCount,
  required SujetBareme bareme,
  int? dureeMinutes,
}) => [
  l10n.sujetSummaryQuestions(questionCount),
  l10n.sujetPointsOf(
    formatPoints(bareme.total),
    formatPoints(bareme.maxPoints),
  ),
  if (dureeMinutes != null) formatDuree(l10n, dureeMinutes),
].join(' · ');

/// Message du barème (spec S4).
String baremeMessage(AppLocalizations l10n, SujetBareme bareme) =>
    switch (bareme.status) {
      BaremeStatus.empty => l10n.sujetBaremeEmpty,
      BaremeStatus.under => l10n.sujetBaremeUnder(formatPoints(bareme.gap)),
      BaremeStatus.complete => l10n.sujetBaremeComplete,
      BaremeStatus.over => l10n.sujetBaremeOver(formatPoints(bareme.gap)),
    };
