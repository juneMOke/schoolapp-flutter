import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

/// Met le reçu provisoire en **lignes de caractères**.
///
/// C'est le point de jonction des deux sorties de RG-012-10, reformulé : « un
/// modèle, deux renderers ». Aucune abstraction ne joint un arbre de widgets PDF
/// à un flux d'octets ESC/POS — mais les deux savent poser des lignes de texte
/// en police fixe. Ce gabarit est donc le seul endroit où la mise en page est
/// décidée, et le seul niveau réellement testable du dépôt (aucun golden test
/// n'y existe, et le rendu PDF n'est pas montable en test de widget).
///
/// Le critère d'acceptation de l'ADR — « ticket ESC/POS **et** PDF depuis le
/// même gabarit, comparaison du contenu textuel » — se vérifie exactement ici.
abstract final class TicketTextLayout {
  /// Largeur d'un ticket 80 mm en police A (12×24) sur une imprimante
  /// thermique standard. 58 mm donnerait 32, la police B 64.
  static const int defaultColumns = 48;

  /// Rend le ticket. [columns] est le nombre de caractères par ligne.
  static List<String> render(
    TicketReceiptModel model, {
    int columns = defaultColumns,
  }) {
    final width = columns < 24 ? 24 : columns;
    final lines = <String>[];

    // ── Z1 — l'établissement, en-tête complet : nom, adresse, localité, email,
    // téléphone. Le logo, lui, n'est PAS ici : c'est une bande posée par chaque
    // renderer en amont de ces lignes. Une image ne passe pas par le pivot
    // `List<String>`, et c'est ce pivot qui rend vérifiable le critère
    // d'acceptation de l'ADR — même contenu textuel entre les deux sorties. Le
    // précédent est celui de `cutNotice` : ce qui appartient au SUPPORT est posé
    // par le renderer, jamais par le gabarit.
    //
    // Aucune garde à écrire sur les lignes optionnelles : `_centered('')` rend
    // une liste VIDE, donc un champ absent ne laisse pas même une ligne
    // d'espaces. Une école mal renseignée sort un en-tête plus COURT, jamais un
    // en-tête troué — et sur une pièce, une ligne blanche se lirait comme une
    // mention effacée.
    lines.addAll(_centered(model.schoolName.toUpperCase(), width));
    lines.addAll(_centered(model.schoolAddress ?? '', width));
    lines.addAll(_centered(model.schoolLocality ?? '', width));
    lines.addAll(_centered(model.schoolEmail ?? '', width));
    lines.addAll(_centered(model.schoolPhone ?? '', width));
    lines.add(_rule(width));

    // Nature de la pièce, sous l'en-tête : quelqu'un qui trie une liasse de fin
    // de journée doit pouvoir l'identifier sans lire le corps.
    //
    // ⚠️ « Ticket de perception », jamais « note de perception » : ce dernier
    // nom désigne déjà une pièce ANNUELLE SCELLÉE au niveau élève
    // (`EditiqueDocumentType.notePerception`). Deux papiers homonymes au guichet
    // se paieraient au premier rapprochement, et c'est le nom vers lequel on
    // glisse naturellement en voulant faire « plus officiel ».
    lines.addAll(_centered(model.labels.documentTitle.toUpperCase(), width));

    // Le filet reste, lui : sans lui le titre coulerait directement dans le nom
    // de l'élève, et la coupure entre « ce qu'est ce document » et « de qui il
    // parle » disparaîtrait. Il ne se récupère pas avec le bandeau.
    lines.add(_rule(width));

    // ── Z2 — l'élève.
    lines.addAll(_wrapped(model.studentFullName.toUpperCase(), width));
    _addOptional(
      lines,
      model.labels.matriculationLabel,
      model.matriculationNumber,
      width,
    );
    _addOptional(
      lines,
      model.labels.classroomLabel,
      model.classroomName,
      width,
    );
    lines.add(_rule(width));

    // ── Z3 — la traçabilité. Sur une pièce non scellée, l'imputabilité humaine
    // remplace l'imputabilité cryptographique : le caissier est obligatoire dès
    // qu'il est connu (RG-012-11).
    // La mention « provisoire » s'accole au LIBELLÉ, pas à la fin de la ligne :
    // elle qualifie ainsi le numéro — l'argent est reçu, et le ticket
    // l'affirme — et elle se replie proprement quand la référence retombe sur
    // l'UUID du paiement, là où une parenthèse de fin de ligne se coupait en
    // deux.
    final referenceLabel = model.isProvisional
        ? '${model.labels.referenceLabel} ${model.labels.provisionalMention}'
        : model.labels.referenceLabel;
    lines.addAll(_wrapped('$referenceLabel ${model.reference}', width));
    // La date prend enfin un libellé — elle occupait jusqu'ici le créneau de
    // gauche sans être nommée. L'heure reste calée à DROITE sur la même ligne :
    // « Date : » + `JJ/MM/AAAA` fait 16 caractères, l'heure 5, il reste 27
    // colonnes de battement à 48 et 11 à 32. Aucune ligne de papier ajoutée.
    _addPair(
      lines,
      '${model.labels.dateLabel} ${_formatDate(model.paidAt)}',
      _formatTime(model.paidAt),
      width,
    );
    _addOptional(
      lines,
      model.labels.cashierLabel,
      model.cashierFullName,
      width,
    );
    lines.add(_rule(width));

    // ── Le payeur, quand il y en a un.
    //
    // **Le bloc ENTIER disparaît sinon** — ni cadre vide, ni tiret. Sur une
    // pièce, une mention laissée vide se lit comme une mention EFFACÉE et invite
    // à chercher ce qu'on aurait retiré ; mieux vaut n'avoir rien à lire que
    // quelque chose à interpréter.
    //
    // Un téléphone SEUL garde le bloc : il a été tapé, donc il désigne
    // quelqu'un. Même règle que le ticket de vente boutique, et il le faut —
    // deux pièces du même acte qui divergent se paient au rapprochement de
    // caisse.
    if (model.hasPayer) {
      final payerName = model.payerFullName?.trim() ?? '';
      if (payerName.isNotEmpty) {
        lines.addAll(
          _wrapped(
            '${model.labels.payerLabel} ${payerName.toUpperCase()}',
            width,
          ),
        );
      }
      _addOptional(
        lines,
        model.labels.phoneLabel,
        model.payerPhoneNumber,
        width,
      );
      lines.add(_rule(width));
    }

    // ── Z5 — l'argent. Montant reçu et répartition sont des FAITS : ils
    // s'impriment sans réserve (RG-012-13 — la répartition est une saisie, pas
    // un calcul). Seul le solde est incertain, et lui seul porte la mention.
    // Une ligne PAR DEVISE : un versement peut solder une créance en dollars et
    // une en francs. Les additionner imprimerait, sur la pièce que le payeur
    // emporte, un chiffre qui n'est l'argent de personne.
    _addMoneyBag(
      lines,
      model.labels.amountReceivedLabel,
      model.amountReceived,
      width,
    );

    // Le taux, sous le montant reçu, et **seulement** quand les deux unités
    // divergent. C'est le chiffre que le parent conteste au guichet : le laisser
    // déduire par division lui ferait lire un taux dérivé de l'arrondi. Un
    // « 1,00 » sur un règlement ordinaire, à l'inverse, ferait chercher ce qui a
    // été converti — d'où le filtre sur l'identité.
    for (final tender in model.tenders) {
      if (tender.isIdentity) continue;
      _addPair(
        lines,
        model.labels.rateLabel,
        _formatRate(tender, width),
        width,
      );
    }

    // Part du montant reçu qu'aucune créance n'absorbe. Elle EXISTE : un
    // versement peut dépasser le dû (`isOptimisticallyOverpaid`), le paiement
    // est alors accepté et le ticket reste valide.
    //
    // Elle s'imprime comme une ligne de répartition, et pas à part, pour une
    // raison de lecture : la ventilation somme alors exactement au montant
    // reçu. Sans elle, un parent qui additionne trouve un écart que rien
    // n'explique — le pire des trois cas, puisque le silence se lit comme une
    // erreur de caisse. Ce qu'elle ne fait PAS, c'est arbitrer le trop-perçu :
    // l'imputation définitive appartient au reçu scellé.
    // ⚠️ Uniquement quand une ventilation est IMPRIMÉE : c'est un écart visible
    // qu'on ferme, pas une comptabilité qu'on tient. Sans bloc « Répartition »,
    // le lecteur n'a aucune soustraction à faire, et une ligne d'avance seule
    // ne ferait que dupliquer le montant reçu deux lignes plus haut.
    if (model.allocations.isNotEmpty) {
      lines.add('');
      lines.add(TicketCharset.printable(model.labels.allocationsLabel));
      // Un filet sous le titre : sans lui, la première ligne de répartition se
      // lit comme un prolongement du mot « Répartition » plutôt que comme la
      // première d'une liste.
      lines.add(_rule(width));
      for (final allocation in model.allocations) {
        _addPair(
          lines,
          '  ${allocation.label}',
          formatAmount(allocation.amountInCents, allocation.currency),
          width,
        );
        // Ce que ce poste vaut dans la monnaie posée sur le comptoir. Sur une
        // ligne à part, jamais dans une troisième colonne : le gabarit fait 48
        // caractères en 80 mm et **32 en 58 mm**, où « libellé + montant » prend
        // déjà toute la largeur.
        final derived = model.derivedAmountOf(allocation);
        if (derived == null) continue;
        _addPair(
          lines,
          '    ${model.labels.derivedAmountPrefix}',
          formatAmount(derived.amountInCents, derived.currency),
          width,
        );
      }
      // Un écart NÉGATIF (ventilation supérieure au reçu) est une saisie
      // incohérente, pas une avance : `advance` l'écarte devise par devise, et
      // on ne l'habille pas d'un libellé qui la ferait passer pour normale.
      for (final advance in model.advance.entries) {
        if (advance.amountInCents <= 0) continue;
        _addPair(
          lines,
          '  ${model.labels.advanceLabel}',
          formatAmount(advance.amountInCents, advance.currency),
          width,
        );
      }
    }

    final balance = model.remainingBalance;
    if (balance != null && balance.isNotEmpty) {
      // Le solde est bâti comme la répartition — titre, détail, filet, total :
      // deux blocs de même nature doivent se lire de la même façon.
      //
      // Le qualificatif de temps est passé DANS le titre. Il se lit ainsi
      // AVANT les chiffres au lieu de les suivre, et la réserve qui traînait
      // sous le total a disparu avec lui — la garder en plus l'aurait dit deux
      // fois.
      //
      // ⚠️ Pas de ligne blanche au-dessus du filet. Elle ouvrait ce bloc du
      // temps où RIEN ne l'en séparait ; depuis qu'un filet le fait, les deux
      // séparent la même chose, et la blanche ne fait plus que coûter du
      // papier.

      // Titre REPLIÉ, pas posé brut. « Solde restant au moment de
      // l'impression » fait 39 caractères : il tient à 48, et se replie
      // proprement sur deux lignes à 32. Posé brut, il aurait débordé la
      // largeur du papier — c'est le défaut que « Répartition », court, masque
      // encore.
      final title = _wrapped(model.labels.balanceLabel, width);

      // Le filet qui SÉPARE de la répartition, avant le titre.
      //
      // ⚠️ Conditionné au titre, et pas seulement pour la forme : `_wrapped('')`
      // rend une liste VIDE. Un libellé vide — ce qu'une traduction incomplète
      // produit sans bruit — laisserait ce filet et celui du total se toucher,
      // en un « ---- / ---- » que rien d'autre ne rattraperait. Poser les deux
      // ensemble ou aucun ferme le cas à la source plutôt qu'en aval.
      if (title.isNotEmpty) {
        lines.add(_rule(width));
        lines.addAll(title);
      }

      // Le reste PAR NATURE avant le total. « Il vous reste 10 000 FC et
      // 314 $ » juxtapose deux devises sans les expliquer ; le détail dit d'où
      // elles viennent. C'est la règle que le montant reçu applique déjà — ne
      // jamais additionner deux unités — étendue au solde, qui y avait échappé.
      //
      // Les lignes sont indentées comme celles de la ventilation : elles se
      // lisent de la même façon, et le total les coiffe.
      for (final line in model.remainingByCharge) {
        _addPair(
          lines,
          '  ${line.label}',
          formatAmount(line.amountInCents, line.currency),
          width,
        );
      }

      // ⚠️ Filet et total **seulement quand le total ADDITIONNE quelque
      // chose.** Le solde ne porte plus que les frais réglés par ce versement :
      // le cas courant est UNE ligne, et « Frais divers 500 FC / ---- /
      // Total 500 FC » dirait deux fois le même chiffre sur un papier qui se
      // recompte. Le filet qui ferme la zone suit alors directement le détail.
      if (!_totalRepeatsDetail(balance, model.remainingByCharge)) {
        // Un filet SOUS le détail : le trait d'une addition posée. Il sépare
        // des lignes de nature différente — des créances au-dessus, ce
        // qu'elles font ensemble en dessous — là où le filet de la
        // répartition, lui, ouvre une liste sous son titre.
        lines.add(_rule(width));

        // Le total en DERNIÈRE ligne du bloc : le détail sans total obligerait
        // le parent à additionner, le total sans détail est ce qu'on lui
        // reproche.
        _addTotal(lines, model.labels.balanceTotalLabel, balance, width);
      }
    }

    lines.add(_rule(width));

    // Phrase de conservation (RG-012-12) : sans elle, l'établissement n'a aucun
    // levier pour rappeler un parent dont le versement poserait problème.
    //
    // ⚠️ **Seulement sur une pièce NON scellée**, et lue sur le même signal
    // affirmatif que la mention de référence — `isProvisional`, dérivé de
    // l'absence de `receipt_id`. Sur un ticket qui porte déjà son numéro
    // définitif, elle est factuellement FAUSSE : il n'y a pas de reçu à venir,
    // celui-là l'est. Sa raison d'être ne vaut que hors ligne.
    if (model.isProvisional) {
      lines.addAll(_centeredWrapped(model.labels.keepTicketNotice, width));
    }

    // Le pied, sur les deux sorties et dans tous les cas.
    //
    // L'adresse est sur sa PROPRE ligne, et sans schéma : deux lignes courtes
    // valent mieux qu'une longue qui se replierait au hasard, l'adresse isolée
    // se recopie, et un `http://` imprimé sur un papier que des familles gardent
    // annoncerait un transport non chiffré.
    lines.addAll(_centeredWrapped(model.labels.thanksNotice, width));
    lines.addAll(_centered(model.labels.editorNotice, width));
    lines.addAll(_centered(model.labels.editorSite, width));

    return lines;
  }

  /// Un libellé, puis **une ligne par devise**.
  ///
  /// Le libellé ne se répète pas : il coiffe la première ligne, les suivantes
  /// s'alignent sous elle. Sur 32 colonnes, le répéter mangerait la largeur du
  /// montant — et un ticket se recompte, il ne se déchiffre pas.
  static void _addMoneyBag(
    List<String> lines,
    String label,
    MoneyBag bag,
    int width,
  ) {
    if (bag.isEmpty) return;
    var first = true;
    for (final amount in bag.entries) {
      _addPair(
        lines,
        first ? label : '',
        formatAmount(amount.amountInCents, amount.currency),
        width,
      );
      first = false;
    }
  }

  /// Le total du solde : **une seule ligne**, les devises reliées par un `+`.
  ///
  /// Le `+` ne gagne pas que de la place. Deux montants séparés d'un simple
  /// espace se lisent comme un seul nombre bizarrement mis en forme ; le signe
  /// dit qu'ils sont DEUX, et qu'on ne les a précisément pas additionnés — ce
  /// qu'on ne saurait faire sans inventer un taux. C'est aussi ce qui justifie
  /// que cette ligne ait une forme que `Montant reçu` n'a pas : elle totalise,
  /// lui énumère.
  ///
  /// Les montants sortent de [formatAmount], le **même** formateur que les
  /// lignes au-dessus. Un total écrit autrement que les chiffres qu'il totalise
  /// se lit comme une autre nature de nombre, et un parent qui recompte
  /// s'arrête dessus.
  ///
  /// ## Le repli
  ///
  /// La ligne unique tient à 48 colonnes, et à 32 jusqu'à
  /// « 9 999 999 FC + 99 999,00 $ » — 26 caractères, la mesure exacte. Au-delà,
  /// le bloc revient à **une ligne par devise**, la seconde forme que le
  /// porteur accepte.
  ///
  /// Ce repli-là est explicite parce que celui d'[_addPair] serait mauvais
  /// ici : il renverrait les deux montants **collés sur une ligne à eux**, ce
  /// qui garde le défaut qu'on voulait éviter, et déborderait franchement la
  /// largeur du papier si la valeur seule atteignait la largeur.
  static void _addTotal(
    List<String> lines,
    String label,
    MoneyBag bag,
    int width,
  ) {
    if (bag.isEmpty) return;
    final joined = TicketCharset.printable(
      bag.entries
          .map((amount) => formatAmount(amount.amountInCents, amount.currency))
          .join(' + '),
    );
    // Mesure sur la forme TRANSLITTÉRÉE, des deux côtés : c'est elle qui
    // s'imprime, et `œ` → `oe` change une longueur.
    final printableLabel = TicketCharset.printable(label);
    if (printableLabel.length + 1 + joined.length <= width) {
      _addPair(lines, label, joined, width);
      return;
    }
    _addMoneyBag(lines, label, bag, width);
  }

  /// Le total ne ferait-il que **redire** l'unique ligne de détail ?
  ///
  /// La question porte sur la répétition, pas sur le nombre de lignes : une
  /// ligne unique sous un total qui ne lui est pas égal — une seconde devise
  /// sans détail — garde son total, qui dit alors quelque chose de plus.
  /// Comparés en sacs, donc devises normalisées des deux côtés.
  static bool _totalRepeatsDetail(
    MoneyBag balance,
    List<TicketAllocationLine> detail,
  ) =>
      detail.length == 1 &&
      balance ==
          MoneyBag.from(
            Money.parse(detail.single.amountInCents, detail.single.currency),
          );

  /// Le taux, tel qu'il s'imprime : « 1 666,67 FC / $ ».
  ///
  /// Deux décimales, celles-là mêmes qui sont stockées — la saisie est
  /// contrainte au centième pour que l'imprimé et le stocké soient le MÊME
  /// nombre. Un taux arrondi à l'affichage ne ferait pas retomber le parent sur
  /// son total.
  ///
  /// Sur un ticket étroit, la forme « FC / \$ » cède à la seule devise reçue : la
  /// paire tient rarement à droite de « Taux » en 32 colonnes, et c'est le
  /// nombre qui compte.
  static String _formatRate(TicketTenderLine tender, int width) {
    final value = tender.rate.formatted(space: MoneyFormat.thermalSpace);
    final quote = MoneyFormat.symbolOf(tender.currency);
    if (width < 40) return '$value $quote';
    final base = MoneyFormat.symbolOf(tender.pivotCurrency);
    return '$value $quote / $base';
  }

  /// Montant en centimes → « 1 234 FC », « 425,00 $ ».
  ///
  /// Façade sur [MoneyFormat], qui porte désormais la règle : les décimales se
  /// décident sur la **devise**, et `CDF` s'écrit « FC ». Le ticket écrivait
  /// jusqu'ici « 1 234,00 CDF » — deux décimales sur une devise qui n'en a pas,
  /// et le code ISO à la place de l'abréviation d'usage.
  ///
  /// Formateur **pur**, sans données de locale à initialiser : le ticket doit
  /// pouvoir être rendu dans un test unitaire comme dans un isolat d'impression.
  /// L'espace de groupement est l'**ordinaire** — une imprimante thermique ne
  /// rend pas l'insécable.
  static String formatAmount(int cents, String currency) => MoneyFormat.format(
    Money.parse(cents, currency),
    space: MoneyFormat.thermalSpace,
  );

  // ── Primitives de mise en page ──────────────────────────────────────────────
  //
  // Déléguées à `TicketTextPrimitives`, partagé avec le ticket de vente
  // boutique : deux copies divergeraient au premier ajustement de largeur.

  static void _addOptional(
    List<String> lines,
    String label,
    String? value,
    int width,
  ) => TicketTextPrimitives.addOptional(lines, label, value, width);

  static String _rule(int width) => TicketTextPrimitives.rule(width);

  static List<String> _centered(String text, int width) =>
      TicketTextPrimitives.centered(text, width);

  static List<String> _centeredWrapped(String text, int width) =>
      TicketTextPrimitives.centeredWrapped(text, width);

  static void _addPair(
    List<String> lines,
    String rawLabel,
    String rawValue,
    int width,
  ) => TicketTextPrimitives.addPair(lines, rawLabel, rawValue, width);

  static String _formatDate(DateTime at) => TicketTextPrimitives.formatDate(at);

  static String _formatTime(DateTime at) => TicketTextPrimitives.formatTime(at);

  static List<String> _wrapped(String text, int width) =>
      TicketTextPrimitives.wrapped(text, width);
}
