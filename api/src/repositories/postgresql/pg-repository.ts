import type pg from 'pg';
import type { IArchitectureRepository } from '../interfaces.js';
import type {
  ArchitecturePath,
  BaseEntity,
  CreateEntityInput,
  EntityType,
  ExpandResult,
  GraphEdge,
  GraphNode,
  ImpactPath,
  MetadataType,
  PathFilters,
  SearchResult,
  SimilarityMatch,
  AdmMetadata,
} from '../../types/entities.js';

const ENTITY_TABLE_MAP: Record<EntityType, { table: string; nameColumn: string; descColumn: string }> = {
  domain: { table: 'business_domains', nameColumn: 'domain_name', descColumn: 'description' },
  capability: { table: 'business_capabilities', nameColumn: 'capability_name', descColumn: 'capability_description' },
  process: { table: 'business_processes', nameColumn: 'process_name', descColumn: 'process_description' },
  system: { table: 'business_systems', nameColumn: 'system_name', descColumn: 'description' },
  technology: { table: 'technology_components', nameColumn: 'technology_name', descColumn: 'description' },
  data_entity: { table: 'business_data_entities', nameColumn: 'entity_name', descColumn: 'entity_description' },
};

export class PgArchitectureRepository implements IArchitectureRepository {
  constructor(private readonly pool: pg.Pool) {}

  async searchByKeyword(keyword: string): Promise<SearchResult[]> {
    const pattern = `%${keyword}%`;
    const query = `
      SELECT id, domain_name AS name, 'domain' AS type, description
      FROM business_domains WHERE domain_name ILIKE $1
      UNION ALL
      SELECT id, capability_name AS name, 'capability' AS type, capability_description AS description
      FROM business_capabilities WHERE capability_name ILIKE $1
      UNION ALL
      SELECT id, process_name AS name, 'process' AS type, process_description AS description
      FROM business_processes WHERE process_name ILIKE $1
      UNION ALL
      SELECT id, system_name AS name, 'system' AS type, description
      FROM business_systems WHERE system_name ILIKE $1
      UNION ALL
      SELECT id, technology_name AS name, 'technology' AS type, description
      FROM technology_components WHERE technology_name ILIKE $1
      UNION ALL
      SELECT id, entity_name AS name, 'data_entity' AS type, entity_description AS description
      FROM business_data_entities WHERE entity_name ILIKE $1
      ORDER BY name
    `;
    const result = await this.pool.query(query, [pattern]);
    return result.rows;
  }

  async getFullPath(filters?: PathFilters): Promise<ArchitecturePath[]> {
    const conditions: string[] = [];
    const params: string[] = [];

    if (filters?.domain_name) {
      params.push(`%${filters.domain_name}%`);
      conditions.push(`d.domain_name ILIKE $${params.length}`);
    }
    if (filters?.capability_name) {
      params.push(`%${filters.capability_name}%`);
      conditions.push(`c.capability_name ILIKE $${params.length}`);
    }
    if (filters?.system_name) {
      params.push(`%${filters.system_name}%`);
      conditions.push(`s.system_name ILIKE $${params.length}`);
    }
    if (filters?.technology_name) {
      params.push(`%${filters.technology_name}%`);
      conditions.push(`t.technology_name ILIKE $${params.length}`);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    const query = `
      SELECT
        d.domain_name,
        dc.relationship_type AS domain_to_capability_relationship,
        c.capability_name,
        cp.relationship_type AS capability_to_process_relationship,
        p.process_name,
        ps.relationship_type AS process_to_system_relationship,
        s.system_name,
        st.relationship_type AS system_to_technology_relationship,
        t.technology_name
      FROM business_domains d
      JOIN domain_capabilities dc ON dc.domain_id = d.id
      JOIN business_capabilities c ON c.id = dc.capability_id
      LEFT JOIN capability_processes cp ON cp.capability_id = c.id
      LEFT JOIN business_processes p ON p.id = cp.process_id
      LEFT JOIN process_systems ps ON ps.process_id = p.id
      LEFT JOIN business_systems s ON s.id = ps.system_id
      LEFT JOIN system_technologies st ON st.system_id = s.id
      LEFT JOIN technology_components t ON t.id = st.technology_id
      ${whereClause}
      ORDER BY d.domain_name, c.capability_name, p.process_name, s.system_name, t.technology_name
    `;
    const result = await this.pool.query(query, params);
    return result.rows;
  }

  async getReversePath(technologyName: string): Promise<ImpactPath[]> {
    const query = `
      SELECT DISTINCT
        t.technology_name,
        s.system_name,
        s.system_type,
        s.owner_team,
        ps.relationship_type AS process_to_system_relationship,
        p.process_name,
        cp.relationship_type AS capability_to_process_relationship,
        c.capability_name,
        dc.relationship_type AS domain_to_capability_relationship,
        d.domain_name,
        sde.crud_type AS system_data_relationship,
        de.entity_name AS data_entity_name
      FROM technology_components t
      JOIN system_technologies st ON st.technology_id = t.id
      JOIN business_systems s ON s.id = st.system_id
      LEFT JOIN process_systems ps ON ps.system_id = s.id
      LEFT JOIN business_processes p ON p.id = ps.process_id
      LEFT JOIN capability_processes cp ON cp.process_id = p.id
      LEFT JOIN business_capabilities c ON c.id = cp.capability_id
      LEFT JOIN domain_capabilities dc ON dc.capability_id = c.id
      LEFT JOIN business_domains d ON d.id = dc.domain_id
      LEFT JOIN system_data_entities sde ON sde.system_id = s.id
      LEFT JOIN business_data_entities de ON de.id = sde.data_entity_id
      WHERE t.technology_name ILIKE $1
      ORDER BY d.domain_name, c.capability_name, p.process_name, s.system_name, de.entity_name
    `;
    const result = await this.pool.query(query, [`%${technologyName}%`]);
    return result.rows;
  }

  async expandNode(nodeType: EntityType, nodeId: string): Promise<ExpandResult> {
    switch (nodeType) {
      case 'domain': return this.expandDomain(nodeId);
      case 'capability': return this.expandCapability(nodeId);
      case 'process': return this.expandProcess(nodeId);
      case 'system': return this.expandSystem(nodeId);
      case 'technology': return this.expandTechnologyReverse(nodeId);
      case 'data_entity': return this.expandDataEntityReverse(nodeId);
      default: return { nodes: [], edges: [] };
    }
  }

  async findSimilar(entityType: EntityType, name: string): Promise<SimilarityMatch[]> {
    const config = ENTITY_TABLE_MAP[entityType];
    if (!config) return [];

    const query = `
      SELECT
        id,
        ${config.nameColumn} AS name,
        $3::text AS type,
        ${config.descColumn} AS description,
        similarity(${config.nameColumn}, $1) AS similarity
      FROM ${config.table}
      WHERE similarity(${config.nameColumn}, $1) > 0.15
         OR ${config.nameColumn} ILIKE $2
      ORDER BY similarity DESC
      LIMIT 10
    `;
    const result = await this.pool.query(query, [name, `%${name}%`, entityType]);
    return result.rows;
  }

  async listEntities(entityType: EntityType): Promise<BaseEntity[]> {
    const config = ENTITY_TABLE_MAP[entityType];
    if (!config) return [];

    const result = await this.pool.query(
      `SELECT * FROM ${config.table} ORDER BY ${config.nameColumn}`
    );
    return result.rows;
  }

  async createEntity(entityType: EntityType, data: CreateEntityInput): Promise<BaseEntity> {
    const config = ENTITY_TABLE_MAP[entityType];
    if (!config) throw new Error(`Unknown entity type: ${entityType}`);

    const query = `
      INSERT INTO ${config.table} (${config.nameColumn}, ${config.descColumn})
      VALUES ($1, $2)
      RETURNING *
    `;
    const result = await this.pool.query(query, [data.name, data.description ?? null]);
    return result.rows[0];
  }

  async getMetadata(types?: MetadataType[]): Promise<AdmMetadata[]> {
    if (types && types.length > 0) {
      const placeholders = types.map((_, i) => `$${i + 1}`).join(', ');
      const result = await this.pool.query(
        `SELECT * FROM adm_metadata WHERE metadata_type IN (${placeholders}) ORDER BY sort_order`,
        types
      );
      return result.rows;
    }

    const result = await this.pool.query(
      'SELECT * FROM adm_metadata ORDER BY sort_order'
    );
    return result.rows;
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.pool.query('SELECT 1');
      return true;
    } catch {
      return false;
    }
  }

  private async expandDomain(domainId: string): Promise<ExpandResult> {
    const query = `
      SELECT c.id, c.capability_name, c.capability_description, dc.relationship_type
      FROM domain_capabilities dc
      JOIN business_capabilities c ON c.id = dc.capability_id
      WHERE dc.domain_id = $1
      ORDER BY c.capability_name
    `;
    const result = await this.pool.query(query, [domainId]);

    const nodes: GraphNode[] = result.rows.map((row) => ({
      id: row.id,
      label: row.capability_name,
      type: 'capability' as EntityType,
      metadata: { description: row.capability_description },
    }));

    const edges: GraphEdge[] = result.rows.map((row) => ({
      id: `${domainId}-${row.id}-${row.relationship_type}`,
      source: domainId,
      target: row.id,
      label: row.relationship_type,
    }));

    return { nodes, edges };
  }

  private async expandCapability(capabilityId: string): Promise<ExpandResult> {
    const processQuery = `
      SELECT p.id, p.process_name, p.process_description, cp.relationship_type
      FROM capability_processes cp
      JOIN business_processes p ON p.id = cp.process_id
      WHERE cp.capability_id = $1
      ORDER BY p.process_name
    `;
    const childQuery = `
      SELECT id, capability_name, capability_description
      FROM business_capabilities
      WHERE parent_capability_id = $1
      ORDER BY capability_name
    `;

    const [processResult, childResult] = await Promise.all([
      this.pool.query(processQuery, [capabilityId]),
      this.pool.query(childQuery, [capabilityId]),
    ]);

    const nodes: GraphNode[] = [
      ...processResult.rows.map((row) => ({
        id: row.id,
        label: row.process_name,
        type: 'process' as EntityType,
        metadata: { description: row.process_description },
      })),
      ...childResult.rows.map((row) => ({
        id: row.id,
        label: row.capability_name,
        type: 'capability' as EntityType,
        metadata: { description: row.capability_description },
      })),
    ];

    const edges: GraphEdge[] = [
      ...processResult.rows.map((row) => ({
        id: `${capabilityId}-${row.id}-${row.relationship_type}`,
        source: capabilityId,
        target: row.id,
        label: row.relationship_type,
      })),
      ...childResult.rows.map((row) => ({
        id: `${capabilityId}-${row.id}-parent_of`,
        source: capabilityId,
        target: row.id,
        label: 'parent_of',
      })),
    ];

    return { nodes, edges };
  }

  private async expandProcess(processId: string): Promise<ExpandResult> {
    const systemQuery = `
      SELECT s.id, s.system_name, s.system_type, s.owner_team, ps.relationship_type
      FROM process_systems ps
      JOIN business_systems s ON s.id = ps.system_id
      WHERE ps.process_id = $1
      ORDER BY s.system_name
    `;
    const childQuery = `
      SELECT id, process_name, process_description
      FROM business_processes
      WHERE parent_process_id = $1
      ORDER BY process_name
    `;

    const [systemResult, childResult] = await Promise.all([
      this.pool.query(systemQuery, [processId]),
      this.pool.query(childQuery, [processId]),
    ]);

    const nodes: GraphNode[] = [
      ...systemResult.rows.map((row) => ({
        id: row.id,
        label: row.system_name,
        type: 'system' as EntityType,
        metadata: { system_type: row.system_type, owner_team: row.owner_team },
      })),
      ...childResult.rows.map((row) => ({
        id: row.id,
        label: row.process_name,
        type: 'process' as EntityType,
        metadata: { description: row.process_description },
      })),
    ];

    const edges: GraphEdge[] = [
      ...systemResult.rows.map((row) => ({
        id: `${processId}-${row.id}-${row.relationship_type}`,
        source: processId,
        target: row.id,
        label: row.relationship_type,
      })),
      ...childResult.rows.map((row) => ({
        id: `${processId}-${row.id}-parent_of`,
        source: processId,
        target: row.id,
        label: 'parent_of',
      })),
    ];

    return { nodes, edges };
  }

  private async expandSystem(systemId: string): Promise<ExpandResult> {
    const techQuery = `
      SELECT t.id, t.technology_name, t.technology_type, st.relationship_type
      FROM system_technologies st
      JOIN technology_components t ON t.id = st.technology_id
      WHERE st.system_id = $1
      ORDER BY t.technology_name
    `;
    const dataQuery = `
      SELECT de.id, de.entity_name, de.entity_description, sde.crud_type
      FROM system_data_entities sde
      JOIN business_data_entities de ON de.id = sde.data_entity_id
      WHERE sde.system_id = $1
      ORDER BY de.entity_name
    `;

    const [techResult, dataResult] = await Promise.all([
      this.pool.query(techQuery, [systemId]),
      this.pool.query(dataQuery, [systemId]),
    ]);

    const nodes: GraphNode[] = [
      ...techResult.rows.map((row) => ({
        id: row.id,
        label: row.technology_name,
        type: 'technology' as EntityType,
        metadata: { technology_type: row.technology_type },
      })),
      ...dataResult.rows.map((row) => ({
        id: row.id,
        label: row.entity_name,
        type: 'data_entity' as EntityType,
        metadata: { description: row.entity_description },
      })),
    ];

    const edges: GraphEdge[] = [
      ...techResult.rows.map((row) => ({
        id: `${systemId}-${row.id}-${row.relationship_type}`,
        source: systemId,
        target: row.id,
        label: row.relationship_type,
      })),
      ...dataResult.rows.map((row) => ({
        id: `${systemId}-${row.id}-${row.crud_type}`,
        source: systemId,
        target: row.id,
        label: row.crud_type,
      })),
    ];

    return { nodes, edges };
  }

  private async expandTechnologyReverse(technologyId: string): Promise<ExpandResult> {
    const query = `
      SELECT s.id, s.system_name, s.system_type, s.owner_team, st.relationship_type
      FROM system_technologies st
      JOIN business_systems s ON s.id = st.system_id
      WHERE st.technology_id = $1
      ORDER BY s.system_name
    `;
    const result = await this.pool.query(query, [technologyId]);

    const nodes: GraphNode[] = result.rows.map((row) => ({
      id: row.id,
      label: row.system_name,
      type: 'system' as EntityType,
      metadata: { system_type: row.system_type, owner_team: row.owner_team },
    }));

    const edges: GraphEdge[] = result.rows.map((row) => ({
      id: `${row.id}-${technologyId}-${row.relationship_type}`,
      source: row.id,
      target: technologyId,
      label: row.relationship_type,
    }));

    return { nodes, edges };
  }

  private async expandDataEntityReverse(dataEntityId: string): Promise<ExpandResult> {
    const query = `
      SELECT s.id, s.system_name, s.system_type, sde.crud_type
      FROM system_data_entities sde
      JOIN business_systems s ON s.id = sde.system_id
      WHERE sde.data_entity_id = $1
      ORDER BY s.system_name
    `;
    const result = await this.pool.query(query, [dataEntityId]);

    const nodes: GraphNode[] = result.rows.map((row) => ({
      id: row.id,
      label: row.system_name,
      type: 'system' as EntityType,
      metadata: { system_type: row.system_type },
    }));

    const edges: GraphEdge[] = result.rows.map((row) => ({
      id: `${row.id}-${dataEntityId}-${row.crud_type}`,
      source: row.id,
      target: dataEntityId,
      label: row.crud_type,
    }));

    return { nodes, edges };
  }
}
