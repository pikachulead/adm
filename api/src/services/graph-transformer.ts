import type {
  ArchitecturePath,
  GraphData,
  GraphEdge,
  GraphNode,
  ImpactPath,
} from '../types/entities.js';

export function pathsToGraph(rows: ArchitecturePath[]): GraphData {
  const nodeMap = new Map<string, GraphNode>();
  const edgeSet = new Set<string>();
  const edges: GraphEdge[] = [];

  for (const row of rows) {
    addNode(nodeMap, row.domain_name, 'domain');

    if (row.capability_name) {
      addNode(nodeMap, row.capability_name, 'capability');
      addEdge(edges, edgeSet, row.domain_name, row.capability_name, row.domain_to_capability_relationship ?? 'owns');
    }

    if (row.process_name) {
      addNode(nodeMap, row.process_name, 'process');
      addEdge(edges, edgeSet, row.capability_name, row.process_name, row.capability_to_process_relationship ?? 'realized_by');
    }

    if (row.system_name) {
      addNode(nodeMap, row.system_name, 'system');
      addEdge(edges, edgeSet, row.process_name!, row.system_name, row.process_to_system_relationship ?? 'supported_by');
    }

    if (row.technology_name) {
      addNode(nodeMap, row.technology_name, 'technology');
      addEdge(edges, edgeSet, row.system_name!, row.technology_name, row.system_to_technology_relationship ?? 'uses');
    }
  }

  return { nodes: [...nodeMap.values()], edges };
}

export function impactPathsToGraph(rows: ImpactPath[]): GraphData {
  const nodeMap = new Map<string, GraphNode>();
  const edgeSet = new Set<string>();
  const edges: GraphEdge[] = [];

  for (const row of rows) {
    addNode(nodeMap, row.technology_name, 'technology');
    addNode(nodeMap, row.system_name, 'system', {
      system_type: row.system_type,
      owner_team: row.owner_team,
    });
    addEdge(edges, edgeSet, row.system_name, row.technology_name, 'uses');

    if (row.process_name) {
      addNode(nodeMap, row.process_name, 'process');
      addEdge(edges, edgeSet, row.process_name, row.system_name, row.process_to_system_relationship ?? 'supported_by');
    }

    if (row.capability_name) {
      addNode(nodeMap, row.capability_name, 'capability');
      addEdge(edges, edgeSet, row.capability_name, row.process_name!, row.capability_to_process_relationship ?? 'realized_by');
    }

    if (row.domain_name) {
      addNode(nodeMap, row.domain_name, 'domain');
      addEdge(edges, edgeSet, row.domain_name, row.capability_name!, row.domain_to_capability_relationship ?? 'owns');
    }

    if (row.data_entity_name) {
      addNode(nodeMap, row.data_entity_name, 'data_entity');
      addEdge(edges, edgeSet, row.system_name, row.data_entity_name, row.system_data_relationship ?? 'uses');
    }
  }

  return { nodes: [...nodeMap.values()], edges };
}

function addNode(
  nodeMap: Map<string, GraphNode>,
  name: string,
  type: GraphNode['type'],
  metadata?: Record<string, string | null>,
): void {
  if (!nodeMap.has(name)) {
    nodeMap.set(name, {
      id: name,
      label: name,
      type,
      ...(metadata && { metadata }),
    });
  }
}

function addEdge(
  edges: GraphEdge[],
  edgeSet: Set<string>,
  source: string,
  target: string,
  label: string,
): void {
  const key = `${source}-${target}-${label}`;
  if (!edgeSet.has(key)) {
    edgeSet.add(key);
    edges.push({ id: key, source, target, label });
  }
}
