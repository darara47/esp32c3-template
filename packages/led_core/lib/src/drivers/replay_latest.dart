import 'dart:async';

/// Wraps [updates] so a new listener immediately sees [current]'s value (if
/// any) before any future event.
///
/// A plain [StreamController.broadcast] stream only delivers events emitted
/// *after* a listener subscribes — fine for a single long-lived listener,
/// but wrong for a driver's `state`/`status`/`descriptorUpdates`: a screen
/// that starts watching after the device already connected (e.g. navigating
/// into a device screen from a list tile that connected it first) would
/// otherwise see nothing until the *next* change, which might be minutes
/// away or never.
///
/// Subscribes to [updates] *before* reading [current], both synchronously
/// inside `onListen` — otherwise there's a window between "read the
/// snapshot" and "start forwarding live updates" where an update can slip
/// through unobserved and get lost forever (an `async*` version of this
/// function has exactly that gap, since a generator only resumes past its
/// first `yield` on a later microtask).
Stream<T> replayLatest<T>(T? Function() current, Stream<T> updates) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;

  controller = StreamController<T>(
    onListen: () {
      subscription = updates.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      final value = current();
      if (value != null) controller.add(value);
    },
    onCancel: () => subscription?.cancel(),
  );

  return controller.stream;
}
