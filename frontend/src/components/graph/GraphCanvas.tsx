import { useCallback, useEffect, useMemo, useRef } from 'react';
import {
  ReactFlow,
  useNodesState,
  useEdgesState,
  MiniMap,
  Controls,
  useReactFlow,
  ReactFlowProvider,
} from '@xyflow/react';
import type { Node, Edge, NodeMouseHandler, EdgeMouseHandler } from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import { AdmNode } from './AdmNode.js';
import { AdmEdge } from './AdmEdge.js';
import { applyDagreLayout } from './layout.js';
import { NODE_CONFIG, getEdgeColor } from '@/constants/node-config.js';
import type { GraphData, Selection, GraphNode, GraphEdge, EntityType } from '@/types/index.js';
import { en } from '@/i18n/index.js';

const nodeTypes = { adm: AdmNode };
const edgeTypes = { adm: AdmEdge };

function toFlowNodes(graphNodes: GraphNode[]): Node[] {
  return graphNodes.map((n) => ({
    id: n.id,
    type: 'adm',
    position: { x: 0, y: 0 },
    data: { label: n.label, entityType: n.type, metadata: n.metadata },
  }));
}

function toFlowEdges(graphEdges: GraphEdge[]): Edge[] {
  return graphEdges.map((e) => ({
    id: e.id,
    source: e.source,
    target: e.target,
    type: 'adm',
    data: { label: e.label },
  }));
}

interface GraphCanvasInnerProps {
  graph: GraphData;
  onSelect: (selection: Selection) => void;
}

function GraphCanvasInner({ graph, onSelect }: GraphCanvasInnerProps) {
  const [nodes, setNodes, onNodesChange] = useNodesState<Node>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);
  const { fitView } = useReactFlow();
  const prevGraphRef = useRef<GraphData | null>(null);

  useEffect(() => {
    if (graph === prevGraphRef.current) return;
    prevGraphRef.current = graph;

    if (graph.nodes.length === 0) {
      setNodes([]);
      setEdges([]);
      return;
    }

    const flowNodes = toFlowNodes(graph.nodes);
    const flowEdges = toFlowEdges(graph.edges);
    const positioned = applyDagreLayout(flowNodes, flowEdges);

    setNodes(positioned);
    setEdges(flowEdges);

    setTimeout(() => fitView({ padding: 0.15, duration: 300 }), 50);
  }, [graph, setNodes, setEdges, fitView]);

  const onNodeClick: NodeMouseHandler = useCallback(
    (_event, node) => {
      onSelect({
        kind: 'node',
        data: {
          id: node.id,
          label: node.data.label as string,
          type: node.data.entityType as EntityType,
          metadata: node.data.metadata as Record<string, string | null> | undefined,
        },
      });
    },
    [onSelect],
  );

  const onEdgeClick: EdgeMouseHandler = useCallback(
    (_event, edge) => {
      onSelect({
        kind: 'edge',
        data: {
          id: edge.id,
          source: edge.source,
          target: edge.target,
          label: (edge.data?.label as string) ?? '',
        },
      });
    },
    [onSelect],
  );

  const onPaneClick = useCallback(() => {
    onSelect(null);
  }, [onSelect]);

  const miniMapNodeColor = useCallback((node: Node) => {
    const entityType = node.data?.entityType as EntityType | undefined;
    if (!entityType) return '#6b7280';
    const colorMap: Record<EntityType, string> = {
      domain: '#2563eb',
      capability: '#7c3aed',
      process: '#059669',
      system: '#d97706',
      technology: '#dc2626',
      data_entity: '#0891b2',
    };
    return colorMap[entityType];
  }, []);

  const nodeCount = nodes.length;
  const edgeCount = edges.length;

  return (
    <div className="relative w-full h-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        onEdgeClick={onEdgeClick}
        onPaneClick={onPaneClick}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        fitView
        minZoom={0.1}
        maxZoom={2}
        proOptions={{ hideAttribution: true }}
      >
        <Controls />
        <MiniMap nodeColor={miniMapNodeColor} pannable zoomable />
      </ReactFlow>

      {nodeCount > 0 && (
        <div className="absolute bottom-2 left-2 px-2 py-1 bg-white/80 rounded text-xs text-gray-500">
          {nodeCount} {en.graph.nodes} · {edgeCount} {en.graph.edges}
        </div>
      )}
    </div>
  );
}

interface GraphCanvasProps {
  graph: GraphData;
  onSelect: (selection: Selection) => void;
}

export function GraphCanvas({ graph, onSelect }: GraphCanvasProps) {
  return (
    <ReactFlowProvider>
      <GraphCanvasInner graph={graph} onSelect={onSelect} />
    </ReactFlowProvider>
  );
}
