import 'package:fl_nodes_core/fl_nodes_core.dart';

import 'run_context.dart';

/// A friendlier facade over fl_nodes_core's [OnNodeExecute] positional-
/// callback shape, handed to the closures built with `automationNode` and
/// its `triggerNode`/`conditionNode`/`actionNode` specializations.
class AutomationExecutionContext {
  AutomationExecutionContext({
    required this.ports,
    required this.fields,
    required this.state,
    required this.run,
    required void Function(Set<String>, {bool definitive}) forwardRaw,
    required void Function(Set<(String, dynamic)>) putRaw,
  })  : _forwardRaw = forwardRaw,
        _putRaw = putRaw;

  /// Live port data for this node: resolved values for data inputs, and
  /// whatever has been written so far for data outputs.
  final Map<String, dynamic> ports;

  /// The node's configured field values — its inspector config, as authored
  /// on the canvas (e.g. which canned-message template a "send message"
  /// action node points at).
  final Map<String, dynamic> fields;

  /// Scratch state that survives across repeated [forward] calls for
  /// stateful/loop nodes (fl_nodes_core's `execState`).
  final Map<String, dynamic> state;

  /// The record + variables shared by every node in this run.
  final AutomationRunContext run;

  final void Function(Set<String>, {bool definitive}) _forwardRaw;
  final void Function(Set<(String, dynamic)>) _putRaw;

  /// Forwards control flow to a single named output port. [definitive]
  /// defaults to `true` (this node is done) — pass `false` from a
  /// loop/stateful node that will [forward] again before it's finished, and
  /// `true` on its final iteration. This default differs from
  /// fl_nodes_core's raw callback (which defaults to `false`) because most
  /// automation nodes — triggers, conditions, one-shot actions — really are
  /// done after one [forward] call.
  void forward(String port, {bool definitive = true}) => _forwardRaw({port}, definitive: definitive);

  /// Forwards to several output ports at once (fan-out to more than one
  /// downstream branch simultaneously).
  void forwardAll(Set<String> ports, {bool definitive = true}) =>
      _forwardRaw(ports, definitive: definitive);

  /// Writes [data] to a data output port, propagating it to every node
  /// linked to that port.
  void put(String port, dynamic data) => _putRaw({(port, data)});
}
