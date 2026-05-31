import type { ToolDefinition } from '../llm/types.js';

export const AGENT_TOOLS: ToolDefinition[] = [
  {
    name: 'search_architecture',
    description:
      'Search the architecture repository by keyword across all entity types: domains, capabilities, processes, systems, technologies, and data entities. Use this when the user asks about a concept, abbreviation, or term and you need to find where it exists in the organization.',
    inputSchema: {
      type: 'object',
      properties: {
        keyword: {
          type: 'string',
          description: 'Search term or keyword to find across all architecture entities',
        },
      },
      required: ['keyword'],
    },
  },
  {
    name: 'get_full_path',
    description:
      'Retrieve the full architecture traceability path: Domain → Capability → Process → System → Technology. Use this to show how business domains connect through capabilities and processes down to systems and technologies. Supports optional filters by domain, capability, system, or technology name.',
    inputSchema: {
      type: 'object',
      properties: {
        domain_name: {
          type: 'string',
          description: 'Filter by domain name (partial match)',
        },
        capability_name: {
          type: 'string',
          description: 'Filter by capability name (partial match)',
        },
        system_name: {
          type: 'string',
          description: 'Filter by system name (partial match)',
        },
        technology_name: {
          type: 'string',
          description: 'Filter by technology name (partial match)',
        },
      },
    },
  },
  {
    name: 'get_reverse_impact',
    description:
      'Perform reverse impact analysis starting from a technology. Traces Technology → Systems → Processes → Capabilities → Domains to show all business areas impacted by a technology change, deprecation, or upgrade. Also shows affected data entities.',
    inputSchema: {
      type: 'object',
      properties: {
        technology_name: {
          type: 'string',
          description: 'Technology name to analyze impact for (e.g., "Java", "Kafka", "PostgreSQL")',
        },
      },
      required: ['technology_name'],
    },
  },
  {
    name: 'expand_node',
    description:
      'Get the direct children/related entities of a specific architecture node. Domain expands to capabilities, capability to processes, process to systems, system to technologies and data entities. Use this when drilling down into a specific entity.',
    inputSchema: {
      type: 'object',
      properties: {
        node_type: {
          type: 'string',
          enum: ['domain', 'capability', 'process', 'system', 'technology', 'data_entity'],
          description: 'Type of the node to expand',
        },
        node_id: {
          type: 'string',
          description: 'UUID of the node to expand',
        },
      },
      required: ['node_type', 'node_id'],
    },
  },
  {
    name: 'list_entities',
    description:
      'List all entities of a given type. Use this to get a complete inventory of domains, capabilities, processes, systems, technologies, or data entities.',
    inputSchema: {
      type: 'object',
      properties: {
        entity_type: {
          type: 'string',
          enum: ['domain', 'capability', 'process', 'system', 'technology', 'data_entity'],
          description: 'Type of entities to list',
        },
      },
      required: ['entity_type'],
    },
  },
  {
    name: 'suggest_similar',
    description:
      'Find existing entities similar to a given name using fuzzy matching. Use this before creating new entities to check for duplicates or near-matches. Returns similarity scores.',
    inputSchema: {
      type: 'object',
      properties: {
        entity_type: {
          type: 'string',
          enum: ['domain', 'capability', 'process', 'system', 'technology', 'data_entity'],
          description: 'Type of entity to search for similar names',
        },
        name: {
          type: 'string',
          description: 'Name to find similar entities for',
        },
      },
      required: ['entity_type', 'name'],
    },
  },
  {
    name: 'create_entity',
    description:
      'Create a new entity in the architecture repository. Always use suggest_similar first to check for duplicates before creating. Returns the created entity.',
    inputSchema: {
      type: 'object',
      properties: {
        entity_type: {
          type: 'string',
          enum: ['domain', 'capability', 'process', 'system', 'technology', 'data_entity'],
          description: 'Type of entity to create',
        },
        name: {
          type: 'string',
          description: 'Name of the new entity',
        },
        description: {
          type: 'string',
          description: 'Description of the new entity',
        },
      },
      required: ['entity_type', 'name'],
    },
  },
];
