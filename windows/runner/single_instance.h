#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <windows.h>

// Instance unique par environnement et par session Windows.
//
// Deux instances sur la même base chiffrée se bloquaient et laissaient des
// processus fantômes. Le second lancement (double-clic, raccourci) ramène
// donc la fenêtre existante au premier plan et s'arrête. Le nom porte
// l'environnement (ETEELO_INSTANCE_ENV, posé à la compilation) : une staging
// ne réveille jamais la production du même poste.
//
// En debug, rien n'est verrouillé : `flutter run` doit pouvoir démarrer même
// si l'application installée est ouverte.

// Vrai si ce processus est la seule instance ; faux si une autre tourne déjà
// (sa fenêtre a alors été ramenée au premier plan) et que celui-ci doit
// s'arrêter.
bool AcquireSingleInstance();

// Marque la fenêtre principale pour qu'un second lancement la retrouve.
void MarkSingleInstanceWindow(HWND window);

#endif  // RUNNER_SINGLE_INSTANCE_H_
