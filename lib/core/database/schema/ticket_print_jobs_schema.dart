import 'package:school_app_flutter/core/database/table_schema.dart';

/// `ticket_print_jobs` — les tickets que CE poste doit encore imprimer
/// (continuité des tickets RC, lot D).
///
/// Un ticket ne sort qu'avec le numéro définitif de son reçu : hors ligne, ce
/// numéro n'existe pas encore. Le geste qui crée le besoin d'un papier écrit
/// donc sa ligne ici, dans SA transaction, et le caissier imprime plus tard,
/// depuis « Tickets à imprimer ». Le promoteur contrôle sa pile jour par jour :
/// chaque numéro doit y avoir un papier — le ticket, ou son annulation.
///
/// Une ligne ne naît QUE d'un geste de ce poste : un versement descendu par le
/// pull n'y entre jamais, il a été imprimé (ou non) sur la tablette qui l'a
/// encaissé.
///
/// **Rien n'est « prêt » en base** : la disponibilité se compose à la lecture,
/// sur le versement et sa correction (numéro définitif, annulation confirmée).
/// Une colonne d'état devrait suivre l'accusé ET le pull, deux écrivains qui
/// n'en savent rien.
///
/// - `kind` : `receipt` (le ticket de caisse) ou `cancellation` (le ticket
///   d'annulation, lot B).
/// - `correction_id` : la correction qui annule, pour un ticket d'annulation.
///   Refusée par le serveur, elle n'annule rien : le ticket disparaît de la
///   file et celui du reçu y revient.
/// - `printed_at` : epoch ms du premier envoi réussi à l'imprimante. La ligne
///   reste, comme preuve du papier.
/// - `last_problem` : la cause du dernier échec d'impression, telle que
///   `ThermalPrinterProblem.name` l'écrit.
const TableSchema ticketPrintJobsTable = TableSchema(
  name: 'ticket_print_jobs',
  createTableSql: '''
    CREATE TABLE ticket_print_jobs (
      id TEXT PRIMARY KEY,
      payment_id TEXT NOT NULL,
      kind TEXT NOT NULL CHECK (kind IN ('receipt', 'cancellation')),
      correction_id TEXT,
      created_at INTEGER NOT NULL,
      printed_at INTEGER,
      last_problem TEXT
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX idx_ticket_print_jobs_payment_kind '
        'ON ticket_print_jobs(payment_id, kind)',
  ],
);

const List<TableSchema> ticketPrintJobsTables = [ticketPrintJobsTable];
