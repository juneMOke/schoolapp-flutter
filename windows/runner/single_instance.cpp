#include "single_instance.h"

#ifndef ETEELO_INSTANCE_ENV
#define ETEELO_INSTANCE_ENV "prod"
#endif

#define ETEELO_WIDEN_(text) L##text
#define ETEELO_WIDEN(text) ETEELO_WIDEN_(text)

namespace {

#ifndef _DEBUG
// `Local\` : propre à la session Windows de l'utilisateur. Deux comptes
// ouverts sur un même poste gardent chacun leur application.
constexpr const wchar_t kMutexName[] =
    L"Local\\EteeloConnect-" ETEELO_WIDEN(ETEELO_INSTANCE_ENV);
#endif

// Propriété posée sur la fenêtre principale : le titre est le même pour tous
// les environnements, il ne suffit pas à la reconnaître.
constexpr const wchar_t kWindowProperty[] =
    L"EteeloConnect-" ETEELO_WIDEN(ETEELO_INSTANCE_ENV);

#ifndef _DEBUG
BOOL CALLBACK BringForward(HWND window, LPARAM) {
  if (::GetPropW(window, kWindowProperty) == nullptr) return TRUE;
  // Fenêtre encore cachée (première image pas rendue) : elle s'affichera
  // d'elle-même, la montrer maintenant ne donnerait qu'un cadre noir.
  if (!::IsWindowVisible(window)) return FALSE;
  if (::IsIconic(window)) ::ShowWindow(window, SW_RESTORE);
  ::SetForegroundWindow(window);
  return FALSE;
}
#endif

}  // namespace

bool AcquireSingleInstance() {
#ifdef _DEBUG
  return true;
#else
  // Jamais refermé : le système le libère à la fin du processus, même brutale.
  HANDLE mutex = ::CreateMutexW(nullptr, FALSE, kMutexName);
  if (mutex == nullptr) return true;  // Pas de verrou possible : on démarre.
  if (::GetLastError() != ERROR_ALREADY_EXISTS) return true;
  ::CloseHandle(mutex);
  ::EnumWindows(BringForward, 0);
  return false;
#endif
}

void MarkSingleInstanceWindow(HWND window) {
  ::SetPropW(window, kWindowProperty, reinterpret_cast<HANDLE>(1));
}
