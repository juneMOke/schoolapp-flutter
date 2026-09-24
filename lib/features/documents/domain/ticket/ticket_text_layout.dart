import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
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

  /// Rend le ticket **en texte nu**. [columns] est le nombre de caractères par
  /// ligne.
  ///
  /// Façade sur [renderRich], et elle reste la forme de référence : c'est sur
  /// elle que se vérifie le critère d'acceptation de l'ADR-012 — « même contenu
  /// textuel entre les deux sorties ». Le gras n'est pas du contenu, il ne s'y
  /// invite donc pas.
  static List<String> render(
    TicketReceiptModel model, {
    int columns = defaultColumns,
  }) => [for (final line in renderRich(model, columns: columns)) line.text];

  /// Rend le ticket **avec ses attributs de composition**.
  ///
  /// C'est ce que consomment les deux renderers. Le gras est posé par
  /// `emphasised`, qui marque tout ce que le bloc qu'il enveloppe a ajouté :
  /// aucun calcul d'indice au point d'appel, et les cas multi-lignes — un titre
  /// replié, un montant en deux devises — sont couverts sans y penser.
  static List<TicketLine> renderRich(
    TicketReceiptModel model, {
    int columns = defaultColumns,
  }) {
    final width = columns < 24 ? 24 : columns;
    final lines = <String>[];

    // Les indices des lignes grasses. Un ensemble plutôt qu'une liste
    // parallèle : la seconde devrait rester alignée sur la première à chaque
    // `addAll`, ce qui est exactement le genre d'invariant qui se casse en
    // silence.
    final bold = <int>{};

    /// Une ligne d'en-tête NOMMÉE, centrée, et **escamotée quand elle est
    /// vide** — la règle de tout l'en-tête, étendue aux lignes à libellé.
    ///
    /// `_addOptional` ferait le même escamotage mais aligne à gauche ; ici les
    /// lignes d'école sont centrées, et une seule d'entre elles cadrée à gauche
    /// se lirait comme un défaut de composition.
    ///
    /// ## Le repli : le libellé au-dessus, jamais le numéro coupé
    ///
    /// « Tél. Promoteur : +243 000 000 000 » fait 33 caractères. Il tient à 48
    /// et **déborde à 32** — le papier 58 mm —, où `_centered` le replierait sur
    /// les espaces et rendrait `+243 000 000` puis `000` : un numéro coupé en
    /// deux, que personne ne peut composer.
    ///
    /// Quand les deux ne tiennent pas ensemble, le libellé prend donc sa propre
    /// ligne et la valeur la suivante, entière. C'est la règle que le gabarit
    /// applique déjà partout où une valeur ne rentre pas — `_addPair` reporte le
    /// montant, `_addTotal` revient à une ligne par devise : **on ne tronque
    /// jamais une valeur, on la reporte.**
    void centeredOptional(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      // Mesure sur la forme TRANSLITTÉRÉE, des deux côtés : c'est elle qui
      // s'imprime, et « é » → « e » ne change pas la longueur mais « œ » si.
      final oneLine = TicketCharset.printable('$label $trimmed');
      if (oneLine.length <= width) {
        lines.addAll(_centered(oneLine, width));
        return;
      }
      lines.addAll(_centered(label, width));
      lines.addAll(_centered(trimmed, width));
    }

    /// Marque en gras TOUT ce que [build] ajoute — une ligne ou dix.
    void emphasised(void Function() build) {
      final from = lines.length;
      build();
      for (var i = from; i < lines.length; i++) {
        bold.add(i);
      }
    }

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
    emphasised(
      () => lines.addAll(_centered(model.schoolName.toUpperCase(), width)),
    );
    lines.addAll(_centered(model.schoolAddress ?? '', width));
    lines.addAll(_centered(model.schoolLocality ?? '', width));
    lines.addAll(_centered(model.schoolEmail ?? '', width));

    // Les DEUX téléphones, chacun sur sa ligne et chacun NOMMÉ.
    //
    // L'en-tête n'en portait qu'un, nu comme les autres lignes d'école. Le
    // second ne pouvait pas y entrer ainsi : deux numéros sans libellé laissent
    // le parent deviner lequel appeler pour une question de paiement, ce qui
    // est précisément la question que le numéro de caisse existe pour clore.
    // Nommer le second oblige donc à nommer le premier — c'est le prix de
    // l'ajout, et il se paie en libellés, pas en lignes.
    //
    // ⚠️ Nommés, mais toujours ESCAMOTABLES : un libellé sans numéro se lirait
    // comme un numéro effacé. `centeredOptional` garde donc la règle de tout
    // l'en-tête — un champ absent ne laisse pas même une ligne d'espaces —, là
    // où `_centered('$label ')` aurait imprimé le libellé seul.
    centeredOptional(model.labels.schoolPhoneLabel, model.schoolPhone);
    centeredOptional(model.labels.tillPhoneLabel, model.schoolTillPhone);
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
    // Sous le matricule classique, qui reste — c'est ainsi que le serveur les
    // pose sur le reçu scellé, et les deux papiers finissent dans les mains du
    // même parent.
    _addOptional(
      lines,
      model.labels.annualMatriculationLabel,
      model.annualMatriculationNumber,
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
    emphasised(
      () => _addMoneyBag(
        lines,
        model.labels.amountReceivedLabel,
        model.amountReceived,
        width,
      ),
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
      emphasised(
        () => lines.add(TicketCharset.printable(model.labels.allocationsLabel)),
      );
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
        emphasised(() => lines.addAll(title));
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
        emphasised(
          () =>
              _addTotal(lines, model.labels.balanceTotalLabel, balance, width),
        );
      }
    }

    // ── Z6 — les versements de l'année, CE TICKET COMPRIS.
    //
    // Le versement courant y figure, et ce n'est pas une redite du « Montant
    // reçu » : ce qui se lit ici, c'est le CUMUL de l'année, que le total du
    // bloc porte en dernière ligne. Sans lui le cumul s'arrêterait la veille, et
    // le parent devrait ajouter de tête le chiffre imprimé cinq lignes plus
    // haut. C'est `printedPayments` qui l'insère — à sa date, jamais épinglé en
    // tête, parce que la date d'encaissement est saisissable au guichet.
    //
    // Le bloc ne disparaît donc qu'aux deux cas où il n'y a **rien** à lister :
    // année inconnue, ou versement sans ligne de tiroir. Au tout premier
    // versement de l'année il sort avec sa ligne unique et sans total — un total
    // qui ne coifferait qu'une ligne la redirait, règle déjà appliquée au solde.
    //
    // ⚠️ Il vient APRÈS le solde, et l'ordre n'est pas indifférent : le parent
    // lit ce qu'il vient de payer, ce qu'il lui reste, puis tout ce qu'il a
    // versé. Remonter le bloc au-dessus du solde ferait finir la pièce sur une
    // dette.
    final printedPayments = model.printedPayments;
    if (printedPayments.isNotEmpty) {
      // Le filet qui SÉPARE du bloc précédent — répartition, solde, ou le
      // montant reçu seul. Posé sans condition : il ferme ce qui précède, pas
      // ce qui suit.
      lines.add(_rule(width));

      // Titre REPLIÉ, comme celui du solde : « Historique des paiements » fait
      // 24 caractères, il tient à 48 et à 32 — mais un libellé traduit plus long
      // déborderait, et le repli coûte moins qu'une ligne coupée au papier.
      //
      // ⚠️ Filet du dessous conditionné au titre, pour la raison déjà payée par
      // le bloc de solde : `_wrapped('')` rend une liste VIDE, et un libellé
      // vide — ce qu'une traduction incomplète produit sans bruit — collerait
      // deux filets l'un sur l'autre.
      final title = _wrapped(model.labels.historyLabel, width);
      if (title.isNotEmpty) {
        emphasised(() => lines.addAll(title));
        // Le filet qui OUVRE la liste sous son titre, comme celui de la
        // répartition : sans lui, la première date se lit comme un prolongement
        // du mot « Historique ».
        lines.add(_rule(width));
      }

      // Une ligne par versement : la date à gauche, le perçu à droite. Celui
      // du jour ne porte AUCUNE marque — sa date est déjà celle imprimée en
      // tête du ticket, il se reconnaît donc seul, et une mention lui coûterait
      // onze colonnes que les 32 d'un papier 58 mm n'ont pas.
      //
      // Un versement qui a mêlé deux devises prend deux lignes, la date sur la
      // première seulement — `_addMoneyBag` ne répète jamais son libellé, et
      // une date répétée se lirait comme deux versements du même jour.
      for (final entry in printedPayments) {
        _addMoneyBag(
          lines,
          '  ${_formatDate(entry.paidAt)}',
          entry.received,
          width,
        );
      }

      // Filet et total **seulement quand le total additionne quelque chose** —
      // même règle que le solde, et pour la même raison : un versement unique
      // suivi d'un total qui le répète dirait deux fois le même chiffre sur un
      // papier qui se recompte.
      if (!_totalRepeatsHistory(printedPayments)) {
        lines.add(_rule(width));
        emphasised(
          () => _addTotal(
            lines,
            model.labels.historyTotalLabel,
            model.printedPaymentsTotal,
            width,
          ),
        );
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

    // ── La zone à signer, juste avant les remerciements.
    //
    // C'est le CAISSIER qui signe : sur un papier que le parent emporte, la
    // signature du parent ne vaudrait que contre une souche, et la thermique
    // n'en produit aucune.
    //
    // Trois lignes, dans cet ordre, parce que c'est la forme d'une vraie zone
    // de signature : le libellé dit qui signe, le blanc donne la hauteur du
    // geste, le trait dit où il s'arrête. On signe AU-DESSUS du trait — le
    // remplacer par un pointillé sur la ligne du libellé ferait signer dans une
    // hauteur de ligne thermique, soit deux millimètres.
    //
    // ⚠️ Conditionnée au libellé, comme le titre du solde : `_wrapped('')` rend
    // une liste VIDE, et un trait à signer sans rien qui dise qui signe ne se
    // remplit pas. Une traduction incomplète escamote la zone entière plutôt
    // que d'imprimer deux blancs et un trait orphelins.
    final signature = _wrapped(model.labels.signatureLabel, width);
    if (signature.isNotEmpty) {
      lines.add(_rule(width));
      emphasised(() => lines.addAll(signature));
      lines.add('');
      lines.add('');
      // Le trait, à DROITE et sur la moitié de la laize : une signature se pose
      // à droite sur une pièce, et la moitié suffit — plus large, il toucherait
      // le bord que la thermique n'imprime jamais tout à fait.
      //
      // En pointillé, jamais en trait plein ni en soulignés : le gabarit pose
      // déjà ses filets en `-` pour cette raison (le rendu thermique d'un trait
      // continu bave), et un pointillé se distingue d'un filet de section.
      lines.add(('.' * (width ~/ 2)).padLeft(width));
      lines.add(_rule(width));
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

    return [
      for (var i = 0; i < lines.length; i++)
        TicketLine(lines[i], bold: bold.contains(i)),
    ];
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

  /// Le total de l'historique ne ferait-il que **redire** l'unique versement
  /// qu'il coiffe ?
  ///
  /// Jumeau de [_totalRepeatsDetail], mais la réponse y est plus simple, et il
  /// faut dire pourquoi : une entrée d'historique porte un **sac**, là où une
  /// ligne de solde porte un scalaire. Le total d'un versement unique est donc
  /// toujours ce versement, y compris quand il a mêlé deux devises — il les
  /// réécrirait sur une ligne de plus, dans l'autre sens, sans rien apprendre.
  /// Le nombre de versements suffit à trancher, et l'égalité qui vivait ici
  /// était vraie par construction.
  static bool _totalRepeatsHistory(List<TicketHistoryEntry> history) =>
      history.length == 1;

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
