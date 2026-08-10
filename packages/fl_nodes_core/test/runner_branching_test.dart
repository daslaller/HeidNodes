// Regression coverage for FlNodesExecutionHelper's control-flow branching.
//
// This is the one thing hosts adopting fl_nodes_core as an automation engine
// (rather than a pure visual-scripting demo) depend on most: a node with
// several named control-output ports (an if/else, a switch) must execute
// *only* the branch it forwards to, not every branch it's wired to. Before
// this file, runner.dart had zero automated coverage of that behavior —
// it was only exercised by hand via the example app.
import 'package:fl_nodes_core/fl_nodes_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

FlControlOutputPortPrototype controlOut(String id) => FlControlOutputPortPrototype(
      idName: id,
      displayName: (_) => id,
      geometricOrientation: FlPortGeometricOrientation.right,
      styleBuilder: flDefaultPortStyleBuilder,
    );

FlControlInputPortPrototype controlIn(String id) => FlControlInputPortPrototype(
      idName: id,
      displayName: (_) => id,
      geometricOrientation: FlPortGeometricOrientation.left,
      styleBuilder: flDefaultPortStyleBuilder,
    );

/// A field (not customData) carrying the sink's label — `customData` isn't
/// passed to `onExecute`, so a field is the only way a node's execution
/// logic can tell instances of the same prototype apart.
FlFieldPrototype labelField(String defaultValue) => FlFieldPrototype(
      idName: 'label',
      displayName: (_) => 'Label',
      visualizerBuilder: (data) => const SizedBox.shrink(),
      onVisualizerTap: (data, setData) {},
      defaultData: defaultValue,
    );

void main() {
  // executeGraph() reads controller.editorKey.currentContext for
  // localization fallback even when no widget is ever built, and
  // GlobalKey.currentContext needs a live WidgetsBinding to answer that
  // question at all (regardless of whether a widget is attached to the
  // key) — real apps always have one; tests need it explicit.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlNodesExecutionHelper branching', () {
    late FlNodesController controller;
    late List<String> executed;

    setUp(() {
      executed = [];
      controller = FlNodesController(
        appVersion: '1.0.0',
        config: const FlNodesConfig(autoBuildGraph: false, autoExecGraph: false, autoSave: false),
      );

      controller.registerNodePrototype(
        FlNodePrototype(
          idName: 'start',
          displayName: (_) => 'Start',
          description: (_) => '',
          portPrototypes: [controlOut('out')],
          onExecute: (ports, fields, state, forward, put) async {
            executed.add('start');
            forward({'out'});
          },
        ),
      );

      controller.registerNodePrototype(
        FlNodePrototype(
          idName: 'if_else',
          displayName: (_) => 'If/Else',
          description: (_) => '',
          portPrototypes: [controlIn('in'), controlOut('true'), controlOut('false')],
          fieldPrototypes: [labelField('true')],
          onExecute: (ports, fields, state, forward, put) async {
            executed.add('if_else');
            forward({fields['label'] as String});
          },
        ),
      );

      controller.registerNodePrototype(
        FlNodePrototype(
          idName: 'sink',
          displayName: (_) => 'Sink',
          description: (_) => '',
          portPrototypes: [controlIn('in'), controlOut('out')],
          fieldPrototypes: [labelField('sink')],
          onExecute: (ports, fields, state, forward, put) async {
            executed.add('sink:${fields['label']}');
            forward({'out'});
          },
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('a linear chain executes every node exactly once, in order', () async {
      final start = controller.addNode('start');
      final sink = controller.addNode('sink');
      sink.fields['label']!.data = 'only';

      controller.addLink(start.id, 'out', sink.id, 'in');

      controller.runner.buildGraph();
      await controller.runner.executeGraph();

      expect(executed, ['start', 'sink:only']);
    });

    test('only the taken branch of an if/else executes', () async {
      final start = controller.addNode('start');
      final branch = controller.addNode('if_else');
      final onTrue = controller.addNode('sink');
      final onFalse = controller.addNode('sink');
      onTrue.fields['label']!.data = 'true-branch';
      onFalse.fields['label']!.data = 'false-branch';

      controller.addLink(start.id, 'out', branch.id, 'in');
      controller.addLink(branch.id, 'true', onTrue.id, 'in');
      controller.addLink(branch.id, 'false', onFalse.id, 'in');

      branch.fields['label']!.data = 'true';

      controller.runner.buildGraph();
      await controller.runner.executeGraph();

      // The 'true' branch's sink ran; the 'false' branch's sink never did.
      expect(executed, ['start', 'if_else', 'sink:true-branch']);
    });

    test('flipping the condition takes the other branch, not both', () async {
      final start = controller.addNode('start');
      final branch = controller.addNode('if_else');
      final onTrue = controller.addNode('sink');
      final onFalse = controller.addNode('sink');
      onTrue.fields['label']!.data = 'true-branch';
      onFalse.fields['label']!.data = 'false-branch';

      controller.addLink(start.id, 'out', branch.id, 'in');
      controller.addLink(branch.id, 'true', onTrue.id, 'in');
      controller.addLink(branch.id, 'false', onFalse.id, 'in');

      branch.fields['label']!.data = 'false';

      controller.runner.buildGraph();
      await controller.runner.executeGraph();

      expect(executed, ['start', 'if_else', 'sink:false-branch']);
      expect(executed, isNot(contains('sink:true-branch')));
    });

    test('two independent starting nodes each get their own subgraph', () async {
      final startA = controller.addNode('start');
      final startB = controller.addNode('start');
      final sinkA = controller.addNode('sink');
      final sinkB = controller.addNode('sink');
      sinkA.fields['label']!.data = 'a';
      sinkB.fields['label']!.data = 'b';

      controller.addLink(startA.id, 'out', sinkA.id, 'in');
      controller.addLink(startB.id, 'out', sinkB.id, 'in');

      controller.runner.buildGraph();
      await controller.runner.executeGraph();

      expect(executed.where((e) => e == 'start').length, 2);
      expect(executed, containsAll(['sink:a', 'sink:b']));
    });
  });
}
