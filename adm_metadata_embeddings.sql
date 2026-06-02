CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS adm_metadata_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID NOT NULL REFERENCES adm_metadata(id) ON DELETE CASCADE,
    metadata_code VARCHAR(160) NOT NULL,
    metadata_object_type VARCHAR(20) NOT NULL,
    metadata_name VARCHAR(200) NOT NULL,
    metadata_source_table_name VARCHAR(150) NOT NULL,
    metadata_source_column_name VARCHAR(150) NULL,
    content TEXT NOT NULL,
    embedding_model VARCHAR(120) NOT NULL,
    embedding_dimensions INTEGER NOT NULL,
    embedding vector(1536) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uq_adm_metadata_embeddings_metadata_id UNIQUE (metadata_id),
    CONSTRAINT uq_adm_metadata_embeddings_metadata_code UNIQUE (metadata_code)
);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_embeddings_object_type
    ON adm_metadata_embeddings(metadata_object_type);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_embeddings_source_table
    ON adm_metadata_embeddings(metadata_source_table_name);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_embeddings_vector
    ON adm_metadata_embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);