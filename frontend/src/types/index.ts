export type EntityType =
  | 'domain'
  | 'capability'
  | 'process'
  | 'system'
  | 'technology'
  | 'data_entity';

export interface GraphNode {
  id: string;
  label: string;
  type: EntityType;
  metadata?: Record<string, string | null>;
}

export interface GraphEdge {
  id: string;
  source: string;
  target: string;
  label: string;
}

export interface GraphData {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface SearchResponse {
  answer: string;
  graph: GraphData;
}

export interface ExpandResponse {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export interface SelectedNode {
  kind: 'node';
  data: GraphNode;
}

export interface SelectedEdge {
  kind: 'edge';
  data: GraphEdge;
}

export type Selection = SelectedNode | SelectedEdge | null;
