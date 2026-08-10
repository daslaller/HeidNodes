import 'run_report.dart';

/// Ambient state for a single automation run: the record a trigger fired on
/// (e.g. a ticket's JSON payload) plus scratch variables nodes can read and
/// write across the whole graph as it executes, and the running list of
/// per-node outcomes that becomes [AutomationEngine.run]'s returned report.
///
/// Node prototypes built with `automationNode`/`triggerNode`/`conditionNode`/
/// `actionNode` (see `node_builders.dart`) receive this via the `getRun`
/// callback they're given at catalog-build time — conventionally
/// `() => engine.currentRun!`. See [AutomationEngine.currentRun] for the
/// single-flight constraint this relies on.
class AutomationRunContext {
  AutomationRunContext({
    Map<String, dynamic> record = const {},
    Map<String, dynamic>? variables,
  })  : record = Map<String, dynamic>.unmodifiable(record),
        variables = variables ?? <String, dynamic>{};

  /// The record the run's trigger fired on (e.g. a ticket, a booking). Read
  /// via `{{path}}`-style field config in a node's inspector, or directly by
  /// a node's `onExecute` closure. Immutable — a run's input doesn't change
  /// mid-flight.
  final Map<String, dynamic> record;

  /// Free-form scratch space nodes can write to and later nodes can read
  /// from within the same run (e.g. a value computed by one node and
  /// consumed three nodes downstream, without wiring a data port for it).
  final Map<String, dynamic> variables;

  final List<AutomationNodeResult> _outcomes = [];

  /// Every node outcome recorded so far this run, in execution order.
  List<AutomationNodeResult> get outcomes => List.unmodifiable(_outcomes);

  /// Called by the `automationNode` wrapper immediately around each node's
  /// execution — **not** derived from fl_nodes_core's event bus. That was
  /// the first design here, and it doesn't work: the event bus's broadcast
  /// `StreamController` delivers asynchronously on a schedule that is not
  /// reliably drained by the time `AutomationEngine.run`'s own `await`
  /// chain resolves (confirmed empirically — events arrived after the
  /// awaited `run()` call had already returned and been asserted on).
  /// Recording synchronously, inline with the actual call that produced the
  /// outcome, sidesteps that entirely.
  void recordOutcome(String nodeType, AutomationNodeOutcome outcome) {
    _outcomes.add(AutomationNodeResult(nodeType: nodeType, outcome: outcome));
  }
}
