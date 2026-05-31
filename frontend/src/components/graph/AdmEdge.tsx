import {
  BaseEdge,
  EdgeLabelRenderer,
  getSmoothStepPath,
} from '@xyflow/react';
import type { EdgeProps } from '@xyflow/react';
import { getEdgeColor } from '@/constants/node-config.js';

export function AdmEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  selected,
}: EdgeProps) {
  const label = (data?.label as string) ?? '';
  const color = getEdgeColor(label);

  const [edgePath, labelX, labelY] = getSmoothStepPath({
    sourceX,
    sourceY,
    targetX,
    targetY,
    sourcePosition,
    targetPosition,
    borderRadius: 8,
  });

  return (
    <>
      <BaseEdge
        id={id}
        path={edgePath}
        style={{
          stroke: color,
          strokeWidth: selected ? 2.5 : 1.5,
          opacity: selected ? 1 : 0.7,
        }}
      />
      <EdgeLabelRenderer>
        <div
          className={`
            absolute pointer-events-auto cursor-pointer
            px-1.5 py-0.5 rounded text-[10px] font-medium
            border whitespace-nowrap
            transition-opacity duration-150
            ${selected ? 'opacity-100' : 'opacity-80'}
          `}
          style={{
            transform: `translate(-50%, -50%) translate(${labelX}px, ${labelY}px)`,
            backgroundColor: 'white',
            color,
            borderColor: color,
          }}
        >
          {label}
        </div>
      </EdgeLabelRenderer>
    </>
  );
}
