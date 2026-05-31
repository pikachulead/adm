import type { ILlmProvider } from './interfaces.js';
import type { LlmConfig } from './types.js';
import { AnthropicProvider } from './anthropic/anthropic-provider.js';
import { OpenAiCompatibleProvider } from './openai-compatible/openai-compatible-provider.js';

const KNOWN_PROVIDERS: Record<string, { baseUrl?: string }> = {
  anthropic: {},
  openai: { baseUrl: 'https://api.openai.com/v1' },
  groq: { baseUrl: 'https://api.groq.com/openai/v1' },
  openrouter: { baseUrl: 'https://openrouter.ai/api/v1' },
  together: { baseUrl: 'https://api.together.xyz/v1' },
  ollama: { baseUrl: 'http://localhost:11434/v1' },
};

export function createLlmProvider(config?: LlmConfig): ILlmProvider {
  const provider = config?.provider ?? process.env.LLM_PROVIDER ?? 'anthropic';
  const model = config?.model ?? process.env.LLM_MODEL ?? 'claude-sonnet-4-6';
  const apiKey = config?.apiKey ?? process.env.LLM_API_KEY ?? process.env.ANTHROPIC_API_KEY ?? '';
  const baseUrl = config?.baseUrl ?? process.env.LLM_BASE_URL ?? KNOWN_PROVIDERS[provider]?.baseUrl;

  if (!apiKey && provider !== 'ollama') {
    throw new Error(`LLM_API_KEY or ANTHROPIC_API_KEY environment variable is required for provider: ${provider}`);
  }

  if (provider === 'anthropic') {
    return new AnthropicProvider(model, apiKey);
  }

  return new OpenAiCompatibleProvider(
    provider,
    model,
    apiKey,
    baseUrl,
  );
}

export type { ILlmProvider } from './interfaces.js';
export type { LlmConfig, LlmMessage, LlmResponse, LlmToolCall, ToolDefinition } from './types.js';
