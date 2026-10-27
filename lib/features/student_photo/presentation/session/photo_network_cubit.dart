import 'package:school_app_flutter/core/offline/network_status_cubit.dart';

/// En ligne ou non, pour la séance : une photo prise hors connexion se dit
/// « en file », et le bandeau rassure sur son envoi au retour du réseau.
class PhotoNetworkCubit extends NetworkStatusCubit {
  PhotoNetworkCubit(super.connectivity);
}
