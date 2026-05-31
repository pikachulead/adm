import { Handle, Position } from '@xyflow/react';
import type { NodeProps, Node } from '@xyflow/react';
import { NODE_CONFIG } from '@/constants/node-config.js';
import type { EntityType } from '@/types/index.js';

export type AdmNodeData = {
  label: string;
  entityType: EntityType;
  metadata?: Record<string, string | null>;
};

type AdmNodeType = Node<AdmNodeData, 'adm'>;

export function AdmNode({ data, selected }: NodeProps<AdmNodeType>) {
  const config = NODE_CONFIG[data.entityType];

  return (
    <div
      className={`
        min-w-[200px] max-w-[240px] rounded-lg shadow-md border-2 overflow-hidden
        transition-shadow duration-150
        ${selected ? 'shadow-lg ring-2 ring-blue-400' : ''}
        ${config.border}
      `}
    >
      <div className={`px-3 py-1.5 flex items-center gap-1.5 ${config.bg} ${config.text}`}>
        <span className="text-xs">{config.icon}</span>
        <span className="text-xs font-semibold uppercase tracking-wide">{config.label}</span>
      </div>
      <div className="px-3 py-2 bg-white">
        <span className="text-sm font-medium text-gray-800 leading-tight block">
          {data.label}
        </span>
      </div>
      <Handle type="target" position={Position.Left} className="!bg-gray-400 !w-2 !h-2" />
      <Handle type="source" position={Position.Right} className="!bg-gray-400 !w-2 !h-2" />
    </div>
  );
}
