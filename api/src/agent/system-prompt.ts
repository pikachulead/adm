import type { IArchitectureRepository } from '../repositories/interfaces.js';
import type { AdmMetadata } from '../types/entities.js';

let cachedPrompt: string | null = null;

export async function buildSystemPrompt(
  repository: IArchitectureRepository,
): Promise<string> {
  if (cachedPrompt) return cachedPrompt;

  const metadata = await repository.getMetadata([
    'MODEL',
    'ENTITY',
    'RELATIONSHIP',
    'VALUE_SET',
    'QUERY_PATTERN',
    'GOVERNANCE_RULE',
  ]);

  const modelSection = formatSection(
    'Architecture Repository Model',
    metadata.filter((m) => m.metadata_type === 'MODEL'),
  );

  const entitySection = formatSection(
    'Entity Definitions',
    metadata.filter((m) => m.metadata_type === 'ENTITY'),
  );

  const relationshipSection = formatSection(
    'Relationship Definitions',
    metadata.filter((m) => m.metadata_type === 'RELATIONSHIP'),
  );

  const valueSetSection = formatSection(
    'Allowed Value Sets',
    metadata.filter((m) => m.metadata_type === 'VALUE_SET'),
  );

  const queryPatternSection = formatSection(
    'Query Patterns',
    metadata.filter((m) => m.metadata_type === 'QUERY_PATTERN'),
  );

  const governanceSection = formatSection(
    'Governance Rules',
    metadata.filter((m) => m.metadata_type === 'GOVERNANCE_RULE'),
  );

  cachedPrompt = `You are an Architecture Domain Model (ADM) assistant. You help users explore and manage an enterprise architecture repository that maps business domains, capabilities, processes, systems, technologies, and data entities.

Your answers must be strictly grounded in the data model and its data. Do not speculate or provide information outside what exists in the repository. If something is not found, say so clearly.

When answering questions:
- Use the available tools to query the repository before answering
- Always search first before assuming something does not exist
- Present results in a clear, structured format
- When showing architecture paths, use the chain notation: Domain --[relationship]--> Capability --[relationship]--> Process --[relationship]--> System --[relationship]--> Technology
- For impact analysis, clearly identify all affected domains, capabilities, processes, systems, and data entities
- When the user wants to add or modify data, always use suggest_similar first to check for duplicates

${modelSection}

${entitySection}

${relationshipSection}

${valueSetSection}

${queryPatternSection}

${governanceSection}

The key relationship chain in this model is:
BusinessDomain --[owns]--> BusinessCapability --[realized_by]--> BusinessProcess --[supported_by]--> BusinessSystem --[uses]--> TechnologyComponent

With a side chain:
BusinessSystem --[creates/reads/updates/deletes/owns/consumes/produces]--> BusinessDataEntity

There are 4 business domains in this repository: Claims, Underwriting, Policy Administration, and Billing and Payments. Each domain has its own capabilities, processes, systems, technologies, and data entities, with some shared across domains (e.g., Policy Administration System is used by multiple domains).`;

  return cachedPrompt;
}

export function clearPromptCache(): void {
  cachedPrompt = null;
}

function formatSection(title: string, items: AdmMetadata[]): string {
  if (items.length === 0) return '';

  const lines = items.map((item) => {
    const parts: string[] = [];

    if (item.entity_name) parts.push(`Entity: ${item.entity_name}`);
    if (item.relationship_name) parts.push(`Relationship: ${item.relationship_name}`);
    if (item.metadata_key && !item.entity_name && !item.relationship_name) {
      parts.push(`Key: ${item.metadata_key}`);
    }

    parts.push(`Purpose: ${item.purpose}`);
    parts.push(`Definition: ${item.definition}`);
    parts.push(`Usage: ${item.usage_guidance}`);

    if (item.example_usage) parts.push(`Example: ${item.example_usage}`);

    return `- ${parts.join('\n  ')}`;
  });

  return `## ${title}\n${lines.join('\n\n')}`;
}
