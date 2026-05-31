import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildSystemPrompt, clearPromptCache } from '../system-prompt.js';
import { PgArchitectureRepository } from '../../repositories/postgresql/pg-repository.js';
import { getPool, closePool } from '../../repositories/postgresql/pg-pool.js';

let repo: PgArchitectureRepository;

beforeAll(() => {
  repo = new PgArchitectureRepository(getPool());
});

beforeEach(() => {
  clearPromptCache();
});

afterAll(async () => {
  await closePool();
});

describe('system prompt builder', () => {
  it('builds a prompt containing entity definitions', async () => {
    const prompt = await buildSystemPrompt(repo);
    expect(prompt).toContain('Business Domain');
    expect(prompt).toContain('Business Capability');
    expect(prompt).toContain('Business Process');
    expect(prompt).toContain('Business System');
    expect(prompt).toContain('Technology Component');
    expect(prompt).toContain('Business Data Entity');
  });

  it('contains relationship definitions', async () => {
    const prompt = await buildSystemPrompt(repo);
    expect(prompt).toContain('owns');
    expect(prompt).toContain('realized_by');
    expect(prompt).toContain('supported_by');
    expect(prompt).toContain('uses');
  });

  it('contains the key relationship chain', async () => {
    const prompt = await buildSystemPrompt(repo);
    expect(prompt).toContain('BusinessDomain --[owns]--> BusinessCapability');
    expect(prompt).toContain('BusinessCapability --[realized_by]--> BusinessProcess');
  });

  it('mentions the 4 business domains', async () => {
    const prompt = await buildSystemPrompt(repo);
    expect(prompt).toContain('Claims');
    expect(prompt).toContain('Underwriting');
    expect(prompt).toContain('Policy Administration');
    expect(prompt).toContain('Billing and Payments');
  });

  it('instructs the agent to ground answers in data', async () => {
    const prompt = await buildSystemPrompt(repo);
    expect(prompt).toContain('strictly grounded in the data model');
  });

  it('caches the prompt on second call', async () => {
    const prompt1 = await buildSystemPrompt(repo);
    const prompt2 = await buildSystemPrompt(repo);
    expect(prompt1).toBe(prompt2);
  });
});
