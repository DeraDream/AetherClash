import 'dart:async';
import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class NetworkTopologyView extends ConsumerStatefulWidget {
  const NetworkTopologyView({super.key});

  @override
  ConsumerState<NetworkTopologyView> createState() =>
      _NetworkTopologyViewState();
}

class _NetworkTopologyViewState extends ConsumerState<NetworkTopologyView> {
  static const _pollInterval = Duration(seconds: 1);

  final Set<String> _collapsedSummaryNodes = {};
  final Set<String> _expandedDetailNodes = {};

  Timer? _pollTimer;
  List<TrackerInfo> _connections = const [];
  bool _paused = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshConnections());
      _pollTimer = Timer.periodic(
        _pollInterval,
        (_) => unawaited(_refreshConnections()),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshConnections() async {
    if (!mounted || _paused || _polling) return;
    _polling = true;
    try {
      final connections = await ref.read(coreHandlerProvider).getConnections();
      if (!mounted || _paused) return;
      setState(() {
        _connections = connections;
      });
    } catch (_) {
      // Keep the last successful snapshot while the core is restarting.
    } finally {
      _polling = false;
    }
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
    if (!_paused) {
      unawaited(_refreshConnections());
    }
  }

  bool _isExpanded(_TopologyNode node) {
    if (!node.hasChildren) return false;
    return switch (node.type) {
      _TopologyNodeType.rule ||
      _TopologyNodeType.client => _expandedDetailNodes.contains(node.id),
      _ => !_collapsedSummaryNodes.contains(node.id),
    };
  }

  void _toggleNode(_TopologyNode node) {
    if (!node.hasChildren) return;
    setState(() {
      switch (node.type) {
        case _TopologyNodeType.rule:
        case _TopologyNodeType.client:
          if (!_expandedDetailNodes.add(node.id)) {
            _expandedDetailNodes.remove(node.id);
          }
          break;
        case _TopologyNodeType.group:
        case _TopologyNodeType.proxy:
          if (!_collapsedSummaryNodes.add(node.id)) {
            _collapsedSummaryNodes.remove(node.id);
          }
          break;
        case _TopologyNodeType.port:
          break;
      }
    });
  }

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  Widget build(BuildContext context) {
    final roots = _buildHierarchy(_connections);
    final stats = _TopologyStats.fromConnections(_connections);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TopologyStatsLine(
                stats: stats,
                text: (zh, en) => _text(context, zh, en),
              ),
            ),
            IconButton(
              tooltip: _paused
                  ? _text(context, '继续', 'Resume')
                  : _text(context, '暂停', 'Pause'),
              visualDensity: VisualDensity.compact,
              onPressed: _togglePause,
              icon: Icon(
                _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 19,
                color: _paused
                    ? context.toneColor(GlassTone.warning)
                    : context.glass.secondaryLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TopologyLegend(text: (zh, en) => _text(context, zh, en)),
        const SizedBox(height: 12),
        if (roots.isEmpty)
          _TopologyEmptyState(
            label: _text(context, '等待连接数据...', 'Waiting for connections...'),
          )
        else
          _TopologyCanvas(
            roots: roots,
            isExpanded: _isExpanded,
            onToggle: _toggleNode,
          ),
      ],
    );
  }
}

enum _TopologyNodeType { group, proxy, rule, client, port }

class _TopologyBuilderNode {
  _TopologyBuilderNode({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final _TopologyNodeType type;
  final Map<String, _TopologyBuilderNode> children = {};
  int connections = 0;
  int traffic = 0;

  _TopologyBuilderNode child({
    required String id,
    required String name,
    required _TopologyNodeType type,
  }) {
    return children.putIfAbsent(
      id,
      () => _TopologyBuilderNode(id: id, name: name, type: type),
    );
  }

  void addTraffic(int value) {
    connections++;
    traffic += value;
  }

  _TopologyNode freeze() {
    final frozenChildren = children.values.map((node) => node.freeze()).toList()
      ..sort((a, b) {
        final trafficOrder = b.traffic.compareTo(a.traffic);
        return trafficOrder != 0 ? trafficOrder : a.name.compareTo(b.name);
      });
    return _TopologyNode(
      id: id,
      name: name,
      type: type,
      connections: connections,
      traffic: traffic,
      children: frozenChildren,
    );
  }
}

class _TopologyNode {
  const _TopologyNode({
    required this.id,
    required this.name,
    required this.type,
    required this.connections,
    required this.traffic,
    required this.children,
  });

  final String id;
  final String name;
  final _TopologyNodeType type;
  final int connections;
  final int traffic;
  final List<_TopologyNode> children;

  bool get hasChildren => children.isNotEmpty;
}

List<_TopologyNode> _buildHierarchy(List<TrackerInfo> connections) {
  final root = _TopologyBuilderNode(
    id: 'root',
    name: 'Connections',
    type: _TopologyNodeType.group,
  );

  for (final connection in connections) {
    final chains = connection.chains;
    final proxy = chains.isEmpty ? 'DIRECT' : chains.first;
    final group = chains.length > 1 ? chains[1] : proxy;
    final rule = connection.rule.isEmpty ? 'DIRECT' : connection.rule;
    final fullRule = connection.rulePayload.isEmpty
        ? rule
        : '$rule: ${connection.rulePayload}';
    final client = connection.metadata.sourceIP.isEmpty
        ? 'Unknown'
        : connection.metadata.sourceIP;
    final port = connection.metadata.sourcePort.isEmpty
        ? 'Unknown'
        : connection.metadata.sourcePort;
    final traffic = connection.upload + connection.download;

    final groupNode = root.child(
      id: 'group-$group',
      name: group,
      type: _TopologyNodeType.group,
    )..addTraffic(traffic);

    final proxyNode = groupNode.child(
      id: 'proxy-$group-$proxy',
      name: proxy,
      type: _TopologyNodeType.proxy,
    )..addTraffic(traffic);

    final ruleNode = proxyNode.child(
      id: 'rule-$group-$proxy-$fullRule',
      name: fullRule,
      type: _TopologyNodeType.rule,
    )..addTraffic(traffic);

    final clientNode = ruleNode.child(
      id: 'client-$group-$proxy-$fullRule-$client',
      name: client,
      type: _TopologyNodeType.client,
    )..addTraffic(traffic);

    clientNode
        .child(
          id: 'port-$group-$proxy-$fullRule-$client-$port',
          name: port,
          type: _TopologyNodeType.port,
        )
        .addTraffic(traffic);
  }

  return root.children.values.map((node) => node.freeze()).toList()
    ..sort((a, b) {
      final trafficOrder = b.traffic.compareTo(a.traffic);
      return trafficOrder != 0 ? trafficOrder : a.name.compareTo(b.name);
    });
}

class _TopologyStats {
  const _TopologyStats({
    required this.clients,
    required this.rules,
    required this.groups,
    required this.proxies,
    required this.traffic,
  });

  factory _TopologyStats.fromConnections(List<TrackerInfo> connections) {
    final clients = <String>{};
    final rules = <String>{};
    final groups = <String>{};
    final proxies = <String>{};
    var traffic = 0;

    for (final connection in connections) {
      clients.add(
        connection.metadata.sourceIP.isEmpty
            ? 'Unknown'
            : connection.metadata.sourceIP,
      );
      rules.add(connection.rule.isEmpty ? 'DIRECT' : connection.rule);
      final chains = connection.chains;
      final proxy = chains.isEmpty ? 'DIRECT' : chains.first;
      final group = chains.length > 1 ? chains[1] : proxy;
      proxies.add(proxy);
      groups.add(group);
      traffic += connection.upload + connection.download;
    }

    return _TopologyStats(
      clients: clients.length,
      rules: rules.length,
      groups: groups.length,
      proxies: proxies.length,
      traffic: traffic,
    );
  }

  final int clients;
  final int rules;
  final int groups;
  final int proxies;
  final int traffic;
}

class _TopologyStatsLine extends StatelessWidget {
  const _TopologyStatsLine({required this.stats, required this.text});

  final _TopologyStats stats;
  final String Function(String zh, String en) text;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodySmall?.copyWith(
      color: context.glass.secondaryLabel,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Wrap(
      spacing: 7,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${stats.clients} ${text('客户端', 'clients')}', style: style),
        Text('·', style: style),
        Text('${stats.rules} ${text('规则', 'rules')}', style: style),
        Text('·', style: style),
        Text('${stats.groups} ${text('代理组', 'groups')}', style: style),
        Text('·', style: style),
        Text('${stats.proxies} ${text('节点', 'nodes')}', style: style),
        Text('·', style: style),
        Text(stats.traffic.traffic.show, style: style),
      ],
    );
  }
}

class _TopologyLegend extends StatelessWidget {
  const _TopologyLegend({required this.text});

  final String Function(String zh, String en) text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _TopologyLegendItem(
          type: _TopologyNodeType.group,
          icon: Icons.hub_rounded,
          label: text('代理组', 'Proxy groups'),
        ),
        _TopologyLegendItem(
          type: _TopologyNodeType.proxy,
          icon: Icons.dns_rounded,
          label: text('代理节点', 'Proxy nodes'),
        ),
        _TopologyLegendItem(
          type: _TopologyNodeType.rule,
          icon: Icons.filter_alt_rounded,
          label: text('规则', 'Rules'),
        ),
        _TopologyLegendItem(
          type: _TopologyNodeType.client,
          icon: Icons.computer_rounded,
          label: text('来源 IP', 'Source IP'),
        ),
        _TopologyLegendItem(
          type: _TopologyNodeType.port,
          icon: Icons.tag_rounded,
          label: text('来源端口', 'Source port'),
        ),
      ],
    );
  }
}

class _TopologyLegendItem extends StatelessWidget {
  const _TopologyLegendItem({
    required this.type,
    required this.icon,
    required this.label,
  });

  final _TopologyNodeType type;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _topologyColor(context, type);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.glass.secondaryLabel,
          ),
        ),
      ],
    );
  }
}

class _TopologyEmptyState extends StatelessWidget {
  const _TopologyEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_rounded,
              size: 32,
              color: context.glass.secondaryLabel.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.glass.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopologyCanvas extends StatelessWidget {
  const _TopologyCanvas({
    required this.roots,
    required this.isExpanded,
    required this.onToggle,
  });

  final List<_TopologyNode> roots;
  final bool Function(_TopologyNode node) isExpanded;
  final ValueChanged<_TopologyNode> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _TopologyLayout.build(
          roots: roots,
          viewportWidth: constraints.maxWidth,
          isExpanded: isExpanded,
        );
        final viewportHeight = layout.size.height
            .clamp(300.0, 460.0)
            .toDouble();
        return Container(
          height: viewportHeight,
          decoration: BoxDecoration(
            color: context.glass.fill.withValues(
              alpha: context.glass.isDark ? 0.28 : 0.42,
            ),
            borderRadius: AppRadius.all(10),
            border: Border.all(
              color: context.glass.separator.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.70,
            maxScale: 1.45,
            boundaryMargin: const EdgeInsets.all(80),
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TopologyLinkPainter(
                        edges: layout.edges,
                        lineColor: context.glass.secondaryLabel.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                  ),
                  for (final item in layout.nodes)
                    Positioned(
                      left: item.center.dx - item.width / 2,
                      top: item.center.dy - _TopologyLayout.nodeBoxHeight / 2,
                      width: item.width,
                      height: _TopologyLayout.nodeBoxHeight,
                      child: _TopologyNodeWidget(
                        item: item,
                        expanded: isExpanded(item.node),
                        onTap: item.node.hasChildren
                            ? () => onToggle(item.node)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopologyLayout {
  const _TopologyLayout({
    required this.size,
    required this.nodes,
    required this.edges,
  });

  static const nodeHeight = 30.0;
  static const nodeBoxHeight = 50.0;
  static const rowGap = 58.0;
  static const levelGap = 44.0;
  static const paddingX = 34.0;
  static const paddingY = 30.0;

  factory _TopologyLayout.build({
    required List<_TopologyNode> roots,
    required double viewportWidth,
    required bool Function(_TopologyNode node) isExpanded,
  }) {
    final entries = <_RawLayoutNode>[];
    final rawEdges = <(_TopologyNode, _TopologyNode)>[];
    var nextY = paddingY + nodeBoxHeight / 2;

    double visit(_TopologyNode node, int depth) {
      final visibleChildren = isExpanded(node)
          ? node.children
          : const <_TopologyNode>[];
      double y;
      if (visibleChildren.isEmpty) {
        y = nextY;
        nextY += rowGap;
      } else {
        final childYs = <double>[];
        for (final child in visibleChildren) {
          childYs.add(visit(child, depth + 1));
          rawEdges.add((node, child));
        }
        y = (childYs.first + childYs.last) / 2;
      }
      entries.add(
        _RawLayoutNode(node: node, depth: depth, y: y, width: _nodeWidth(node)),
      );
      return y;
    }

    for (final root in roots) {
      visit(root, 0);
      nextY += 10;
    }

    final maxWidthPerDepth = <int, double>{};
    for (final entry in entries) {
      maxWidthPerDepth[entry.depth] = math
          .max(maxWidthPerDepth[entry.depth] ?? 0.0, entry.width)
          .toDouble();
    }

    final centerX = <int, double>{};
    var cursor = paddingX;
    final maxDepth = maxWidthPerDepth.keys.fold<int>(
      0,
      (value, depth) => value > depth ? value : depth,
    );
    for (var depth = 0; depth <= maxDepth; depth++) {
      final width = maxWidthPerDepth[depth] ?? 90;
      if (depth == 0) {
        centerX[depth] = cursor + width / 2;
      } else {
        final previousWidth = maxWidthPerDepth[depth - 1] ?? 90;
        final previousCenter = centerX[depth - 1] ?? paddingX;
        centerX[depth] =
            previousCenter + previousWidth / 2 + levelGap + width / 2;
      }
    }

    final positioned = <_PositionedTopologyNode>[];
    final byNode = <_TopologyNode, _PositionedTopologyNode>{};
    for (final entry in entries) {
      final item = _PositionedTopologyNode(
        node: entry.node,
        center: Offset(centerX[entry.depth] ?? paddingX, entry.y),
        width: entry.width,
      );
      positioned.add(item);
      byNode[entry.node] = item;
    }

    final edges = <_TopologyEdge>[];
    for (final (source, target) in rawEdges) {
      final sourceItem = byNode[source];
      final targetItem = byNode[target];
      if (sourceItem == null || targetItem == null) continue;
      edges.add(
        _TopologyEdge(
          start: Offset(
            sourceItem.center.dx + sourceItem.width / 2,
            sourceItem.center.dy,
          ),
          end: Offset(
            targetItem.center.dx - targetItem.width / 2,
            targetItem.center.dy,
          ),
          connections: target.connections,
        ),
      );
    }

    final contentWidth = positioned.fold<double>(
      paddingX * 2,
      (value, item) => math
          .max(value, item.center.dx + item.width / 2 + paddingX)
          .toDouble(),
    );
    final contentHeight = math
        .max(300.0, nextY + paddingY - rowGap / 2)
        .toDouble();

    return _TopologyLayout(
      size: Size(
        math.max(viewportWidth, contentWidth).toDouble(),
        contentHeight,
      ),
      nodes: positioned,
      edges: edges,
    );
  }

  final Size size;
  final List<_PositionedTopologyNode> nodes;
  final List<_TopologyEdge> edges;

  static double _nodeWidth(_TopologyNode node) {
    final textWidth = node.name.runes.length * 7.0;
    final collapseSpace = node.hasChildren ? 24.0 : 0.0;
    return (textWidth + 28 + collapseSpace).clamp(88.0, 220.0).toDouble();
  }
}

class _RawLayoutNode {
  const _RawLayoutNode({
    required this.node,
    required this.depth,
    required this.y,
    required this.width,
  });

  final _TopologyNode node;
  final int depth;
  final double y;
  final double width;
}

class _PositionedTopologyNode {
  const _PositionedTopologyNode({
    required this.node,
    required this.center,
    required this.width,
  });

  final _TopologyNode node;
  final Offset center;
  final double width;
}

class _TopologyEdge {
  const _TopologyEdge({
    required this.start,
    required this.end,
    required this.connections,
  });

  final Offset start;
  final Offset end;
  final int connections;
}

class _TopologyLinkPainter extends CustomPainter {
  const _TopologyLinkPainter({required this.edges, required this.lineColor});

  final List<_TopologyEdge> edges;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final midX = (edge.start.dx + edge.end.dx) / 2;
      final path = Path()
        ..moveTo(edge.start.dx, edge.start.dy)
        ..cubicTo(
          midX,
          edge.start.dy,
          midX,
          edge.end.dy,
          edge.end.dx,
          edge.end.dy,
        );
      final width = (edge.connections / 5).clamp(1.0, 4.0).toDouble();
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyLinkPainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.lineColor != lineColor;
  }
}

class _TopologyNodeWidget extends StatelessWidget {
  const _TopologyNodeWidget({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _PositionedTopologyNode item;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final node = item.node;
    final color = _topologyColor(context, node.type);
    final glass = context.glass;
    return Tooltip(
      message:
          '${node.name}\n${node.connections} connections\n${node.traffic.traffic.show}',
      child: Column(
        children: [
          SizedBox(
            height: 14,
            child: Text(
              '${node.connections}',
              style: context.textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.all(6),
                child: Container(
                  height: _TopologyLayout.nodeHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: glass.isDark ? 0.15 : 0.10),
                    borderRadius: AppRadius.all(6),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (node.hasChildren) ...[
                        const SizedBox(width: 5),
                        Icon(
                          expanded ? Icons.remove_rounded : Icons.add_rounded,
                          size: 15,
                          color: color,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _topologyColor(BuildContext context, _TopologyNodeType type) {
  return switch (type) {
    _TopologyNodeType.group => context.toneColor(GlassTone.success),
    _TopologyNodeType.proxy => context.toneColor(GlassTone.danger),
    _TopologyNodeType.rule => context.colorScheme.secondary,
    _TopologyNodeType.client => context.colorScheme.primary,
    _TopologyNodeType.port => context.toneColor(GlassTone.warning),
  };
}
