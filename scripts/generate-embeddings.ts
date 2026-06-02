import pg from 'pg';
import OpenAI from 'openai';
import { createWriteStream } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, '../.env.local') });

// ── Config ────────────────────────────────────────────────────────────────────

const DATABASE_URL = process.env.DATABASE_URL;
const EMBEDDING_API_KEY = process.env.EMBEDDING_API_KEY;
const EMBEDDING_MODEL = process.env.EMBEDDING_MODEL ?? 'text-embedding-3-small';
const EMBEDDING_DIMENSIONS = 1536;
const BATCH_SIZE = 50;
const OUTPUT_FILE = resolve(__dirname, '../adm_metadata_embeddings.csv');
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';

if (!DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set in .env.local');
  process.exit(1);
}
if (!EMBEDDING_API_KEY) {
  console.error('ERROR: EMBEDDING_API_KEY is not set in .env.local');
  process.exit(1);
}

// ── OpenAI-compatible client via OpenRouter ───────────────────────────────────

const openai = new OpenAI({
  apiKey: EMBEDDING_API_KEY,
  baseURL: OPENROUTER_BASE_URL,
});

// ── DB client ─────────────────────────────────────────────────────────────────

const pool = new pg.Pool({ connectionString: DATABASE_URL });

// ── Fetch metadata records ────────────────────────────────────────────────────

interface MetadataRow {
  id: string;
  metadata_code: string;
  metadata_name: string;
  metadata_object_type: string;
  metadata_source_table_name: string;
  metadata_source_column_name: string | null;
  metadata_business_definition: string;
  metadata_model_purpose: string;
  metadata_usage_guidance: string;
  metadata_example_values: string | null;
}

async function fetchMetadata(): Promise<MetadataRow[]> {
  const result = await pool.query<MetadataRow>(`
    SELECT
      id,
      metadata_code,
      metadata_name,
      metadata_object_type,
      metadata_source_table_name,
      metadata_source_column_name,
      metadata_business_definition,
      metadata_model_purpose,
      metadata_usage_guidance,
      metadata_example_values
    FROM adm_metadata
    ORDER BY metadata_code
  `);
  return result.rows;
}

// ── Build content for embedding ───────────────────────────────────────────────

function buildContent(row: MetadataRow): string {
  const parts: string[] = [];
  parts.push(`Name: ${row.metadata_name}`);
  parts.push(`Type: ${row.metadata_object_type}`);
  parts.push(`Table: ${row.metadata_source_table_name}`);
  if (row.metadata_source_column_name) {
    parts.push(`Column: ${row.metadata_source_column_name}`);
  }
  parts.push(`Definition: ${row.metadata_business_definition}`);
  parts.push(`Purpose: ${row.metadata_model_purpose}`);
  parts.push(`Usage: ${row.metadata_usage_guidance}`);
  if (row.metadata_example_values) {
    parts.push(`Examples: ${row.metadata_example_values}`);
  }
  return parts.join('\n');
}

// ── Generate embeddings in batches ────────────────────────────────────────────

async function generateEmbeddings(texts: string[]): Promise<number[][]> {
  const response = await openai.embeddings.create({
    model: EMBEDDING_MODEL,
    input: texts,
    dimensions: EMBEDDING_DIMENSIONS,
  });
  return response.data
    .sort((a, b) => a.index - b.index)
    .map((item) => item.embedding);
}

// ── CSV helpers ───────────────────────────────────────────────────────────────

function csvEscape(value: string | null): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n') || str.includes('\r')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function vectorToPgFormat(embedding: number[]): string {
  return `"[${embedding.join(',')}]"`;
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log('ADM Metadata Embeddings Generator');
  console.log(`  Model:      ${EMBEDDING_MODEL}`);
  console.log(`  Provider:   OpenRouter`);
  console.log(`  Dimensions: ${EMBEDDING_DIMENSIONS}`);
  console.log(`  Output:     ${OUTPUT_FILE}`);
  console.log('');

  // Fetch records
  console.log('Fetching metadata records from database...');
  const rows = await fetchMetadata();
  console.log(`  Found ${rows.length} records`);
  console.log('');

  if (rows.length === 0) {
    console.error('ERROR: No records found in adm_metadata. Run the SQL load step first.');
    process.exit(1);
  }

  // Open CSV file
  const writer = createWriteStream(OUTPUT_FILE, { encoding: 'utf8' });

  // CSV header matching adm_metadata_embeddings columns (excluding id — DB generates it)
  writer.write([
    'metadata_id',
    'metadata_code',
    'metadata_object_type',
    'metadata_name',
    'metadata_source_table_name',
    'metadata_source_column_name',
    'content',
    'embedding_model',
    'embedding_dimensions',
    'embedding',
  ].join(',') + '\n');

  // Process in batches
  let processed = 0;
  const total = rows.length;

  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const contents = batch.map(buildContent);

    process.stdout.write(`  Generating embeddings ${processed + 1}–${Math.min(processed + batch.length, total)} of ${total}...`);

    const embeddings = await generateEmbeddings(contents);

    for (let j = 0; j < batch.length; j++) {
      const row = batch[j];
      const content = contents[j];
      const embedding = embeddings[j];

      const csvRow = [
        csvEscape(row.id),
        csvEscape(row.metadata_code),
        csvEscape(row.metadata_object_type),
        csvEscape(row.metadata_name),
        csvEscape(row.metadata_source_table_name),
        csvEscape(row.metadata_source_column_name),
        csvEscape(content),
        csvEscape(EMBEDDING_MODEL),
        String(EMBEDDING_DIMENSIONS),
        vectorToPgFormat(embedding),
      ].join(',');

      writer.write(csvRow + '\n');
    }

    processed += batch.length;
    console.log(` done.`);
  }

  writer.end();
  await new Promise<void>((resolve) => writer.on('finish', resolve));

  console.log('');
  console.log(`✓ Generated ${total} embedding records`);
  console.log(`✓ CSV written to: ${OUTPUT_FILE}`);
  console.log('');
  console.log('Next step: run the import step in the shell script to load the CSV into PostgreSQL.');

  await pool.end();
}

main().catch((err) => {
  console.error('ERROR:', err.message);
  process.exit(1);
});
