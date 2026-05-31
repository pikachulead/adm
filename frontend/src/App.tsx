import { useCallback } from 'react';
import { useArchitectureSearch } from '@/hooks/useArchitectureSearch.js';
import { ChatPanel } from '@/components/chat/ChatPanel.js';
import { GraphCanvas } from '@/components/graph/GraphCanvas.js';
import { DetailPanel } from '@/components/detail/DetailPanel.js';
import { ErrorToast } from '@/components/ErrorToast.js';
import { en } from '@/i18n/index.js';
import { NODE_CONFIG } from '@/constants/node-config.js';
import type { EntityType } from '@/types/index.js';

const LEGEND_TYPES: EntityType[] = [
  'domain', 'capability', 'process', 'system', 'technology', 'data_entity',
];

export function App() {
  const {
    messages,
    graph,
    loading,
    error,
    selection,
    setSelection,
    sendQuery,
  } = useArchitectureSearch();

  const clearError = useCallback(() => {}, []);
  const hasDetailPanel = selection !== null;

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      <ErrorToast message={error} onDismiss={clearError} />

      <header className="flex items-center justify-between px-4 py-2 bg-white border-b border-gray-200 shrink-0">
        <div className="flex items-center gap-3">
          <h1 className="text-lg font-bold text-gray-900">{en.app.title}</h1>
          <span className="text-xs text-gray-400">{en.app.subtitle}</span>
        </div>
        <div className="flex items-center gap-3">
          {LEGEND_TYPES.map((type) => {
            const config = NODE_CONFIG[type];
            return (
              <div key={type} className="flex items-center gap-1">
                <span className={`inline-block w-2.5 h-2.5 rounded-sm ${config.bg}`} />
                <span className="text-[10px] text-gray-500">{config.label}</span>
              </div>
            );
          })}
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden">
        <div className="w-[360px] shrink-0 border-r border-gray-200 bg-white">
          <ChatPanel
            messages={messages}
            loading={loading}
            onSend={sendQuery}
          />
        </div>

        <div className="flex-1 relative">
          {loading && graph.nodes.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full gap-3">
              <div className="w-8 h-8 border-3 border-blue-200 border-t-blue-600 rounded-full animate-spin" />
              <p className="text-sm text-gray-400">{en.search.loading}</p>
            </div>
          ) : graph.nodes.length === 0 ? (
            <div className="flex items-center justify-center h-full">
              <p className="text-sm text-gray-400">{en.graph.empty}</p>
            </div>
          ) : (
            <GraphCanvas
              graph={graph}
              onSelect={setSelection}
            />
          )}
        </div>

        {hasDetailPanel && (
          <div className="w-[300px] shrink-0 border-l border-gray-200 bg-white overflow-y-auto">
            <div className="flex items-center justify-between px-4 py-2 border-b border-gray-200">
              <h2 className="text-sm font-semibold text-gray-700">{en.detail.title}</h2>
              <button
                onClick={() => setSelection(null)}
                className="text-gray-400 hover:text-gray-600 text-lg leading-none"
              >
                &times;
              </button>
            </div>
            <DetailPanel selection={selection} />
          </div>
        )}
      </div>
    </div>
  );
}
