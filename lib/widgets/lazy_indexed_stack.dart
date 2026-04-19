import 'package:flutter/material.dart';

/// Like [IndexedStack] but only builds child [index] the first time it is
/// shown. Once a child has been visited, it stays alive (so state is
/// preserved when switching tabs). Saves cold-start work and memory for
/// tabs the user never opens.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration sizingDuration; // unused; kept for API parity if we add fades

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.sizingDuration = Duration.zero,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _visited = List<bool>.filled(widget.children.length, false);
    _visited[widget.index] = true;
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _visited[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (_visited[i]) return widget.children[i];
        // Placeholder for unvisited tabs — zero work, takes no space because
        // IndexedStack only paints the active child.
        return const SizedBox.shrink();
      }),
    );
  }
}
