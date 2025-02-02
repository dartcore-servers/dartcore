import 'dart:io';

import 'package:dartcore/dartcore.dart';

import 'package:watcher/watcher.dart';

/// Watches for changes in Dart files within the current directory and its subdirectories.
/// When a Dart file is modified, the [onFileChange] callback is triggered.
void watchFiles(Function onFileChange) {
  var watcher = DirectoryWatcher(Directory.current.path);

  watcher.events.listen((event) {
    if (event.type == ChangeType.MODIFY && event.path.endsWith('.dart')) {
      onFileChange();
    }
  });
}

/// Performs a hot reload of the application by shutting down the current
/// instance and restarting it with the same executable and arguments.
///
/// The function first shuts down the app gracefully using [app.shutdown()].
/// Then it starts a new process with the same Dart executable and script
/// arguments, inheriting the standard input/output streams. Finally, it
/// exits the current process with code 0, allowing the new process to take
/// over.
///
/// This function is typically used in conjunction with file watchers to
/// automatically restart the application when source code changes are
/// detected.
void hotReload(App app) async {
  await app.shutdown();
  print("[dartcore] Hot reloading...");
  print("[dartcore]");
  var result = await Process.start(
    Platform.executable,
    Platform.executableArguments + [Platform.script.toFilePath()],
    mode: ProcessStartMode.inheritStdio,
  );
  print("[dartcore] Server started in the background");
  print("[dartcore] Your shell will inherit the new stdout/stderr streams.");
  print("[dartcore] with PID: ${result.pid}");
  exit(0);
}

/// Enables hot reloading of the application when source files change.
///
/// This works by watching for file changes in the current directory and
/// its subdirectories. When a Dart file changes, the application is
/// restarted.
///
/// The application is restarted by calling the [hotReload] function.
void enableHotReload(App app) {
  print("[dartcore] 🗹  Hot Reload");
  watchFiles(() => hotReload(app));
}

/// Disables hot reloading of the application.
///
/// This function is the opposite of [enableHotReload]. Instead of
/// restarting the application when a source file changes, this function
/// does nothing when a source file changes.
///
/// This function is useful for temporarily disabling hot reloading
/// without having to comment out the call to [enableHotReload].
/// or dynamically disable hot reloading based on some condition.
void disableHotReload(App app) {
  print("[dartcore] [𐄂] Hot Reload");
  watchFiles(() => {});
}
