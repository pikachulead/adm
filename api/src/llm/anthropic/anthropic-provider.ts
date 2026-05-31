import Anthropic from '@anthropic-ai/sdk';
import type { ILlmProvider } from '../interfaces.js';
import type {
  LlmMessage,
  LlmResponse,
  LlmToolCall,
  LlmContentBlock,
  ToolDefinition,
} from '../types.js';

export class AnthropicProvider implements ILlmProvider {
  private readonly client: Anthropic;
  readonly providerName = 'anthropic';

  constructor(
    readonly modelName: string,
    apiKey: string,
  ) {
    this.client = new Anthropic({ apiKey });
  }

  async chat(params: {
    systemPrompt: string;
    messages: LlmMessage[];
    tools?: ToolDefinition[];
    maxTokens?: number;
  }): Promise<LlmResponse> {
    const anthropicMessages = params.messages.map((msg) =>
      this.toAnthropicMessage(msg)
    );

    const anthropicTools = params.tools?.map((tool) => ({
      name: tool.name,
      description: tool.description,
      input_schema: tool.inputSchema as Anthropic.Tool['input_schema'],
    }));

    const response = await this.client.messages.create({
      model: this.modelName,
      max_tokens: params.maxTokens ?? 4096,
      system: params.systemPrompt,
      messages: anthropicMessages,
      ...(anthropicTools?.length && { tools: anthropicTools }),
    });

    return this.fromAnthropicResponse(response);
  }

  private toAnthropicMessage(
    msg: LlmMessage
  ): Anthropic.MessageParam {
    if (typeof msg.content === 'string') {
      return { role: msg.role === 'tool_result' ? 'user' : msg.role, content: msg.content };
    }

    const blocks = msg.content as LlmContentBlock[];
    const anthropicContent: Anthropic.ContentBlockParam[] = blocks.map((block) => {
      switch (block.type) {
        case 'text':
          return { type: 'text' as const, text: block.text };
        case 'tool_use':
          return {
            type: 'tool_use' as const,
            id: block.id,
            name: block.name,
            input: block.input,
          };
        case 'tool_result':
          return {
            type: 'tool_result' as const,
            tool_use_id: block.tool_use_id,
            content: block.content,
          };
      }
    });

    return {
      role: msg.role === 'tool_result' ? 'user' : msg.role,
      content: anthropicContent,
    };
  }

  private fromAnthropicResponse(
    response: Anthropic.Message
  ): LlmResponse {
    let content: string | null = null;
    const toolCalls: LlmToolCall[] = [];

    for (const block of response.content) {
      if (block.type === 'text') {
        content = block.text;
      } else if (block.type === 'tool_use') {
        toolCalls.push({
          id: block.id,
          name: block.name,
          input: block.input as Record<string, unknown>,
        });
      }
    }

    return {
      content,
      toolCalls,
      stopReason: response.stop_reason === 'tool_use' ? 'tool_use' : 'end_turn',
    };
  }
}
