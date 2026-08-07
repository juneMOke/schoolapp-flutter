// Barrel des modèles de synchro (push) de l'agrégat inscription — miroir de
// `openapi_enrollment_sync.yaml`. Séparation de concern : payload figé outbox,
// requête réseau et réponse canonique dans des fichiers distincts.
export 'enrollment_aggregate_request.dart';
export 'enrollment_aggregate_response.dart';
export 'enrollment_outbox_payload.dart';
