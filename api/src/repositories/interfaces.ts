import type {
  ArchitecturePath,
  BaseEntity,
  CreateEntityInput,
  EntityType,
  ExpandResult,
  ImpactPath,
  MetadataType,
  PathFilters,
  SearchResult,
  SimilarityMatch,
  AdmMetadata,
} from '../types/entities.js';

export interface IArchitectureRepository {
  searchByKeyword(keyword: string): Promise<SearchResult[]>;
  getFullPath(filters?: PathFilters): Promise<ArchitecturePath[]>;
  getReversePath(technologyName: string): Promise<ImpactPath[]>;
  expandNode(nodeType: EntityType, nodeId: string): Promise<ExpandResult>;
  findSimilar(entityType: EntityType, name: string): Promise<SimilarityMatch[]>;
  listEntities(entityType: EntityType): Promise<BaseEntity[]>;
  createEntity(entityType: EntityType, data: CreateEntityInput): Promise<BaseEntity>;
  getMetadata(types?: MetadataType[]): Promise<AdmMetadata[]>;
  healthCheck(): Promise<boolean>;
}
