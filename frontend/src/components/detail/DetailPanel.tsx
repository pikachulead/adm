import type { Selection } from '@/types/index.js';
import { NODE_CONFIG } from '@/constants/node-config.js';
import { getEdgeColor } from '@/constants/node-config.js';
import { en } from '@/i18n/index.js';

interface DetailPanelProps {
  selection: Selection;
}

export function DetailPanel({ selection }: DetailPanelProps) {
  if (!selection) {
    return (
      <div className="h-full flex items-center justify-center p-4">
        <p className="text-sm text-gray-400 text-center">{en.detail.empty}</p>
      </div>
    );
  }

  if (selection.kind === 'node') {
    return <NodeDetail selection={selection} />;
  }

  return <EdgeDetail selection={selection} />;
}

function NodeDetail({ selection }: { selection: Extract<Selection, { kind: 'node' }> }) {
  const { data } = selection;
  const config = NODE_CONFIG[data.type];

  return (
    <div className="p-4 space-y-4">
      <div className="flex items-center gap-2">
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold ${config.bg} ${config.text}`}>
          {config.icon} {config.label}
        </span>
      </div>

      <div>
        <h3 className="text-base font-semibold text-gray-900">{data.label}</h3>
      </div>

      <div className="space-y-3">
        <DetailRow label={en.detail.type} value={config.label} />
        <DetailRow label={en.detail.name} value={data.label} />
        <DetailRow label="ID" value={data.id} mono />

        {data.metadata && Object.entries(data.metadata).map(([key, value]) => {
          if (value === null || value === undefined) return null;
          return (
            <DetailRow
              key={key}
              label={formatKey(key)}
              value={value}
            />
          );
        })}
      </div>
    </div>
  );
}

function EdgeDetail({ selection }: { selection: Extract<Selection, { kind: 'edge' }> }) {
  const { data } = selection;
  const color = getEdgeColor(data.label);

  return (
    <div className="p-4 space-y-4">
      <div className="flex items-center gap-2">
        <span
          className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold border"
          style={{ color, borderColor: color }}
        >
          {data.label}
        </span>
      </div>

      <div>
        <h3 className="text-base font-semibold text-gray-900">{en.detail.edgeTitle}</h3>
      </div>

      <div className="space-y-3">
        <DetailRow label={en.detail.relationship} value={data.label} />
        <DetailRow label={en.detail.source} value={data.source} />
        <DetailRow label={en.detail.target} value={data.target} />
        <DetailRow label="ID" value={data.id} mono />
      </div>
    </div>
  );
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <dt className="text-xs font-medium text-gray-500 uppercase tracking-wide">{label}</dt>
      <dd className={`mt-0.5 text-sm text-gray-800 ${mono ? 'font-mono text-xs break-all' : ''}`}>
        {value}
      </dd>
    </div>
  );
}

function formatKey(key: string): string {
  return key
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}
