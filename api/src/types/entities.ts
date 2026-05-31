export type EntityType =
  | 'domain'
  | 'capability'
  | 'process'
  | 'system'
  | 'technology'
  | 'data_entity';

export type MetadataType =
  | 'MODEL'
  | 'ENTITY'
  | 'ATTRIBUTE'
  | 'RELATIONSHIP'
  | 'VALUE_SET'
  | 'QUERY_PATTERN'
  | 'GOVERNANCE_RULE';

export interface BusinessDomain {
  id: string;
  domain_name: string;
  domain_function: string | null;
  description: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface BusinessCapability {
  id: string;
  capability_name: string;
  capability_description: string | null;
  capability_level: number;
  parent_capability_id: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface BusinessProcess {
  id: string;
  process_name: string;
  process_description: string | null;
  process_level: number;
  parent_process_id: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface BusinessSystem {
  id: string;
  system_name: string;
  system_type: string | null;
  lifecycle_status: string | null;
  owner_team: string | null;
  description: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface TechnologyComponent {
  id: string;
  technology_name: string;
  technology_type: string | null;
  vendor_name: string | null;
  lifecycle_status: string | null;
  description: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface BusinessDataEntity {
  id: string;
  entity_name: string;
  entity_description: string | null;
  data_domain: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface AdmMetadata {
  id: string;
  metadata_key: string;
  metadata_type: MetadataType;
  subject_area: string;
  model_layer: string;
  entity_name: string | null;
  table_name: string | null;
  relationship_name: string | null;
  purpose: string;
  definition: string;
  usage_guidance: string;
  example_usage: string | null;
  sort_order: number | null;
}

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

export interface SearchResult {
  id: string;
  name: string;
  type: EntityType;
  description: string | null;
}

export interface ArchitecturePath {
  domain_name: string;
  domain_to_capability_relationship: string | null;
  capability_name: string;
  capability_to_process_relationship: string | null;
  process_name: string | null;
  process_to_system_relationship: string | null;
  system_name: string | null;
  system_to_technology_relationship: string | null;
  technology_name: string | null;
}

export interface ImpactPath {
  technology_name: string;
  system_name: string;
  system_type: string | null;
  owner_team: string | null;
  process_name: string | null;
  process_to_system_relationship: string | null;
  capability_name: string | null;
  capability_to_process_relationship: string | null;
  domain_name: string | null;
  domain_to_capability_relationship: string | null;
  data_entity_name: string | null;
  system_data_relationship: string | null;
}

export interface ExpandResult {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface SimilarityMatch {
  id: string;
  name: string;
  type: EntityType;
  description: string | null;
  similarity: number;
}

export interface PathFilters {
  domain_name?: string;
  capability_name?: string;
  system_name?: string;
  technology_name?: string;
}

export type BaseEntity =
  | BusinessDomain
  | BusinessCapability
  | BusinessProcess
  | BusinessSystem
  | TechnologyComponent
  | BusinessDataEntity;

export interface CreateEntityInput {
  name: string;
  description?: string;
  [key: string]: unknown;
}
