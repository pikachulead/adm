import { describe, it, expect } from 'vitest';
import { applyDagreLayout } from '@/components/graph/layout.js';
import type { Node, Edge } from '@xyflow/react';

describe('applyDagreLayout', () => {
  it('positions nodes left to right based on hierarchy', () => {
    const nodes: Node[] = [
      { id: 'a', position: { x: 0, y: 0 }, data: { label: 'Domain', entityType: 'domain' } },
      { id: 'b', position: { x: 0, y: 0 }, data: { label: 'Capability', entityType: 'capability' } },
      { id: 'c', position: { x: 0, y: 0 }, data: { label: 'Process', entityType: 'process' } },
    ];
    const edges: Edge[] = [
      { id: 'e1', source: 'a', target: 'b' },
      { id: 'e2', source: 'b', target: 'c' },
    ];

    const positioned = applyDagreLayout(nodes, edges);
    const xPositions = positioned.map((n) => n.position.x);

    expect(xPositions[0]).toBeLessThan(xPositions[1]);
    expect(xPositions[1]).toBeLessThan(xPositions[2]);
  });

  it('handles a single node', () => {
    const nodes: Node[] = [
      { id: 'a', position: { x: 0, y: 0 }, data: { label: 'Domain', entityType: 'domain' } },
    ];

    const positioned = applyDagreLayout(nodes, []);
    expect(positioned).toHaveLength(1);
    expect(positioned[0].position.x).toBeGreaterThanOrEqual(0);
  });

  it('handles empty input', () => {
    const positioned = applyDagreLayout([], []);
    expect(positioned).toEqual([]);
  });
});
