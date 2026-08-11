import 'package:fl_nodes_core/fl_nodes_core.dart';

import 'run_context.dart';
import 'run_report.dart';

/// A headless host-facing wrapper around [FlNodesController] for running an
/// automation graph **without ever mounting a widget** — the shape a
/// server-less trigger dispatch (e.g. "a ticket's status just changed, see
/// if any saved workflow cares") needs. `FlNodesController` itself has no
/// hard dependency on a widget actually being built — [FlNodesLocalizations.of]
/// falls back cleanly when given a `null` context, and
/// `FlNodesProjectHelper.load` can load a graph directly from a JSON map
/// rather than through a file-picker callback — so this class is a thin,
/// honest wrapper, not a workaround.
///
/// One real constraint carries over from `fl_nodes_core`, not introduced by
/// this package: [FlNodesExecutionHelper.executeGraph] reads
/// `controller.editorKey.currentContext`, and `GlobalKey.currentContext`
/// needs a live `WidgetsBinding` to answer that question at all — even
/// though it's asking "is a widget attached to this key", not building one.
/// Inside a running Flutter app (RepairX included) the binding always
/// exists by construction; a pure-Dart context with no Flutter engine at
/// all (an isolate, a CLI tool) would need to call
/// `WidgetsFlutterBinding.ensureInitialized()` first, and a test needs
/// `TestWidgetsFlutterBinding.ensureInitialized()` — see this package's own
/// tests.
///
/// The visual editor (built by a host like F8F, layering
/// `FlNodesWidget`/`FlNodesController` UI on top of this package) and this
/// engine share the same node prototypes and the same JSON graph format
/// ([exportGraph]/[loadGraph]), so a workflow authored in the editor runs
/// unchanged here — the editor never has to be on screen for production
/// runs.
///
/// **Single-flight.** Like the underlying [FlNodesExecutionHelper], one
/// engine instance runs one graph at a time. [currentRun] is only valid for
/// the duration of a [run] call; a node prototype built with
/// `automationNode`/`triggerNode`/`conditionNode`/`actionNode` reads it via
/// the `getRun` callback it's given at catalog-build time — conventionally
/// `() => engine.currentRun!`. A host that needs concurrent runs constructs
/// one `AutomationEngine` per in-flight run (cheap — see [dispose]) rather
/// than sharing one across overlapping [run] calls.
class AutomationEngine {
  AutomationEngine({
    required this.appVersion,
    required List<FlNodePrototype> nodePrototypes,
  }) : controller = FlNodesController(
          appVersion: appVersion,
          config: const FlNodesConfig(
            autoBuildGraph: false,
            autoExecGraph: false,
            autoSave: false,
          ),
        ) {
    for (final prototype in nodePrototypes) {
      controller.registerNodePrototype(prototype);
    }
  }

  final String appVersion;

  /// The underlying fl_nodes_core controller. Exposed for advanced host
  /// needs (e.g. mounting the same graph in a `FlNodesWidget` for the
  /// in-editor Preview) — most callers only need [loadGraph]/[exportGraph]
  /// and [run].
  final FlNodesController controller;

  AutomationRunContext? _currentRun;

  /// The [AutomationRunContext] for the run currently in flight, or `null`
  /// outside of [run]. See the single-flight note on the class.
  AutomationRunContext? get currentRun => _currentRun;

  /// Serializes the engine's current graph — built via
  /// `controller.addNode`/`controller.addLink`, or previously loaded via
  /// [loadGraph] — to the same JSON shape a host persists per workflow.
  Map<String, dynamic> exportGraph() =>
      controller.project.projectData.toJson(controller.project.dataHandlers);

  /// Loads a previously-exported graph (see [exportGraph]) into the engine,
  /// replacing whatever graph is currently loaded. Throws if [graphJson]
  /// references a node prototype this engine wasn't constructed with.
  Future<void> loadGraph(Map<String, dynamic> graphJson) => controller.project.load(data: graphJson);

  /// Builds and executes the currently loaded graph against [record],
  /// returning a full audit trail.
  ///
  /// A single node's `onExecute` throwing is recorded as that node's
  /// [AutomationNodeOutcome.exception] and aborts the rest of the run — it
  /// does not throw out of [run] itself, since "one action node failed" is
  /// an expected, audit-worthy outcome for a production automation, not a
  /// caller bug. A malformed graph (e.g. [loadGraph] was never called) is
  /// different in kind and is recorded as [AutomationRunReport.error]
  /// instead of a node result.
  Future<AutomationRunReport> run({
    Map<String, dynamic> record = const {},
    Map<String, dynamic>? variables,
  }) async {
    final report = AutomationRunReport(startedAt: DateTime.now());
    final run = AutomationRunContext(record: record, variables: variables);
    _currentRun = run;

    try {
      controller.runner.buildGraph();
      await controller.runner.executeGraph();
    } catch (e) {
      report.error = e.toString();
    } finally {
      // Deliberately not sourced from controller.eventBus: its broadcast
      // stream's delivery isn't reliably drained by the time this await
      // chain resolves (see the note on AutomationRunContext.recordOutcome).
      // `automationNode`'s wrapper records directly into `run` as each node
      // actually executes, which this await chain *does* wait on.
      report.nodes.addAll(run.outcomes);
      report.finishedAt = DateTime.now();
      _currentRun = null;
    }

    return report;
  }

  /// Releases the underlying controller's resources. Call when this engine
  /// instance is done being used (e.g. after a single [run] on a
  /// per-run-scoped engine).
  void dispose() => controller.dispose();
}
