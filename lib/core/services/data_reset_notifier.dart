import 'package:flutter/material.dart';

/*
  ==================================================================
  "Everything you were showing is gone — read it again."
  ==================================================================

  Every screen in this app loads its data once, when its cubit is
  created, and reloads when the user comes back from somewhere that
  could have changed it. That covers every ordinary edit, because an
  edit happens on a screen you had to navigate to.

  A RESTORE does not work like that. It replaces all eight tables at
  once, from the Settings tab, while the Dashboard and Stores tabs are
  sitting in the shell's IndexedStack still holding the cubits they
  built when the app started. Nothing about that navigation tells them
  anything happened.

  The result would be the worst kind of wrong: a dashboard showing a
  total receivable that was true a minute ago, for a database that no
  longer contains those transactions. Money that looks right and is
  not is precisely what this app spends its effort avoiding.

  So a wholesale replacement raises this flag, and the screens holding
  long-lived state listen for it.

  ------------------------------------------------------------------
  Why not just rebuild the whole shell, or force navigation?
  ------------------------------------------------------------------

  Both were considered. Keying the navigation shell so it rebuilds
  from scratch is fewer lines, but it depends on how go_router's
  StatefulShellRoute treats a recreated element subtree — behaviour
  this project has no device to verify on. `goBranch(initialLocation:
  true)` only resets a branch's navigation STACK; a branch already at
  its root does not rebuild, so the dashboard would keep its stale
  numbers anyway.

  An explicit signal is more code and it is obvious. Nothing about it
  depends on a framework detail being kind.
*/
class DataResetNotifier extends ChangeNotifier {
  int _generation = 0;

  /// Increments every time the database is replaced wholesale. Screens
  /// compare it against what they last loaded at.
  int get generation => _generation;

  /// Called after a restore commits — never after an ordinary edit,
  /// which the screens already handle by reloading on navigation.
  void markReplaced() {
    _generation++;
    notifyListeners();
  }
}

/*
  Calls [onReset] whenever the database has been replaced since this
  widget was built.

  A StatefulWidget rather than a plain listener because it has to
  remember the generation it last acted on: the notifier fires once,
  but a screen may be rebuilt many times afterwards, and reloading on
  every rebuild would be an infinite loop.

  Usage — wrap the screen INSIDE its BlocProvider, so the cubit is
  reachable:

    BlocProvider(
      create: (_) => locator<DashboardCubit>()..loadDashboard(),
      child: DataResetListener(
        onReset: (context) => context.read<DashboardCubit>().loadDashboard(),
        child: const _DashboardView(),
      ),
    );
*/
class DataResetListener extends StatefulWidget {
  final void Function(BuildContext context) onReset;
  final Widget child;

  const DataResetListener({
    super.key,
    required this.onReset,
    required this.child,
  });

  @override
  State<DataResetListener> createState() => _DataResetListenerState();
}

class _DataResetListenerState extends State<DataResetListener> {
  final DataResetNotifier _notifier = dataResetNotifier;

  late int _seenGeneration = _notifier.generation;

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onNotified);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotified);
    super.dispose();
  }

  void _onNotified() {
    if (!mounted) return;
    if (_notifier.generation == _seenGeneration) return;

    _seenGeneration = _notifier.generation;

    /*
      After the frame, not during it. The notifier fires from a cubit
      callback that may already be inside a build, and a reload emits a
      new state — emitting during a build is a framework error.
    */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReset(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/*
  A single instance, reached directly rather than through get_it.

  It holds no dependencies and has exactly one job, and the widget
  above needs it before it has a BuildContext to resolve anything
  with. Registering it would add a lookup and change nothing.
*/
final DataResetNotifier dataResetNotifier = DataResetNotifier();
