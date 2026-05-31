import { describe, it, expect } from 'vitest';
import { pathsToGraph, impactPathsToGraph } from '../graph-transformer.js';
import type { ArchitecturePath, ImpactPath } from '../../types/entities.js';

describe('pathsToGraph', () => {
  it('converts architecture paths to nodes and edges', () => {
    const rows: ArchitecturePath[] = [
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Capture FNOL',
        capability_to_process_relationship: 'realized_by',
        process_name: 'Submit FNOL',
        process_to_system_relationship: 'supported_by',
        system_name: 'Claims Portal',
        system_to_technology_relationship: 'uses',
        technology_name: 'React',
      },
    ];

    const graph = pathsToGraph(rows);
    expect(graph.nodes).toHaveLength(5);
    expect(graph.edges).toHaveLength(4);

    expect(graph.nodes.map((n) => n.type)).toEqual(
      expect.arrayContaining(['domain', 'capability', 'process', 'system', 'technology'])
    );
  });

  it('deduplicates nodes across multiple rows', () => {
    const rows: ArchitecturePath[] = [
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Assess Claim',
        capability_to_process_relationship: 'realized_by',
        process_name: 'Review Loss',
        process_to_system_relationship: 'supported_by',
        system_name: 'Claims Core',
        system_to_technology_relationship: 'uses',
        technology_name: 'Java',
      },
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Assess Claim',
        capability_to_process_relationship: 'realized_by',
        process_name: 'Review Loss',
        process_to_system_relationship: 'supported_by',
        system_name: 'Claims Core',
        system_to_technology_relationship: 'uses',
        technology_name: 'Kafka',
      },
    ];

    const graph = pathsToGraph(rows);
    const domainNodes = graph.nodes.filter((n) => n.type === 'domain');
    expect(domainNodes).toHaveLength(1);

    const systemNodes = graph.nodes.filter((n) => n.type === 'system');
    expect(systemNodes).toHaveLength(1);

    const techNodes = graph.nodes.filter((n) => n.type === 'technology');
    expect(techNodes).toHaveLength(2);
  });

  it('deduplicates edges', () => {
    const rows: ArchitecturePath[] = [
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Assess Claim',
        capability_to_process_relationship: 'realized_by',
        process_name: 'Review Loss',
        process_to_system_relationship: 'supported_by',
        system_name: 'Claims Core',
        system_to_technology_relationship: 'uses',
        technology_name: 'Java',
      },
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Assess Claim',
        capability_to_process_relationship: 'realized_by',
        process_name: 'Review Loss',
        process_to_system_relationship: 'supported_by',
        system_name: 'Claims Core',
        system_to_technology_relationship: 'uses',
        technology_name: 'Kafka',
      },
    ];

    const graph = pathsToGraph(rows);
    const claimsToAssessEdges = graph.edges.filter(
      (e) => e.source === 'Claims' && e.target === 'Assess Claim'
    );
    expect(claimsToAssessEdges).toHaveLength(1);
  });

  it('handles rows with null process/system/technology', () => {
    const rows: ArchitecturePath[] = [
      {
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        capability_name: 'Manage Claims',
        capability_to_process_relationship: null,
        process_name: null,
        process_to_system_relationship: null,
        system_name: null,
        system_to_technology_relationship: null,
        technology_name: null,
      },
    ];

    const graph = pathsToGraph(rows);
    expect(graph.nodes).toHaveLength(2);
    expect(graph.edges).toHaveLength(1);
  });
});

describe('impactPathsToGraph', () => {
  it('converts impact paths to graph with reverse traversal', () => {
    const rows: ImpactPath[] = [
      {
        technology_name: 'Java',
        system_name: 'Claims Core',
        system_type: 'Core Claims',
        owner_team: 'Claims Tech',
        process_name: 'Review Loss',
        process_to_system_relationship: 'supported_by',
        capability_name: 'Assess Claim',
        capability_to_process_relationship: 'realized_by',
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        data_entity_name: 'Claim',
        system_data_relationship: 'own',
      },
    ];

    const graph = impactPathsToGraph(rows);
    expect(graph.nodes.length).toBeGreaterThanOrEqual(5);
    expect(graph.nodes.some((n) => n.type === 'data_entity')).toBe(true);
    expect(graph.edges.some((e) => e.label === 'own')).toBe(true);
  });

  it('deduplicates systems referenced by multiple paths', () => {
    const rows: ImpactPath[] = [
      {
        technology_name: 'Java',
        system_name: 'Claims Core',
        system_type: 'Core',
        owner_team: 'Claims',
        process_name: 'Process A',
        process_to_system_relationship: 'supported_by',
        capability_name: 'Cap A',
        capability_to_process_relationship: 'realized_by',
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        data_entity_name: null,
        system_data_relationship: null,
      },
      {
        technology_name: 'Java',
        system_name: 'Claims Core',
        system_type: 'Core',
        owner_team: 'Claims',
        process_name: 'Process B',
        process_to_system_relationship: 'supported_by',
        capability_name: 'Cap B',
        capability_to_process_relationship: 'realized_by',
        domain_name: 'Claims',
        domain_to_capability_relationship: 'owns',
        data_entity_name: null,
        system_data_relationship: null,
      },
    ];

    const graph = impactPathsToGraph(rows);
    const systemNodes = graph.nodes.filter((n) => n.label === 'Claims Core');
    expect(systemNodes).toHaveLength(1);
  });
});
