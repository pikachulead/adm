import OpenAI from 'openai';
import type { ILlmProvider } from '../interfaces.js';
import type {
  LlmMessage,
  LlmResponse,
  LlmToolCall,
  LlmContentBlock,
  ToolDefinition,
} from '../types.js';

export class OpenAiCompatibleProvider implements ILlmProvider {
  private readonly client: OpenAI;

  constructor(
    readonly providerName: string,
    readonly modelName: string,
    apiKey: string,
    baseUrl?: string,
  ) {
    this.client = new OpenAI({
      apiKey: apiKey || 'ollama',
      ...(baseUrl && { baseURL: baseUrl }),
    });
  }

  async chat(params: {
    systemPrompt: string;
    messages: LlmMessage[];
    tools?: ToolDefinition[];
    maxTokens?: number;
  }): Promise<LlmResponse> {
    const openaiMessages: OpenAI.ChatCompletionMessageParam[] = [
      { role: 'system', content: params.systemPrompt },
      ...params.messages.map((msg) => this.toOpenAiMessage(msg)),
    ];

    const openaiTools: OpenAI.ChatCompletionTool[] | undefined =
      params.tools?.map((tool) => ({
        type: 'function' as const,
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.inputSchema,
        },
      }));

    const response = await this.client.chat.completions.create({
      model: this.modelName,
      max_tokens: params.maxTokens ?? 4096,
      messages: openaiMessages,
      ...(openaiTools?.length && { tools: openaiTools }),
    });

    return this.fromOpenAiResponse(response);
  }

  private toOpenAiMessage(
    msg: LlmMessage
  ): OpenAI.ChatCompletionMessageParam {
    if (typeof msg.content === 'string') {
      if (msg.role === 'tool_result') {
        return { role: 'user', content: msg.content };
      }
      return { role: msg.role as 'user' | 'assistant', content: msg.content };
    }

    const blocks = msg.content as LlmContentBlock[];

    if (msg.role === 'assistant') {
      const textParts = blocks.filter((b) => b.type === 'text');
      const toolUseParts = blocks.filter((b) => b.type === 'tool_use');

      const toolCalls: OpenAI.ChatCompletionMessageToolCall[] = toolUseParts.map((b) => {
        if (b.type !== 'tool_use') throw new Error('Expected tool_use block');
        return {
          id: b.id,
          type: 'function' as const,
          function: {
            name: b.name,
            arguments: JSON.stringify(b.input),
          },
        };
      });

      return {
        role: 'assistant',
        content: textParts.length > 0 && textParts[0].type === 'text' ? textParts[0].text : null,
        ...(toolCalls.length > 0 && { tool_calls: toolCalls }),
      };
    }

    if (msg.role === 'tool_result') {
      const toolResults = blocks.filter((b) => b.type === 'tool_result');
      if (toolResults.length > 0 && toolResults[0].type === 'tool_result') {
        return {
          role: 'tool',
          tool_call_id: toolResults[0].tool_use_id,
          content: toolResults[0].content,
        };
      }
    }

    const textContent = blocks
      .filter((b) => b.type === 'text')
      .map((b) => (b.type === 'text' ? b.text : ''))
      .join('\n');

    return { role: 'user', content: textContent };
  }

  private fromOpenAiResponse(
    response: OpenAI.ChatCompletion
  ): LlmResponse {
    const choice = response.choices[0];
    if (!choice) {
      return { content: null, toolCalls: [], stopReason: 'end_turn' };
    }

    const toolCalls: LlmToolCall[] = (choice.message.tool_calls ?? []).map((tc) => ({
      id: tc.id,
      name: tc.function.name,
      input: JSON.parse(tc.function.arguments) as Record<string, unknown>,
    }));

    return {
      content: choice.message.content,
      toolCalls,
      stopReason: choice.finish_reason === 'tool_calls' ? 'tool_use' : 'end_turn',
    };
  }
}
