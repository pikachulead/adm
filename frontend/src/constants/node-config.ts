import type { EntityType } from '@/types/index.js';

export interface NodeTypeConfig {
  bg: string;
  border: string;
  text: string;
  icon: string;
  label: string;
  rank: number;
}

export const NODE_CONFIG: Record<EntityType, NodeTypeConfig> = {
  domain: {
    bg: 'bg-blue-600',
    border: 'border-blue-700',
    text: 'text-white',
    icon: '◆',
    label: 'Domain',
    rank: 0,
  },
  capability: {
    bg: 'bg-purple-600',
    border: 'border-purple-700',
    text: 'text-white',
    icon: '●',
    label: 'Capability',
    rank: 1,
  },
  process: {
    bg: 'bg-green-600',
    border: 'border-green-700',
    text: 'text-white',
    icon: '▶',
    label: 'Process',
    rank: 2,
  },
  system: {
    bg: 'bg-amber-600',
    border: 'border-amber-700',
    text: 'text-white',
    icon: '■',
    label: 'System',
    rank: 3,
  },
  technology: {
    bg: 'bg-red-600',
    border: 'border-red-700',
    text: 'text-white',
    icon: '⚙',
    label: 'Technology',
    rank: 4,
  },
  data_entity: {
    bg: 'bg-cyan-600',
    border: 'border-cyan-700',
    text: 'text-white',
    icon: '◇',
    label: 'Data Entity',
    rank: 5,
  },
};

export const EDGE_COLORS: Record<string, string> = {
  owns: '#2563eb',
  realized_by: '#7c3aed',
  supported_by: '#059669',
  uses: '#dc2626',
  parent_of: '#6b7280',
  create: '#0891b2',
  read: '#0891b2',
  update: '#0891b2',
  delete: '#0891b2',
  own: '#0891b2',
  consume: '#0891b2',
  produce: '#0891b2',
};

export function getEdgeColor(label: string): string {
  return EDGE_COLORS[label] ?? '#6b7280';
}
