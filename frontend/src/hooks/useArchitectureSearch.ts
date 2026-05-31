import { useState, useCallback } from 'react';
import type { GraphData, ChatMessage, Selection } from '@/types/index.js';
import { searchArchitecture } from '@/api/client.js';

interface UseArchitectureSearchReturn {
  messages: ChatMessage[];
  graph: GraphData;
  loading: boolean;
  error: string | null;
  selection: Selection;
  setSelection: (selection: Selection) => void;
  sendQuery: (query: string) => Promise<void>;
  clearGraph: () => void;
}

const EMPTY_GRAPH: GraphData = { nodes: [], edges: [] };

export function useArchitectureSearch(): UseArchitectureSearchReturn {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [graph, setGraph] = useState<GraphData>(EMPTY_GRAPH);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selection, setSelection] = useState<Selection>(null);

  const sendQuery = useCallback(async (query: string) => {
    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content: query,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setLoading(true);
    setError(null);
    setSelection(null);

    try {
      const result = await searchArchitecture(query);

      const assistantMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: result.answer,
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, assistantMessage]);

      if (result.graph.nodes.length > 0) {
        setGraph(result.graph);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'An error occurred';
      setError(message);

      const errorMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: message,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  }, []);

  const clearGraph = useCallback(() => {
    setGraph(EMPTY_GRAPH);
    setSelection(null);
  }, []);

  return {
    messages,
    graph,
    loading,
    error,
    selection,
    setSelection,
    sendQuery,
    clearGraph,
  };
}
