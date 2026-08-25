import 'dart:ui' as ui;

import 'package:fl_nodes_core/src/widgets/node_editor_render_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// A node whose own state changes its height, with no controller event to go
/// with it — a host's chrome reacting to a run status, a validation ring, a
/// spinner. Exactly the case the layer used to skip.
class _SelfDirtyingNode extends StatefulWidget {
  const _SelfDirtyingNode({super.key});

  static final List<VoidCallback> grow = [];

  @override
  State<_SelfDirtyingNode> createState() => _SelfDirtyingNodeState();
}

class _SelfDirtyingNodeState extends State<_SelfDirtyingNode> {
  double _height = 80;

  @override
  void initState() {
    super.initState();
    _SelfDirtyingNode.grow.add(() {
      if (mounted) setState(() => _height = 140);
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: _height,
        child: const ColoredBox(color: Color(0xFF455A64)),
      );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a node that dirties itself is laid out and keeps painting',
    (WidgetTester tester) async {
      _SelfDirtyingNode.grow.clear();

      final FlNodesController controller = createTestController(snapToGrid: false);
      final ({List<String> nodeIds, List<String> linkIds}) graph =
          buildTestGraph(controller, nodeCount: 2);

      final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
        'lib/shaders/grid.frag',
      );

      // **No `MaterialApp`, deliberately.** The layer reads
      // `ModalRoute.of(context)?.isCurrent` into `isModalPresent` and, when it
      // is true, re-announces every child on every layout pass — which papers
      // over exactly the defect under test. Under a route it is true, so a
      // `MaterialApp` harness passes this test even without the fix. An editor
      // that is not the current route — behind a dialog, in a sheet, or built
      // before the route settles — gets false, and that is the case this
      // pins down.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: NodeEditorRenderObjectWidget(
              controller: controller,
              gridShader: program.fragmentShader(),
              nodeBuilder: (node, _) => _SelfDirtyingNode(key: node.key),
            ),
          ),
        ),
      );
      await _settle(tester);

      final String nodeId = graph.nodeIds.first;
      expect(controller.getNodeById(nodeId)!.cachedRenderboxRect.height, 80);

      // No controller event: the widgets rebuild themselves, which is the
      // whole point. Before the fix the layer never re-measured them, they
      // stayed `_needsLayout`, and `_paintWithContext` then skipped them —
      // the nodes vanished and left only the layer's cached drop shadow.
      for (final VoidCallback grow in _SelfDirtyingNode.grow) {
        grow();
      }
      await _settle(tester);

      for (final String id in graph.nodeIds) {
        expect(
          controller.getNodeById(id)!.cachedRenderboxRect.height,
          140,
          reason: 'node $id was never re-measured',
        );
      }

      // Nothing may still be waiting for layout, or it will not paint.
      final NodeEditorRenderBox renderBox = tester
          .element(
            find.byType(NodeEditorRenderObjectWidget),
          )
          .renderObject! as NodeEditorRenderBox;
      renderBox.visitChildren((RenderObject child) {
        expect(child.debugNeedsLayout, isFalse);
      });

      controller.dispose();
    },
  );
}
