import type { IArchitectureRepository } from '../repositories/interfaces.js';
import type { EntityType, GraphData } from '../types/entities.js';
import { pathsToGraph, impactPathsToGraph } from '../services/graph-transformer.js';

export interface ToolResult {
  data: unknown;
  graph?: GraphData;
}

export async function executeTool(
  toolName: string,
  input: Record<string, unknown>,
  repository: IArchitectureRepository,
): Promise<ToolResult> {
  switch (toolName) {
    case 'search_architecture': {
      const keyword = input.keyword as string;
      const results = await repository.searchByKeyword(keyword);
      return { data: results };
    }

    case 'get_full_path': {
      const filters = {
        domain_name: input.domain_name as string | undefined,
        capability_name: input.capability_name as string | undefined,
        system_name: input.system_name as string | undefined,
        technology_name: input.technology_name as string | undefined,
      };
      const rows = await repository.getFullPath(filters);
      const graph = pathsToGraph(rows);
      return { data: rows, graph };
    }

    case 'get_reverse_impact': {
      const technologyName = input.technology_name as string;
      const rows = await repository.getReversePath(technologyName);
      const graph = impactPathsToGraph(rows);
      return { data: rows, graph };
    }

    case 'expand_node': {
      const nodeType = input.node_type as EntityType;
      const nodeId = input.node_id as string;
      const result = await repository.expandNode(nodeType, nodeId);
      return { data: result, graph: result };
    }

    case 'list_entities': {
      const entityType = input.entity_type as EntityType;
      const entities = await repository.listEntities(entityType);
      return { data: entities };
    }

    case 'suggest_similar': {
      const entityType = input.entity_type as EntityType;
      const name = input.name as string;
      const matches = await repository.findSimilar(entityType, name);
      return { data: matches };
    }

    case 'create_entity': {
      const entityType = input.entity_type as EntityType;
      const entity = await repository.createEntity(entityType, {
        name: input.name as string,
        description: input.description as string | undefined,
      });
      return { data: entity };
    }

    default:
      return { data: { error: `Unknown tool: ${toolName}` } };
  }
}
