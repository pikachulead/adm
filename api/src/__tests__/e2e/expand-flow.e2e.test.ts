import { describe, it, expect, afterAll } from 'vitest';
import { handler } from '../../handlers/expand.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';
import type { LambdaEvent } from '../../handlers/lambda-utils.js';

afterAll(async () => {
  await closePool();
});

function postEvent(body: unknown): LambdaEvent {
  return {
    body: JSON.stringify(body),
    headers: {},
    requestContext: { http: { method: 'POST', path: '/api/expand' } },
  };
}

describe('expand flow E2E', () => {
  it('expands Claims domain → 9 capability nodes with owns edges', async () => {
    const response = await handler(
      postEvent({ nodeType: 'domain', nodeId: '10000000-0000-0000-0000-000000000001' }),
    );

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);

    expect(body.nodes).toHaveLength(9);
    expect(body.edges).toHaveLength(9);
    expect(body.nodes.every((n: { type: string }) => n.type === 'capability')).toBe(true);
    expect(body.edges.every((e: { label: string }) => e.label === 'owns')).toBe(true);

    const names = body.nodes.map((n: { label: string }) => n.label).sort();
    expect(names).toContain('Capture First Notice of Loss');
    expect(names).toContain('Assess Claim');
    expect(names).toContain('Close Claim');
  });

  it('expands FNOL capability → processes including Submit FNOL and Create Claim Record', async () => {
    const response = await handler(
      postEvent({ nodeType: 'capability', nodeId: '20000000-0000-0000-0000-000000000002' }),
    );

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);

    expect(body.nodes.length).toBeGreaterThan(0);
    const processNames = body.nodes
      .filter((n: { type: string }) => n.type === 'process')
      .map((n: { label: string }) => n.label);
    expect(processNames).toContain('Submit First Notice of Loss');
    expect(processNames).toContain('Create Claim Record');
  });

  it('expands Claims Core Platform → technologies and data entities', async () => {
    const response = await handler(
      postEvent({ nodeType: 'system', nodeId: '60000000-0000-0000-0000-000000000001' }),
    );

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);

    const techNodes = body.nodes.filter((n: { type: string }) => n.type === 'technology');
    const dataNodes = body.nodes.filter((n: { type: string }) => n.type === 'data_entity');
    expect(techNodes.length).toBeGreaterThan(0);
    expect(dataNodes.length).toBeGreaterThan(0);

    const techNames = techNodes.map((n: { label: string }) => n.label);
    expect(techNames).toContain('Java');
    expect(techNames).toContain('PostgreSQL');
    expect(techNames).toContain('Kafka');
  });

  it('expands Java technology → reverse to systems using Java', async () => {
    const response = await handler(
      postEvent({ nodeType: 'technology', nodeId: 'a0000000-0000-0000-0000-000000000004' }),
    );

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);

    expect(body.nodes.length).toBeGreaterThan(0);
    expect(body.nodes.every((n: { type: string }) => n.type === 'system')).toBe(true);

    const systemNames = body.nodes.map((n: { label: string }) => n.label);
    expect(systemNames).toContain('Claims Core Platform');
  });

  it('returns empty for non-existent node', async () => {
    const response = await handler(
      postEvent({ nodeType: 'domain', nodeId: '00000000-0000-0000-0000-000000000000' }),
    );

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.nodes).toHaveLength(0);
    expect(body.edges).toHaveLength(0);
  });

  it('chains domain → capability → process → system → technology', async () => {
    const domainRes = await handler(
      postEvent({ nodeType: 'domain', nodeId: '10000000-0000-0000-0000-000000000001' }),
    );
    const domainBody = JSON.parse(domainRes.body);
    const fnolCap = domainBody.nodes.find(
      (n: { label: string }) => n.label === 'Capture First Notice of Loss',
    );
    expect(fnolCap).toBeDefined();

    const capRes = await handler(
      postEvent({ nodeType: 'capability', nodeId: fnolCap.id }),
    );
    const capBody = JSON.parse(capRes.body);
    const submitProcess = capBody.nodes.find(
      (n: { label: string }) => n.label === 'Submit First Notice of Loss',
    );
    expect(submitProcess).toBeDefined();

    const processRes = await handler(
      postEvent({ nodeType: 'process', nodeId: submitProcess.id }),
    );
    const processBody = JSON.parse(processRes.body);
    const portal = processBody.nodes.find(
      (n: { label: string }) => n.label === 'Customer Claims Portal',
    );
    expect(portal).toBeDefined();

    const systemRes = await handler(
      postEvent({ nodeType: 'system', nodeId: portal.id }),
    );
    const systemBody = JSON.parse(systemRes.body);
    const techNames = systemBody.nodes
      .filter((n: { type: string }) => n.type === 'technology')
      .map((n: { label: string }) => n.label);
    expect(techNames).toContain('React');
    expect(techNames).toContain('Next.js');
  });
});
