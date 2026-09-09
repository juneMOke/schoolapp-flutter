import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// La teinte d'un **poste de frais** dans la ventilation par poste.
///
/// La spec nomme **quatre familles** — Inscription, Scolarité, Fournitures,
/// Boutique — avec leurs teintes exactes (l'or de la spec, `--or-sahel`, est l'`orDoux` du socle : même valeur #D9A24E). Le contrat, lui, sert **vingt-trois
/// codes de frais**. Le rapprochement des deux est donc une décision, pas une
/// lecture, et elle est prise ici plutôt qu'éparpillée dans un widget.
///
/// ## Ce qui est sûr, et ce qui ne l'est pas
///
/// Les quatre teintes viennent de la spec. Le classement des codes dans ces
/// familles est **mon interprétation** : `TUITION` en Scolarité,
/// `REGISTRATION`/`ENROLLMENT`/`ADMISSION`/`APPLICATION` en Inscription,
/// `BOOKS`/`UNIFORM`/`SUPPLIES` en Fournitures.
///
/// ⚠️ **Un code non classé prend le gris neutre, jamais une teinte devinée.**
/// Dix-neuf des vingt-trois codes n'ont pas de famille écrite ; leur en
/// attribuer une par ressemblance de nom ferait porter à la couleur une
/// information que personne n'a validée — et la couleur ne porte jamais seule
/// une information de toute façon : le libellé du poste est écrit à côté.
///
/// La boutique n'apparaît pas ici en pratique — une vente comptant n'est
/// imputée sur aucune créance — mais sa teinte est déclarée pour que la famille
/// existe si le serveur en sert un jour une.
Color tillFeeCodeAccent(String code) =>
    _byFamily[code.trim().toUpperCase()] ?? AppColors.textSecondary;

const Map<String, Color> _byFamily = {
  // Scolarité
  'TUITION': AppColors.bleuArdoise,
  // Inscription
  'REGISTRATION': AppColors.vertSavane,
  'ENROLLMENT': AppColors.vertSavane,
  'ADMISSION': AppColors.vertSavane,
  'APPLICATION': AppColors.vertSavane,
  // Fournitures
  'BOOKS': AppColors.orDoux,
  'UNIFORM': AppColors.orDoux,
  'SUPPLIES': AppColors.orDoux,
  // Boutique
  'BOUTIQUE': AppColors.terreCuite,
};
