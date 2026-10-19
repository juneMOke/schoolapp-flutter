#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Au centre de la zone de travail de l'écran principal (barre des tâches
  // exclue), et non collée à son coin. Les mesures sont logiques : Create()
  // les remet à l'échelle de l'écran. Sur un petit écran agrandi (1366 à
  // 125 %), la fenêtre se réduit à la zone disponible.
  RECT work_area = {0, 0, 1280, 720};
  ::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const double scale = ::GetDpiForSystem() / 96.0;
  const int work_width =
      static_cast<int>((work_area.right - work_area.left) / scale);
  const int work_height =
      static_cast<int>((work_area.bottom - work_area.top) / scale);
  const int width = work_width < 1280 ? work_width : 1280;
  const int height = work_height < 720 ? work_height : 720;
  const int left =
      static_cast<int>(work_area.left / scale) + (work_width - width) / 2;
  const int top =
      static_cast<int>(work_area.top / scale) + (work_height - height) / 2;
  Win32Window::Point origin(static_cast<unsigned int>(left > 0 ? left : 0),
                            static_cast<unsigned int>(top > 0 ? top : 0));
  Win32Window::Size size(static_cast<unsigned int>(width),
                         static_cast<unsigned int>(height));
  if (!window.Create(L"ETEELO CONNECT", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
