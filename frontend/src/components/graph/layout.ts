import Dagre from '@dagrejs/dagre';
import type { Node, Edge } from '@xyflow/react';
import { NODE_CONFIG } from '@/constants/node-config.js';
import type { EntityType } from '@/types/index.js';

const NODE_WIDTH = 220;
const NODE_HEIGHT = 100;

export function applyDagreLayout(nodes: Node[], edges: Edge[]): Node[] {
  const g = new Dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({
    rankdir: 'LR',
    nodesep: 240,
    ranksep: 900,
    marginx: 40,
    marginy: 40,
  });

  for (const node of nodes) {
    const entityType = node.data?.entityType as EntityType | undefined;
    const rank = entityType ? NODE_CONFIG[entityType]?.rank : undefined;
    g.setNode(node.id, {
      width: NODE_WIDTH,
      height: NODE_HEIGHT,
      ...(rank !== undefined && { rank }),
    });
  }

  for (const edge of edges) {
    g.setEdge(edge.source, edge.target);
  }

  Dagre.layout(g);

  return nodes.map((node) => {
    const pos = g.node(node.id);
    return {
      ...node,
      position: {
        x: pos.x - NODE_WIDTH / 2,
        y: pos.y - NODE_HEIGHT / 2,
      },
    };
  });
}
