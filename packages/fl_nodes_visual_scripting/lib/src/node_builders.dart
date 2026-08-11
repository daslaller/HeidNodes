import 'package:fl_nodes_core/fl_nodes_core.dart';
import 'package:flutter/widgets.dart';

import 'execution_context.dart';
import 'run_context.dart';
import 'run_report.dart';

/// A node's execution logic, written against the friendlier
/// [AutomationExecutionContext] instead of fl_nodes_core's raw positional
/// [OnNodeExecute] callback.
typedef AutomationNodeExecute = Future<void> Function(AutomationExecutionContext ctx);

/// Supplies the [AutomationRunContext] for whichever run is currently in
/// flight on the engine a node prototype is registered with. Conventionally
/// `() => engine.currentRun!` — see [AutomationEngine.currentRun].
typedef RunContextProvider = AutomationRunContext Function();

String _noDescription(dynamic _) => '';

FlControlOutputPortPrototype _controlOut(
  String idName, {
  FlPortGeometricOrientation orientation = FlPortGeometricOrientation.right,
  String? label,
}) =>
    FlControlOutputPortPrototype(
      idName: idName,
      displayName: (_) => label ?? idName,
      geometricOrientation: orientation,
      styleBuilder: flDefaultPortStyleBuilder,
    );

FlControlInputPortPrototype _controlIn(
  String idName, {
  FlPortGeometricOrientation orientation = FlPortGeometricOrientation.left,
  String? label,
}) =>
    FlControlInputPortPrototype(
      idName: idName,
      displayName: (_) => label ?? idName,
      geometricOrientation: orientation,
      styleBuilder: flDefaultPortStyleBuilder,
    );

/// A typed data output port, for a node that produces a value other nodes
/// can wire into their own data inputs (e.g. a trigger exposing the record
/// that fired it).
FlDataOutputPortPrototype<T> dataOut<T>(
  String idName, {
  String? label,
  FlPortGeometricOrientation orientation = FlPortGeometricOrientation.right,
}) =>
    FlDataOutputPortPrototype<T>(
      idName: idName,
      displayName: (_) => label ?? idName,
      linkPrototype: FlLinkPrototype(label: (_) => ''),
      geometricOrientation: orientation,
    );

/// A typed data input port, for a node that consumes a value from an
/// upstream node's data output.
FlDataInputPortPrototype<T> dataIn<T>(
  String idName, {
  String? label,
  FlPortGeometricOrientation orientation = FlPortGeometricOrientation.left,
}) =>
    FlDataInputPortPrototype<T>(
      idName: idName,
      displayName: (_) => label ?? idName,
      geometricOrientation: orientation,
    );

// ---------------------------------------------------------------------------
// Field helpers.
//
// ⚠️ fl_nodes_core serializes a field's value by looking up a DataHandler
// keyed on `FlFieldPrototype.dataType` — NOT on the value's actual runtime
// type (`data_adapters_legacy.dart`'s `toJsonLegacy`/`fromJsonLegacy`:
// `dataHandlers[prototype.dataType]`). `dataType` defaults to `dynamic`, and
// there is no registered handler for `dynamic` itself, so a field prototype
// built without an explicit `dataType` silently serializes its value as
// `null` — no error, no warning, the value is simply gone on the next
// `loadGraph`. This is the exact kind of silent-truncation trap worth a
// convenience wrapper for: every helper below sets `dataType` correctly, so
// reaching for `FlFieldPrototype` directly (bypassing these) is the only way
// to hit it again.
// ---------------------------------------------------------------------------

/// A single-line text field (e.g. "which canned-message template", "which
/// email address"). Round-trips as a plain [String].
FlFieldPrototype textField({
  required String idName,
  required LocalizedString displayName,
  String defaultValue = '',
  Widget Function(String data)? visualizerBuilder,
  EditorBuilder? editorBuilder,
}) =>
    FlFieldPrototype(
      idName: idName,
      displayName: displayName,
      dataType: String,
      defaultData: defaultValue,
      visualizerBuilder: (data) => (visualizerBuilder ?? _defaultTextVisualizer)(data as String),
      editorBuilder: editorBuilder,
      onVisualizerTap: editorBuilder == null ? (data, setData) {} : null,
    );

Widget _defaultTextVisualizer(String data) => Text(data);

/// A toggle/checkbox field (e.g. "only once per ticket"). Round-trips as a
/// plain [bool].
FlFieldPrototype boolField({
  required String idName,
  required LocalizedString displayName,
  bool defaultValue = false,
  Widget Function(bool data)? visualizerBuilder,
  EditorBuilder? editorBuilder,
}) =>
    FlFieldPrototype(
      idName: idName,
      displayName: displayName,
      dataType: bool,
      defaultData: defaultValue,
      visualizerBuilder: (data) => (visualizerBuilder ?? _defaultBoolVisualizer)(data as bool),
      editorBuilder: editorBuilder,
      onVisualizerTap: editorBuilder == null ? (data, setData) {} : null,
    );

Widget _defaultBoolVisualizer(bool data) => Text(data ? 'on' : 'off');

/// A numeric field (e.g. "delay minutes", "cooldown hours"). Round-trips as
/// a plain [double] — use `.round()`/`.toInt()` for integer config.
FlFieldPrototype numberField({
  required String idName,
  required LocalizedString displayName,
  double defaultValue = 0,
  Widget Function(double data)? visualizerBuilder,
  EditorBuilder? editorBuilder,
}) =>
    FlFieldPrototype(
      idName: idName,
      displayName: displayName,
      dataType: double,
      defaultData: defaultValue,
      visualizerBuilder: (data) => (visualizerBuilder ?? _defaultNumberVisualizer)(data as double),
      editorBuilder: editorBuilder,
      onVisualizerTap: editorBuilder == null ? (data, setData) {} : null,
    );

Widget _defaultNumberVisualizer(double data) => Text(data.toString());

/// Builds an [FlNodePrototype] whose execution logic is the friendlier
/// [AutomationExecutionContext] shape instead of fl_nodes_core's raw
/// positional-callback [OnNodeExecute]. This is the primitive
/// [triggerNode]/[conditionNode]/[actionNode] are built from — reach for it
/// directly when a node needs a port shape none of those three cover (e.g. a
/// data-only transform node, or a trigger with extra data outputs).
FlNodePrototype automationNode({
  required String idName,
  required LocalizedString displayName,
  LocalizedString description = _noDescription,
  List<FlPortPrototype> ports = const [],
  List<FlFieldPrototype> fields = const [],
  required RunContextProvider getRun,
  required AutomationNodeExecute onExecute,
  NodeStyleBuilder styleBuilder = flDefaultNodeStyleBuilder,
  NodeHeaderStyleBuilder headerStyleBuilder = flDefaultNodeHeaderStyleBuilder,
}) {
  return FlNodePrototype(
    idName: idName,
    displayName: displayName,
    description: description,
    portPrototypes: ports,
    fieldPrototypes: fields,
    styleBuilder: styleBuilder,
    headerStyleBuilder: headerStyleBuilder,
    onExecute: (rawPorts, rawFields, execState, forward, put) async {
      final run = getRun();
      final ctx = AutomationExecutionContext(
        ports: rawPorts,
        fields: rawFields,
        state: execState,
        run: run,
        forwardRaw: forward,
        putRaw: put,
      );
      try {
        await onExecute(ctx);
        run.recordOutcome(idName, AutomationNodeOutcome.completed);
      } catch (e) {
        run.recordOutcome(idName, AutomationNodeOutcome.exception);
        // Rethrow so fl_nodes_core's own runner still sees the failure —
        // it does its own state/event bookkeeping and run-abort on this
        // exception; swallowing it here would hide the failure from that.
        rethrow;
      }
    },
  );
}

/// An automation entry point: a control-output-only node with **no inputs
/// at all**. fl_nodes_core's own definition of a graph "starting node" (see
/// `FlNodesExecutionHelper._findAndLinearizeSubgraphs`) is exactly "no data
/// inputs, no control inputs, has control outputs" — so a trigger built this
/// way *is* a valid execution entry point with no extra plumbing, and a
/// graph can have several independent triggers (fl_nodes_core walks every
/// starting node as its own independent subgraph).
///
/// [onFire] defaults to immediately forwarding — override it to gate firing
/// on the trigger's own config (e.g. a schedule trigger checking whether
/// `fields['cron']` matches now) or to `put` data onto [dataOutputs] before
/// forwarding (e.g. exposing the triggering record on a data port so
/// downstream nodes can read individual fields off it via wiring instead of
/// reaching into `ctx.run.record` directly).
FlNodePrototype triggerNode({
  required String idName,
  required LocalizedString displayName,
  LocalizedString description = _noDescription,
  String outPort = 'out',
  List<FlFieldPrototype> fields = const [],
  List<FlDataOutputPortPrototype<dynamic>> dataOutputs = const [],
  required RunContextProvider getRun,
  AutomationNodeExecute? onFire,
}) {
  return automationNode(
    idName: idName,
    displayName: displayName,
    description: description,
    fields: fields,
    ports: [_controlOut(outPort), ...dataOutputs],
    getRun: getRun,
    onExecute: onFire ?? (ctx) async => ctx.forward(outPort),
  );
}

/// A branch node: one control input, N named control outputs (e.g.
/// `true`/`false` for an if/else, or any host-defined set of named
/// branches). [evaluate] decides which single output fires — unlike raw
/// fl_nodes_core nodes, only the port name [evaluate] returns is forwarded,
/// so exactly one branch's subgraph executes (the other branches are never
/// walked, matching `FlNodesExecutionHelper`'s per-control-port subgraph
/// semantics).
FlNodePrototype conditionNode({
  required String idName,
  required LocalizedString displayName,
  LocalizedString description = _noDescription,
  String inPort = 'in',
  required List<String> outPorts,
  List<FlFieldPrototype> fields = const [],
  required RunContextProvider getRun,
  required Future<String> Function(AutomationExecutionContext ctx) evaluate,
}) {
  assert(outPorts.isNotEmpty, 'conditionNode "$idName" needs at least one output port');
  return automationNode(
    idName: idName,
    displayName: displayName,
    description: description,
    fields: fields,
    ports: [
      _controlIn(inPort),
      for (final port in outPorts) _controlOut(port),
    ],
    getRun: getRun,
    onExecute: (ctx) async {
      final chosen = await evaluate(ctx);
      assert(
        outPorts.contains(chosen),
        'conditionNode "$idName".evaluate() returned "$chosen", which is not '
        'one of its declared outPorts $outPorts',
      );
      ctx.forward(chosen);
    },
  );
}

/// An action node: one control input, one control output, does real
/// side-effect work via [perform] (host-supplied — e.g. "send an email
/// through RepairX's mail_send Function"). [perform] failing (throwing)
/// surfaces as this node's execution exception, which fl_nodes_core's
/// runner catches, records, and aborts the run from — no partial "half sent"
/// state to reason about.
FlNodePrototype actionNode({
  required String idName,
  required LocalizedString displayName,
  LocalizedString description = _noDescription,
  String inPort = 'in',
  String outPort = 'out',
  List<FlFieldPrototype> fields = const [],
  required RunContextProvider getRun,
  required Future<void> Function(AutomationExecutionContext ctx) perform,
}) {
  return automationNode(
    idName: idName,
    displayName: displayName,
    description: description,
    fields: fields,
    ports: [_controlIn(inPort), _controlOut(outPort)],
    getRun: getRun,
    onExecute: (ctx) async {
      await perform(ctx);
      ctx.forward(outPort);
    },
  );
}
