import type { ILlmProvider } from '../llm/interfaces.js';
import type { LlmMessage, LlmContentBlock } from '../llm/types.js';
import type { IArchitectureRepository } from '../repositories/interfaces.js';
import type { GraphData, GraphNode, GraphEdge, SearchResponse } from '../types/entities.js';
import { AGENT_TOOLS } from './tools.js';
import { executeTool } from './tool-executor.js';
import { buildSystemPrompt } from './system-prompt.js';

const MAX_TOOL_CALLS = 10;
const MAX_GRAPH_NODES = 200;

export class AgentService {
  constructor(
    private readonly llm: ILlmProvider,
    private readonly repository: IArchitectureRepository,
  ) {}

  async run(userMessage: string): Promise<SearchResponse> {
    const systemPrompt = await buildSystemPrompt(this.repository);
    const messages: LlmMessage[] = [{ role: 'user', content: userMessage }];
    const allNodes = new Map<string, GraphNode>();
    const allEdges = new Map<string, GraphEdge>();
    let toolCallCount = 0;

    while (toolCallCount < MAX_TOOL_CALLS) {
      const response = await this.llm.chat({
        systemPrompt,
        messages,
        tools: AGENT_TOOLS,
        maxTokens: 4096,
      });

      if (response.stopReason === 'end_turn' || response.toolCalls.length === 0) {
        return {
          answer: response.content ?? '',
          graph: capGraph(allNodes, allEdges),
        };
      }

      const assistantContent: LlmContentBlock[] = [];
      if (response.content) {
        assistantContent.push({ type: 'text', text: response.content });
      }
      for (const tc of response.toolCalls) {
        assistantContent.push({
          type: 'tool_use',
          id: tc.id,
          name: tc.name,
          input: tc.input,
        });
      }
      messages.push({ role: 'assistant', content: assistantContent });

      const toolResultBlocks: LlmContentBlock[] = [];
      for (const tc of response.toolCalls) {
        toolCallCount++;
        const result = await executeTool(tc.name, tc.input, this.repository);

        if (result.graph) {
          mergeGraph(allNodes, allEdges, result.graph);
        }

        toolResultBlocks.push({
          type: 'tool_result',
          tool_use_id: tc.id,
          content: JSON.stringify(result.data),
        });
      }
      messages.push({ role: 'tool_result', content: toolResultBlocks });
    }

    const finalResponse = await this.llm.chat({
      systemPrompt,
      messages: [
        ...messages,
        {
          role: 'user',
          content: 'Please provide your final answer based on the information gathered so far.',
        },
      ],
      maxTokens: 4096,
    });

    return {
      answer: finalResponse.content ?? '',
      graph: capGraph(allNodes, allEdges),
    };
  }
}

function mergeGraph(
  nodeMap: Map<string, GraphNode>,
  edgeMap: Map<string, GraphEdge>,
  graph: GraphData,
): void {
  for (const node of graph.nodes) {
    if (!nodeMap.has(node.id)) {
      nodeMap.set(node.id, node);
    }
  }
  for (const edge of graph.edges) {
    if (!edgeMap.has(edge.id)) {
      edgeMap.set(edge.id, edge);
    }
  }
}

function capGraph(
  nodeMap: Map<string, GraphNode>,
  edgeMap: Map<string, GraphEdge>,
): GraphData {
  const nodes = [...nodeMap.values()];
  const edges = [...edgeMap.values()];

  if (nodes.length <= MAX_GRAPH_NODES) {
    return { nodes, edges };
  }

  const cappedNodes = nodes.slice(0, MAX_GRAPH_NODES);
  const cappedNodeIds = new Set(cappedNodes.map((n) => n.id));
  const cappedEdges = edges.filter(
    (e) => cappedNodeIds.has(e.source) && cappedNodeIds.has(e.target),
  );

  return { nodes: cappedNodes, edges: cappedEdges };
}

export function createAgentService(
  llm: ILlmProvider,
  repository: IArchitectureRepository,
): AgentService {
  return new AgentService(llm, repository);
}
