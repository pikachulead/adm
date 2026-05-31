import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { AgentService } from '../agent-service.js';
import { PgArchitectureRepository } from '../../repositories/postgresql/pg-repository.js';
import { getPool, closePool } from '../../repositories/postgresql/pg-pool.js';
import type { ILlmProvider } from '../../llm/interfaces.js';
import type { LlmMessage, LlmResponse, ToolDefinition } from '../../llm/types.js';
import { clearPromptCache } from '../system-prompt.js';

let repo: PgArchitectureRepository;

beforeAll(() => {
  repo = new PgArchitectureRepository(getPool());
  clearPromptCache();
});

afterAll(async () => {
  await closePool();
});

function createMockLlm(responses: LlmResponse[]): ILlmProvider {
  let callIndex = 0;
  return {
    providerName: 'mock',
    modelName: 'mock-model',
    chat: async (_params: {
      systemPrompt: string;
      messages: LlmMessage[];
      tools?: ToolDefinition[];
      maxTokens?: number;
    }): Promise<LlmResponse> => {
      const response = responses[callIndex];
      if (!response) throw new Error(`Mock LLM called more times than expected: ${callIndex + 1}`);
      callIndex++;
      return response;
    },
  };
}

describe('AgentService', () => {
  it('returns direct answer when LLM does not call tools', async () => {
    const mockLlm = createMockLlm([
      {
        content: 'FNOL stands for First Notice of Loss.',
        toolCalls: [],
        stopReason: 'end_turn',
      },
    ]);

    const agent = new AgentService(mockLlm, repo);
    const result = await agent.run('What is FNOL?');

    expect(result.answer).toContain('First Notice of Loss');
    expect(result.graph.nodes).toHaveLength(0);
  });

  it('executes tool calls and accumulates graph data', async () => {
    const mockLlm = createMockLlm([
      {
        content: null,
        toolCalls: [
          {
            id: 'tool-1',
            name: 'get_full_path',
            input: { domain_name: 'Claims', capability_name: 'First Notice' },
          },
        ],
        stopReason: 'tool_use',
      },
      {
        content: 'FNOL (First Notice of Loss) exists in the Claims domain.',
        toolCalls: [],
        stopReason: 'end_turn',
      },
    ]);

    const agent = new AgentService(mockLlm, repo);
    const result = await agent.run('Where does FNOL exist?');

    expect(result.answer).toContain('Claims');
    expect(result.graph.nodes.length).toBeGreaterThan(0);
    expect(result.graph.edges.length).toBeGreaterThan(0);
  });

  it('handles multiple sequential tool calls', async () => {
    const mockLlm = createMockLlm([
      {
        content: null,
        toolCalls: [
          { id: 'tool-1', name: 'search_architecture', input: { keyword: 'Java' } },
        ],
        stopReason: 'tool_use',
      },
      {
        content: null,
        toolCalls: [
          { id: 'tool-2', name: 'get_reverse_impact', input: { technology_name: 'Java' } },
        ],
        stopReason: 'tool_use',
      },
      {
        content: 'Java impacts Claims, Underwriting, Policy Administration, and Billing.',
        toolCalls: [],
        stopReason: 'end_turn',
      },
    ]);

    const agent = new AgentService(mockLlm, repo);
    const result = await agent.run('What is impacted if we deprecate Java?');

    expect(result.answer).toContain('Java');
    expect(result.graph.nodes.length).toBeGreaterThan(0);
  });

  it('enforces circuit breaker after max tool calls', async () => {
    let callCount = 0;
    const mockLlm: ILlmProvider = {
      providerName: 'mock',
      modelName: 'mock-model',
      chat: async () => {
        callCount++;
        if (callCount <= 10) {
          return {
            content: null,
            toolCalls: [
              { id: `tool-${callCount}`, name: 'list_entities', input: { entity_type: 'domain' } },
            ],
            stopReason: 'tool_use' as const,
          };
        }
        return {
          content: 'Final answer after circuit breaker.',
          toolCalls: [],
          stopReason: 'end_turn' as const,
        };
      },
    };

    const agent = new AgentService(mockLlm, repo);
    const result = await agent.run('List everything');

    expect(callCount).toBeGreaterThanOrEqual(10);
    expect(result.answer).toContain('Final answer');
  });

  it('receives system prompt containing model metadata', async () => {
    let capturedSystemPrompt = '';
    const mockLlm: ILlmProvider = {
      providerName: 'mock',
      modelName: 'mock-model',
      chat: async (params) => {
        capturedSystemPrompt = params.systemPrompt;
        return { content: 'Done.', toolCalls: [], stopReason: 'end_turn' };
      },
    };

    const agent = new AgentService(mockLlm, repo);
    await agent.run('test');

    expect(capturedSystemPrompt).toContain('Business Domain');
    expect(capturedSystemPrompt).toContain('Business Capability');
    expect(capturedSystemPrompt).toContain('strictly grounded');
  });

  it('receives tool definitions in chat call', async () => {
    let capturedTools: ToolDefinition[] = [];
    const mockLlm: ILlmProvider = {
      providerName: 'mock',
      modelName: 'mock-model',
      chat: async (params) => {
        capturedTools = params.tools ?? [];
        return { content: 'Done.', toolCalls: [], stopReason: 'end_turn' };
      },
    };

    const agent = new AgentService(mockLlm, repo);
    await agent.run('test');

    const toolNames = capturedTools.map((t) => t.name);
    expect(toolNames).toContain('search_architecture');
    expect(toolNames).toContain('get_full_path');
    expect(toolNames).toContain('get_reverse_impact');
    expect(toolNames).toContain('expand_node');
    expect(toolNames).toContain('list_entities');
    expect(toolNames).toContain('suggest_similar');
    expect(toolNames).toContain('create_entity');
  });
});
