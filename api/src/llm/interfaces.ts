import type { LlmMessage, LlmResponse, ToolDefinition } from './types.js';

export interface ILlmProvider {
  chat(params: {
    systemPrompt: string;
    messages: LlmMessage[];
    tools?: ToolDefinition[];
    maxTokens?: number;
  }): Promise<LlmResponse>;

  readonly providerName: string;
  readonly modelName: string;
}
