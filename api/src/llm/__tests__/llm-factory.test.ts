import { describe, it, expect } from 'vitest';
import { createLlmProvider } from '../index.js';
import { AnthropicProvider } from '../anthropic/anthropic-provider.js';
import { OpenAiCompatibleProvider } from '../openai-compatible/openai-compatible-provider.js';

describe('LLM factory', () => {
  it('creates AnthropicProvider for anthropic provider', () => {
    const provider = createLlmProvider({
      provider: 'anthropic',
      model: 'claude-sonnet-4-6',
      apiKey: 'test-key',
    });
    expect(provider).toBeInstanceOf(AnthropicProvider);
    expect(provider.providerName).toBe('anthropic');
    expect(provider.modelName).toBe('claude-sonnet-4-6');
  });

  it('creates OpenAiCompatibleProvider for groq', () => {
    const provider = createLlmProvider({
      provider: 'groq',
      model: 'llama-3.3-70b-versatile',
      apiKey: 'test-key',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('groq');
    expect(provider.modelName).toBe('llama-3.3-70b-versatile');
  });

  it('creates OpenAiCompatibleProvider for openrouter', () => {
    const provider = createLlmProvider({
      provider: 'openrouter',
      model: 'anthropic/claude-sonnet-4',
      apiKey: 'test-key',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('openrouter');
  });

  it('creates OpenAiCompatibleProvider for openai', () => {
    const provider = createLlmProvider({
      provider: 'openai',
      model: 'gpt-4o',
      apiKey: 'test-key',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('openai');
  });

  it('creates OpenAiCompatibleProvider for together', () => {
    const provider = createLlmProvider({
      provider: 'together',
      model: 'meta-llama/Llama-3-70b',
      apiKey: 'test-key',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('together');
  });

  it('creates OpenAiCompatibleProvider for ollama without api key', () => {
    const provider = createLlmProvider({
      provider: 'ollama',
      model: 'llama3',
      apiKey: '',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('ollama');
  });

  it('supports custom base URL for unknown providers', () => {
    const provider = createLlmProvider({
      provider: 'custom-provider',
      model: 'custom-model',
      apiKey: 'test-key',
      baseUrl: 'https://my-llm.example.com/v1',
    });
    expect(provider).toBeInstanceOf(OpenAiCompatibleProvider);
    expect(provider.providerName).toBe('custom-provider');
  });

  it('throws when api key is missing for non-ollama provider', () => {
    expect(() =>
      createLlmProvider({
        provider: 'groq',
        model: 'test',
        apiKey: '',
      })
    ).toThrow('LLM_API_KEY');
  });
});
