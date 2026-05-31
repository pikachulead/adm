
-- =========================================================
-- adm_metadata.sql
-- Single source of truth for ADM/APM architecture repository model definitions
-- =========================================================
-- Purpose:
--   Creates and populates adm_metadata so architects can understand the
--   meaning, purpose, correct usage, attributes, relationships, value sets,
--   query patterns, and governance rules of the model.
--
-- Safe to re-run:
--   Uses CREATE TABLE IF NOT EXISTS and UPSERT by metadata_key.
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS adm_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    metadata_key VARCHAR(250) NOT NULL UNIQUE,
    metadata_type VARCHAR(50) NOT NULL CHECK (
        metadata_type IN (
            'MODEL',
            'ENTITY',
            'ATTRIBUTE',
            'RELATIONSHIP',
            'VALUE_SET',
            'QUERY_PATTERN',
            'GOVERNANCE_RULE'
        )
    ),

    subject_area VARCHAR(100) NOT NULL,
    model_layer VARCHAR(100) NOT NULL,

    entity_name VARCHAR(150),
    table_name VARCHAR(150),

    attribute_name VARCHAR(150),
    column_name VARCHAR(150),
    data_type VARCHAR(100),
    is_required BOOLEAN,
    is_primary_key BOOLEAN NOT NULL DEFAULT FALSE,
    is_foreign_key BOOLEAN NOT NULL DEFAULT FALSE,
    referenced_entity_name VARCHAR(150),
    referenced_table_name VARCHAR(150),

    relationship_name VARCHAR(200),
    relationship_table_name VARCHAR(150),
    from_entity_name VARCHAR(150),
    from_table_name VARCHAR(150),
    from_column_name VARCHAR(150),
    to_entity_name VARCHAR(150),
    to_table_name VARCHAR(150),
    to_column_name VARCHAR(150),
    relationship_type VARCHAR(75),
    cardinality VARCHAR(75),

    allowed_values TEXT,

    purpose TEXT NOT NULL,
    definition TEXT NOT NULL,
    usage_guidance TEXT NOT NULL,
    example_usage TEXT,
    governance_notes TEXT,

    additional_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    sort_order INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_adm_metadata_relationship_consistency
    CHECK (
        metadata_type <> 'RELATIONSHIP'
        OR (
            from_entity_name IS NOT NULL
            AND to_entity_name IS NOT NULL
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_type
    ON adm_metadata(metadata_type);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_entity_name
    ON adm_metadata(entity_name);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_table_name
    ON adm_metadata(table_name);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_relationship_name
    ON adm_metadata(relationship_name);

CREATE INDEX IF NOT EXISTS idx_adm_metadata_subject_layer
    ON adm_metadata(subject_area, model_layer);

COMMENT ON TABLE adm_metadata IS
'Single source of truth for ADM/APM repository model definitions, including entities, attributes, relationships, value sets, query patterns, and governance rules.';

COMMENT ON COLUMN adm_metadata.metadata_key IS
'Stable natural key for each metadata definition. Used for idempotent upserts.';

COMMENT ON COLUMN adm_metadata.metadata_type IS
'Type of metadata row: MODEL, ENTITY, ATTRIBUTE, RELATIONSHIP, VALUE_SET, QUERY_PATTERN, or GOVERNANCE_RULE.';

COMMENT ON COLUMN adm_metadata.purpose IS
'Why this model object exists and what it is used for.';

COMMENT ON COLUMN adm_metadata.definition IS
'Precise business/architecture definition of the model object.';

COMMENT ON COLUMN adm_metadata.usage_guidance IS
'Instructions for correct usage by architects and implementers.';

COMMENT ON COLUMN adm_metadata.additional_metadata IS
'Extensible JSON field for future metadata without requiring immediate schema changes.';

BEGIN;

INSERT INTO adm_metadata (
    metadata_key,
    metadata_type,
    subject_area,
    model_layer,
    entity_name,
    table_name,
    attribute_name,
    column_name,
    data_type,
    is_required,
    is_primary_key,
    is_foreign_key,
    referenced_entity_name,
    referenced_table_name,
    relationship_name,
    relationship_table_name,
    from_entity_name,
    from_table_name,
    from_column_name,
    to_entity_name,
    to_table_name,
    to_column_name,
    relationship_type,
    cardinality,
    allowed_values,
    purpose,
    definition,
    usage_guidance,
    example_usage,
    governance_notes,
    sort_order
)
VALUES
(
    'model.adm_business_architecture_repository', 'MODEL', 'Architecture Repository', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Defines the overall purpose and usage boundary of the ADM architecture repository model.', 'The ADM model stores business architecture and application/technology/data architecture relationships so architects can understand how domains, capabilities, processes, systems, technologies, and data entities are connected.', 'Use this model as the system of record for architecture inventory, traceability, impact analysis, portfolio views, and graph-style visualization. Keep structural definitions here in adm_metadata and keep business instance data in the domain, capability, process, system, technology, data entity, and relationship tables.', 'Example path: Claims --owns--> Assess Claim --realized_by--> Review Loss Details --supported_by--> Claims Core Platform --uses--> Java.', 'This model is intentionally relational-first and can be projected into graph views or graph databases later if open-ended traversal becomes a core requirement.', 1
),
(
    'entity.business_domains', 'ENTITY', 'Business Architecture', 'Business Architecture', 'Business Domain', 'business_domains', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents a major business area or functional domain within the enterprise.', 'A Business Domain groups related business responsibilities, capabilities, processes, and systems. Examples include Claims, Underwriting, Policy Administration, and Billing and Payments.', 'Create one row per durable business domain. Do not use this table for temporary teams, projects, or individual departments unless they represent an enduring business domain.', 'Claims; Underwriting; Policy Administration; Billing and Payments.', NULL, 10
),
(
    'entity.business_capabilities', 'ENTITY', 'Business Architecture', 'Business Architecture', 'Business Capability', 'business_capabilities', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents what the business must be able to do, independent of process or technology implementation.', 'A Business Capability describes a stable business ability such as Assess Risk, Settle Claim, Issue Policy, or Collect Payment. Capabilities may be hierarchical through parent_capability_id.', 'Use capabilities to organize business architecture and connect business intent to processes and systems. Avoid naming capabilities as activities with step-by-step process language.', 'Assess Claim; Rate and Price Risk; Manage Renewals.', NULL, 11
),
(
    'entity.business_processes', 'ENTITY', 'Business Architecture', 'Business Architecture', 'Business Process', 'business_processes', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents how work is performed to realize a capability.', 'A Business Process is an activity or workflow step such as Validate Coverage, Issue Claim Payment, or Generate Invoice. Processes may be hierarchical through parent_process_id.', 'Use this table for operational work steps, workflows, and processes that implement capabilities. Do not use it for systems or technologies.', 'Submit First Notice of Loss; Create Policy; Collect Payment.', NULL, 12
),
(
    'entity.business_systems', 'ENTITY', 'Application Architecture', 'Application Architecture', 'Business System', 'business_systems', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents an application, platform, service, or system used by the business.', 'A Business System is a logical or physical application/service that supports processes and capabilities. Examples include Claims Core Platform, Underwriting Workbench, Billing Platform, and Policy Administration System.', 'Use one row per enterprise system. Reuse shared systems across domains rather than creating duplicates with the same name.', 'Policy Administration System is reused by Claims, Underwriting, Policy Administration, and Billing and Payments.', NULL, 13
),
(
    'entity.technology_components', 'ENTITY', 'Technology Architecture', 'Technology Architecture', 'Technology Component', 'technology_components', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents a technology, platform, framework, runtime, database, integration technology, or infrastructure component used by systems.', 'A Technology Component captures technical building blocks such as Java, PostgreSQL, Kafka, React, AWS Lambda, REST API Gateway, OAuth 2.0/OIDC, and Amazon S3.', 'Use this table to support technology portfolio views, lifecycle analysis, standards compliance, and technology impact analysis.', 'If Java is deprecated, join through system_technologies to identify impacted systems, processes, capabilities, and domains.', NULL, 14
),
(
    'entity.business_data_entities', 'ENTITY', 'Data Architecture', 'Data Architecture', 'Business Data Entity', 'business_data_entities', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Represents a meaningful business data object managed, used, created, or consumed by systems.', 'A Business Data Entity is a business concept such as Policy, Claim, Customer, Billing Account, Invoice, Payment, Quote, or Risk Profile.', 'Use this table to model data ownership, CRUD responsibility, lineage, and system-of-record relationships.', 'Policy is owned by Policy Administration System; Claim is owned by Claims Core Platform.', NULL, 15
),
(
    'entity.domain_capabilities', 'ENTITY', 'Relationship Model', 'Business Architecture', 'Domain Capability Relationship', 'domain_capabilities', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects business domains to the business capabilities they own or use.', 'This bridge table represents the relationship between Business Domain and Business Capability. It usually expresses that a domain owns a capability.', 'Use this table to define the capability map for each domain. Relationship rows should be unique by domain, capability, and relationship_type.', 'Claims owns Capture First Notice of Loss.', NULL, 16
),
(
    'entity.capability_processes', 'ENTITY', 'Relationship Model', 'Business Architecture', 'Capability Process Relationship', 'capability_processes', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects business capabilities to the processes that realize them.', 'This bridge table represents how capabilities are operationalized through business processes.', 'Use this table when a capability is realized by one or more processes, or when a process contributes to one or more capabilities.', 'Assess Risk is realized by Evaluate Applicant Risk and Check Loss History.', NULL, 17
),
(
    'entity.domain_systems', 'ENTITY', 'Relationship Model', 'Application Architecture', 'Domain System Relationship', 'domain_systems', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects business domains to systems they own or use.', 'This bridge table captures domain-to-system accountability or usage. A domain may own a system or may use a shared enterprise system owned elsewhere.', 'Use owns when the domain is accountable for the system and uses when the domain depends on the system but is not the primary owner.', 'Underwriting uses Policy Administration System.', NULL, 18
),
(
    'entity.process_systems', 'ENTITY', 'Relationship Model', 'Application Architecture', 'Process System Relationship', 'process_systems', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects business processes to systems that support them.', 'This bridge table identifies which systems enable, automate, record, or support a business process.', 'Use this relationship for process-level impact analysis. A process can be supported by multiple systems and a system can support many processes.', 'Issue Claim Payment is supported by Claims Payment Platform.', NULL, 19
),
(
    'entity.capability_systems', 'ENTITY', 'Relationship Model', 'Application Architecture', 'Capability System Relationship', 'capability_systems', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects business capabilities directly to systems that support them.', 'This bridge table provides a shortcut relationship for capability-to-system traceability and criticality assessment.', 'Use this table when architects want a direct capability-to-system view without always traversing through processes. Keep it aligned with process_systems where possible.', 'Settle Claim is supported by Claims Core Platform and Claims Payment Platform.', NULL, 20
),
(
    'entity.system_technologies', 'ENTITY', 'Relationship Model', 'Technology Architecture', 'System Technology Relationship', 'system_technologies', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects systems to technology components they use.', 'This bridge table identifies technology dependencies for each system.', 'Use this table for technology lifecycle impact analysis, standards compliance, and modernization planning.', 'Claims Core Platform uses Java, PostgreSQL, and Kafka.', NULL, 21
),
(
    'entity.system_data_entities', 'ENTITY', 'Relationship Model', 'Data Architecture', 'System Data Entity Relationship', 'system_data_entities', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Connects systems to data entities and describes CRUD/data responsibility.', 'This bridge table describes how a system owns, creates, reads, updates, deletes, consumes, or produces a business data entity.', 'Use crud_type to distinguish system-of-record responsibility from usage/lineage. Prefer own for system-of-record ownership.', 'Billing Platform owns Invoice; Customer Portal reads Policy; Claims Core Platform owns Claim.', NULL, 22
),
(
    'entity.adm_metadata', 'ENTITY', 'Metadata', 'Enterprise Architecture', 'ADM Metadata', 'adm_metadata', NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Documents the meaning, purpose, attributes, relationships, and usage guidance of the ADM model itself.', 'The adm_metadata table is the single source of truth for understanding the architecture repository model and should be reviewed by architects before using or extending the data model.', 'Add or update metadata rows whenever a table, column, relationship, value set, query pattern, or governance rule changes.', 'Architects can search adm_metadata for entity, attribute, relationship, and value set definitions.', NULL, 23
),
(
    'attribute.business_domains.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a business domain.', 'Stable surrogate key for a business domain record.', 'Use internally for joins. Architects should identify domains by domain_name.', NULL, NULL, 101
),
(
    'attribute.business_domains.domain_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'domain_name', 'domain_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the unique domain name.', 'Human-readable name of the business domain.', 'Must be unique. Use durable business domain names, not temporary organizational labels.', 'Claims', NULL, 102
),
(
    'attribute.business_domains.domain_function', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'domain_function', 'domain_function', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Summarizes the business function of the domain.', 'Short business-function description explaining what the domain is responsible for.', 'Use a concise verb-based statement.', 'Manage claim intake, assessment, settlement, and closure.', NULL, 103
),
(
    'attribute.business_domains.description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'description', 'description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Provides a richer description of the domain.', 'Detailed explanation of the domain boundary, scope, and responsibilities.', 'Include what is in and out of scope when helpful.', NULL, NULL, 104
),
(
    'attribute.business_domains.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 105
),
(
    'attribute.business_domains.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Domain', 'business_domains', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 106
),
(
    'attribute.business_capabilities.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a business capability.', 'Stable surrogate key for a capability record.', 'Use internally for joins and hierarchy.', NULL, NULL, 107
),
(
    'attribute.business_capabilities.capability_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'capability_name', 'capability_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the capability name.', 'Human-readable name of the business ability.', 'Name as a business ability, usually noun/verb phrase, not an implementation or process step.', 'Assess Risk', NULL, 108
),
(
    'attribute.business_capabilities.capability_description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'capability_description', 'capability_description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Describes what the capability enables.', 'Business definition of the capability and its intended business outcome.', 'Keep implementation independent; avoid naming specific applications.', NULL, NULL, 109
),
(
    'attribute.business_capabilities.capability_level', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'capability_level', 'capability_level', 'INTEGER', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Indicates the hierarchy level of the capability.', 'Numeric level used to distinguish parent and child capability layers.', 'Use level 1 for broad capabilities and higher numbers for decomposed child capabilities.', '1; 2', NULL, 110
),
(
    'attribute.business_capabilities.parent_capability_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'parent_capability_id', 'parent_capability_id', 'UUID', FALSE, FALSE, TRUE, 'Business Capability', 'business_capabilities', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Links a capability to its parent capability.', 'Self-referencing foreign key used for capability hierarchy.', 'Use only when modeling capability decomposition. Leave null for top-level capabilities.', NULL, NULL, 111
),
(
    'attribute.business_capabilities.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 112
),
(
    'attribute.business_capabilities.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Capability', 'business_capabilities', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 113
),
(
    'attribute.domain_capabilities.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain Capability Relationship', 'domain_capabilities', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a domain-capability relationship.', 'Stable surrogate key for a domain-to-capability relationship row.', 'Use internally for joins.', NULL, NULL, 114
),
(
    'attribute.domain_capabilities.domain_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain Capability Relationship', 'domain_capabilities', 'domain_id', 'domain_id', 'UUID', TRUE, FALSE, TRUE, 'Business Domain', 'business_domains', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the domain in the relationship.', 'Foreign key to business_domains.id.', 'Use the domain that owns or uses the capability.', NULL, NULL, 115
),
(
    'attribute.domain_capabilities.capability_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain Capability Relationship', 'domain_capabilities', 'capability_id', 'capability_id', 'UUID', TRUE, FALSE, TRUE, 'Business Capability', 'business_capabilities', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the capability in the relationship.', 'Foreign key to business_capabilities.id.', 'Use the capability that belongs to or is used by the domain.', NULL, NULL, 116
),
(
    'attribute.domain_capabilities.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain Capability Relationship', 'domain_capabilities', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'owns, uses, supports', 'Describes how the domain relates to the capability.', 'Relationship verb for the domain-capability association.', 'Use owns for the normal capability map.', 'owns', NULL, 117
),
(
    'attribute.domain_capabilities.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain Capability Relationship', 'domain_capabilities', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the relationship.', 'Free-text note about why the relationship exists or how it should be interpreted.', 'Use for architectural context, assumptions, and exceptions.', NULL, NULL, 118
),
(
    'attribute.business_processes.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a business process.', 'Stable surrogate key for a process record.', 'Use internally for joins and hierarchy.', NULL, NULL, 119
),
(
    'attribute.business_processes.process_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'process_name', 'process_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the business process name.', 'Human-readable name of the process or workflow step.', 'Use action-oriented process names.', 'Validate Policy Coverage', NULL, 120
),
(
    'attribute.business_processes.process_description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'process_description', 'process_description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Describes what happens in the process.', 'Business description of the process scope and outcome.', 'Avoid application-specific details unless essential for clarity.', NULL, NULL, 121
),
(
    'attribute.business_processes.process_level', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'process_level', 'process_level', 'INTEGER', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Indicates the hierarchy level of the process.', 'Numeric level used to distinguish parent and child process layers.', 'Use level 1 for end-to-end processes and level 2+ for decomposed steps.', NULL, NULL, 122
),
(
    'attribute.business_processes.parent_process_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'parent_process_id', 'parent_process_id', 'UUID', FALSE, FALSE, TRUE, 'Business Process', 'business_processes', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Links a process to its parent process.', 'Self-referencing foreign key used for process hierarchy.', 'Leave null for top-level/end-to-end processes.', NULL, NULL, 123
),
(
    'attribute.business_processes.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 124
),
(
    'attribute.business_processes.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Process', 'business_processes', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 125
),
(
    'attribute.capability_processes.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability Process Relationship', 'capability_processes', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a capability-process relationship.', 'Stable surrogate key for a capability-to-process relationship row.', 'Use internally for joins.', NULL, NULL, 126
),
(
    'attribute.capability_processes.capability_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability Process Relationship', 'capability_processes', 'capability_id', 'capability_id', 'UUID', TRUE, FALSE, TRUE, 'Business Capability', 'business_capabilities', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the capability being realized.', 'Foreign key to business_capabilities.id.', 'Use the capability that the process helps realize.', NULL, NULL, 127
),
(
    'attribute.capability_processes.process_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability Process Relationship', 'capability_processes', 'process_id', 'process_id', 'UUID', TRUE, FALSE, TRUE, 'Business Process', 'business_processes', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the process that realizes the capability.', 'Foreign key to business_processes.id.', 'Use the process that operationalizes the capability.', NULL, NULL, 128
),
(
    'attribute.capability_processes.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability Process Relationship', 'capability_processes', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'realized_by', 'Describes how the process relates to the capability.', 'Relationship verb for capability-process traceability.', 'Use realized_by for the normal capability-to-process mapping.', 'realized_by', NULL, 129
),
(
    'attribute.capability_processes.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability Process Relationship', 'capability_processes', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the relationship.', 'Free-text note about the capability-process mapping.', 'Use for business context or modeling assumptions.', NULL, NULL, 130
),
(
    'attribute.business_systems.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a business system.', 'Stable surrogate key for a system/application/platform/service record.', 'Use internally for joins. Reuse shared systems across domains.', NULL, NULL, 131
),
(
    'attribute.business_systems.system_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'system_name', 'system_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the unique system name.', 'Human-readable enterprise system name.', 'Must be unique. Do not create duplicate rows for shared systems.', 'Policy Administration System', NULL, 132
),
(
    'attribute.business_systems.system_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'system_type', 'system_type', 'VARCHAR(75)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Classifies the type of system.', 'System category such as Core Policy System, Data Warehouse, Digital Portal, Rules Engine, or Payment Processing System.', 'Use consistent controlled terms where possible.', NULL, NULL, 133
),
(
    'attribute.business_systems.lifecycle_status', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'lifecycle_status', 'lifecycle_status', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active, planned, target, deprecated, retired', 'Indicates current lifecycle state of the system.', 'Portfolio lifecycle value such as active, planned, target, deprecated, or retired.', 'Use to drive modernization and risk analysis.', 'active', NULL, 134
),
(
    'attribute.business_systems.owner_team', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'owner_team', 'owner_team', 'VARCHAR(150)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the owning or accountable team.', 'Team or organization accountable for the system.', 'Use stable team names. Consider normalizing into an owner table if ownership becomes complex.', NULL, NULL, 135
),
(
    'attribute.business_systems.description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'description', 'description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Describes the system and its role.', 'Detailed explanation of what the system does and how it is used.', 'Include primary business purpose and system boundary.', NULL, NULL, 136
),
(
    'attribute.business_systems.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 137
),
(
    'attribute.business_systems.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business System', 'business_systems', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 138
),
(
    'attribute.domain_systems.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain System Relationship', 'domain_systems', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a domain system relationship.', 'Stable surrogate key for a domain system relationship row.', 'Use internally for joins.', NULL, NULL, 139
),
(
    'attribute.domain_systems.domain_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain System Relationship', 'domain_systems', 'domain_id', 'domain_id', 'UUID', TRUE, FALSE, TRUE, 'Business Domain', 'business_domains', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business domain in the relationship.', 'Foreign key to business_domains.id.', 'Use the business domain participating in this relationship.', NULL, NULL, 140
),
(
    'attribute.domain_systems.system_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain System Relationship', 'domain_systems', 'system_id', 'system_id', 'UUID', TRUE, FALSE, TRUE, 'Business System', 'business_systems', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business system in the relationship.', 'Foreign key to business_systems.id.', 'Use the business system participating in this relationship.', NULL, NULL, 141
),
(
    'attribute.domain_systems.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain System Relationship', 'domain_systems', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'owns, uses', 'Describes the relationship verb.', 'Relationship type for the Business Domain to Business System association.', 'Use uses for the standard mapping.', 'uses', NULL, 142
),
(
    'attribute.domain_systems.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Domain System Relationship', 'domain_systems', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the relationship.', 'Free-text note about the relationship.', 'Use for architectural context, assumptions, and exceptions.', NULL, NULL, 143
),
(
    'attribute.process_systems.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Process System Relationship', 'process_systems', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a process system relationship.', 'Stable surrogate key for a process system relationship row.', 'Use internally for joins.', NULL, NULL, 144
),
(
    'attribute.process_systems.process_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Process System Relationship', 'process_systems', 'process_id', 'process_id', 'UUID', TRUE, FALSE, TRUE, 'Business Process', 'business_processes', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business process in the relationship.', 'Foreign key to business_processes.id.', 'Use the business process participating in this relationship.', NULL, NULL, 145
),
(
    'attribute.process_systems.system_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Process System Relationship', 'process_systems', 'system_id', 'system_id', 'UUID', TRUE, FALSE, TRUE, 'Business System', 'business_systems', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business system in the relationship.', 'Foreign key to business_systems.id.', 'Use the business system participating in this relationship.', NULL, NULL, 146
),
(
    'attribute.process_systems.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Process System Relationship', 'process_systems', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'supported_by', 'Describes the relationship verb.', 'Relationship type for the Business Process to Business System association.', 'Use supported_by for the standard mapping.', 'supported_by', NULL, 147
),
(
    'attribute.process_systems.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Process System Relationship', 'process_systems', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the relationship.', 'Free-text note about the relationship.', 'Use for architectural context, assumptions, and exceptions.', NULL, NULL, 148
),
(
    'attribute.capability_systems.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a capability system relationship.', 'Stable surrogate key for a capability system relationship row.', 'Use internally for joins.', NULL, NULL, 149
),
(
    'attribute.capability_systems.capability_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'capability_id', 'capability_id', 'UUID', TRUE, FALSE, TRUE, 'Business Capability', 'business_capabilities', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business capability in the relationship.', 'Foreign key to business_capabilities.id.', 'Use the business capability participating in this relationship.', NULL, NULL, 150
),
(
    'attribute.capability_systems.system_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'system_id', 'system_id', 'UUID', TRUE, FALSE, TRUE, 'Business System', 'business_systems', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the business system in the relationship.', 'Foreign key to business_systems.id.', 'Use the business system participating in this relationship.', NULL, NULL, 151
),
(
    'attribute.capability_systems.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'supported_by', 'Describes the relationship verb.', 'Relationship type for the Business Capability to Business System association.', 'Use supported_by for the standard mapping.', 'supported_by', NULL, 152
),
(
    'attribute.capability_systems.criticality', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'criticality', 'criticality', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'high, medium, low', 'Captures how critical the system is to the capability.', 'Relative criticality of the system for supporting the capability.', 'Use high, medium, or low consistently. High indicates significant business impact if unavailable.', 'high', NULL, 153
),
(
    'attribute.capability_systems.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Capability System Relationship', 'capability_systems', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the relationship.', 'Free-text note about the relationship.', 'Use for architectural context, assumptions, and exceptions.', NULL, NULL, 154
),
(
    'attribute.technology_components.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a technology component.', 'Stable surrogate key for a technology record.', 'Use internally for joins.', NULL, NULL, 155
),
(
    'attribute.technology_components.technology_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'technology_name', 'technology_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the unique technology name.', 'Human-readable name of the technology component.', 'Must be unique. Reuse existing technology records across systems.', 'Java', NULL, 156
),
(
    'attribute.technology_components.technology_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'technology_type', 'technology_type', 'VARCHAR(75)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Classifies the type of technology.', 'Technology category such as Database, Programming Language, Web Framework, Event Streaming, or Object Storage.', 'Use consistent categories to support portfolio reporting.', NULL, NULL, 157
),
(
    'attribute.technology_components.vendor_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'vendor_name', 'vendor_name', 'VARCHAR(150)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the vendor or steward of the technology.', 'Vendor, community, or enterprise platform owner associated with the technology.', 'Use for vendor risk and standards analysis.', NULL, NULL, 158
),
(
    'attribute.technology_components.lifecycle_status', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'lifecycle_status', 'lifecycle_status', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active, planned, target, deprecated, retired', 'Indicates current lifecycle state of the technology.', 'Portfolio lifecycle value for the technology.', 'Use to identify deprecated or target technologies.', 'active', NULL, 159
),
(
    'attribute.technology_components.description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'description', 'description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Describes the technology component.', 'Explanation of what the technology is and how it is generally used.', 'Include important usage boundaries or standardization guidance.', NULL, NULL, 160
),
(
    'attribute.technology_components.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 161
),
(
    'attribute.technology_components.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Technology Component', 'technology_components', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 162
),
(
    'attribute.system_technologies.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Technology Relationship', 'system_technologies', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a system-technology relationship.', 'Stable surrogate key for a system-to-technology relationship row.', 'Use internally for joins.', NULL, NULL, 163
),
(
    'attribute.system_technologies.system_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Technology Relationship', 'system_technologies', 'system_id', 'system_id', 'UUID', TRUE, FALSE, TRUE, 'Business System', 'business_systems', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the system using the technology.', 'Foreign key to business_systems.id.', 'Use the system that depends on the technology.', NULL, NULL, 164
),
(
    'attribute.system_technologies.technology_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Technology Relationship', 'system_technologies', 'technology_id', 'technology_id', 'UUID', TRUE, FALSE, TRUE, 'Technology Component', 'technology_components', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the technology being used.', 'Foreign key to technology_components.id.', 'Use the technology component actually used by the system.', NULL, NULL, 165
),
(
    'attribute.system_technologies.relationship_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Technology Relationship', 'system_technologies', 'relationship_type', 'relationship_type', 'VARCHAR(50)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'uses', 'Describes the relationship verb.', 'Relationship type for the system-to-technology dependency.', 'Use uses for normal technology dependency mapping.', 'uses', NULL, 166
),
(
    'attribute.system_technologies.usage_description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Technology Relationship', 'system_technologies', 'usage_description', 'usage_description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Explains how the technology is used by the system.', 'Free-text usage context for the system-technology dependency.', 'Include enough detail for impact analysis, e.g., database, backend runtime, frontend framework, authentication, integration, or storage role.', NULL, NULL, 167
),
(
    'attribute.business_data_entities.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a business data entity.', 'Stable surrogate key for a business data entity record.', 'Use internally for joins.', NULL, NULL, 168
),
(
    'attribute.business_data_entities.entity_name', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'entity_name', 'entity_name', 'VARCHAR(150)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the unique business data entity name.', 'Human-readable name of the business data concept.', 'Must be unique. Reuse shared data entities across domains and systems.', 'Policy', NULL, 169
),
(
    'attribute.business_data_entities.entity_description', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'entity_description', 'entity_description', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Describes the meaning of the data entity.', 'Business definition of the data entity and what it represents.', 'Avoid physical database implementation details unless useful.', NULL, NULL, 170
),
(
    'attribute.business_data_entities.data_domain', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'data_domain', 'data_domain', 'VARCHAR(150)', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Groups the data entity into a data domain.', 'Business data subject area such as Policy, Claims, Customer, Billing, Finance, or Underwriting.', 'Use for data architecture grouping and ownership conversations.', NULL, NULL, 171
),
(
    'attribute.business_data_entities.created_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'created_at', 'created_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the creation timestamp.', 'Timestamp when the record was created.', 'Use for auditing and sorting. Do not use as the primary business effective date.', NULL, NULL, 172
),
(
    'attribute.business_data_entities.updated_at', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'Business Data Entity', 'business_data_entities', 'updated_at', 'updated_at', 'TIMESTAMP', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Stores the last update timestamp.', 'Timestamp when the record was last updated.', 'Update whenever the record changes. Use for synchronization and audit review.', NULL, NULL, 173
),
(
    'attribute.system_data_entities.id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Data Entity Relationship', 'system_data_entities', 'id', 'id', 'UUID', TRUE, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uniquely identifies a system-data relationship.', 'Stable surrogate key for a system-to-data-entity relationship row.', 'Use internally for joins.', NULL, NULL, 174
),
(
    'attribute.system_data_entities.system_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Data Entity Relationship', 'system_data_entities', 'system_id', 'system_id', 'UUID', TRUE, FALSE, TRUE, 'Business System', 'business_systems', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the system in the data relationship.', 'Foreign key to business_systems.id.', 'Use the system that owns, creates, reads, updates, deletes, consumes, or produces the data entity.', NULL, NULL, 175
),
(
    'attribute.system_data_entities.data_entity_id', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Data Entity Relationship', 'system_data_entities', 'data_entity_id', 'data_entity_id', 'UUID', TRUE, FALSE, TRUE, 'Business Data Entity', 'business_data_entities', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies the data entity in the relationship.', 'Foreign key to business_data_entities.id.', 'Use the business data concept being managed or used.', NULL, NULL, 176
),
(
    'attribute.system_data_entities.crud_type', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Data Entity Relationship', 'system_data_entities', 'crud_type', 'crud_type', 'VARCHAR(20)', TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'create, read, update, delete, own, consume, produce', 'Describes the data responsibility or usage type.', 'CRUD/data-lineage verb describing how a system relates to a data entity.', 'Use own for system-of-record responsibility. Use consume/produce for integration or analytical data flows.', 'own', NULL, 177
),
(
    'attribute.system_data_entities.notes', 'ATTRIBUTE', 'Architecture Repository', 'Enterprise Architecture', 'System Data Entity Relationship', 'system_data_entities', 'notes', 'notes', 'TEXT', FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures explanatory notes for the data relationship.', 'Free-text explanation of the system-data relationship.', 'Use to describe system-of-record decisions, integration assumptions, and lineage details.', NULL, NULL, 178
),
(
    'relationship.business_domain_owns_business_capability', 'RELATIONSHIP', 'Business Architecture', 'Business Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Domain owns Business Capability', 'domain_capabilities', 'Business Domain', 'business_domains', 'domain_id', 'Business Capability', 'business_capabilities', 'capability_id', 'owns', 'many-to-many', 'owns, uses, supports', 'Defines the capability map for each business domain.', 'A business domain may own many capabilities, and a capability may be associated with more than one domain when shared or cross-domain.', 'Use relationship_type = owns for the normal ownership relationship. Avoid duplicating the same domain/capability/type combination.', 'Claims --owns--> Capture First Notice of Loss.', NULL, 501
),
(
    'relationship.business_capability_parent_child', 'RELATIONSHIP', 'Business Architecture', 'Business Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Capability decomposes into Business Capability', 'business_capabilities', 'Business Capability', 'business_capabilities', 'id', 'Business Capability', 'business_capabilities', 'parent_capability_id', 'parent_of', 'one-to-many', NULL, 'Supports capability decomposition and hierarchical capability maps.', 'A top-level capability can have child capabilities. Child capabilities reference the parent through parent_capability_id.', 'Use hierarchy for decomposition only. Do not use it to represent process sequence or system dependency.', 'Manage Underwriting --parent_of--> Assess Risk.', NULL, 502
),
(
    'relationship.business_capability_realized_by_business_process', 'RELATIONSHIP', 'Business Architecture', 'Business Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Capability realized by Business Process', 'capability_processes', 'Business Capability', 'business_capabilities', 'capability_id', 'Business Process', 'business_processes', 'process_id', 'realized_by', 'many-to-many', 'realized_by', 'Connects stable business abilities to the business processes that operationalize them.', 'A capability may be realized by one or more processes, and a process may contribute to one or more capabilities.', 'Use this relationship for capability-to-process traceability and business operating model analysis.', 'Assess Risk --realized_by--> Evaluate Applicant Risk.', NULL, 503
),
(
    'relationship.business_process_parent_child', 'RELATIONSHIP', 'Business Architecture', 'Business Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Process decomposes into Business Process', 'business_processes', 'Business Process', 'business_processes', 'id', 'Business Process', 'business_processes', 'parent_process_id', 'parent_of', 'one-to-many', NULL, 'Supports process decomposition and end-to-end process hierarchy.', 'A top-level business process can have child process steps. Child processes reference the parent through parent_process_id.', 'Use hierarchy for decomposition, not for sequence or orchestration unless explicitly modeled later.', 'End-to-End Claims Handling --parent_of--> Submit First Notice of Loss.', NULL, 504
),
(
    'relationship.business_domain_uses_business_system', 'RELATIONSHIP', 'Application Architecture', 'Application Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Domain owns or uses Business System', 'domain_systems', 'Business Domain', 'business_domains', 'domain_id', 'Business System', 'business_systems', 'system_id', 'owns_or_uses', 'many-to-many', 'owns, uses', 'Shows which systems belong to or are used by each business domain.', 'A domain may own systems and may also use shared systems owned by other domains.', 'Use owns for accountability and uses for dependency. Do not create duplicate system records for the same shared system.', 'Underwriting --uses--> Policy Administration System.', NULL, 505
),
(
    'relationship.business_process_supported_by_business_system', 'RELATIONSHIP', 'Application Architecture', 'Application Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Process supported by Business System', 'process_systems', 'Business Process', 'business_processes', 'process_id', 'Business System', 'business_systems', 'system_id', 'supported_by', 'many-to-many', 'supported_by', 'Connects process execution to the systems that support or automate it.', 'A process can be supported by multiple systems, and a system can support many processes.', 'Use this relationship for process impact analysis and process/system coverage views.', 'Validate Policy Coverage --supported_by--> Policy Administration System.', NULL, 506
),
(
    'relationship.business_capability_supported_by_business_system', 'RELATIONSHIP', 'Application Architecture', 'Application Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business Capability supported by Business System', 'capability_systems', 'Business Capability', 'business_capabilities', 'capability_id', 'Business System', 'business_systems', 'system_id', 'supported_by', 'many-to-many', 'supported_by', 'Provides direct traceability from capabilities to supporting systems.', 'This relationship is a useful shortcut for portfolio views and impact analysis, complementing capability_processes and process_systems.', 'Keep direct mappings aligned with process-level evidence where possible. Use criticality to indicate importance.', 'Collect Payment --supported_by--> Payment Gateway.', NULL, 507
),
(
    'relationship.business_system_uses_technology_component', 'RELATIONSHIP', 'Technology Architecture', 'Technology Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business System uses Technology Component', 'system_technologies', 'Business System', 'business_systems', 'system_id', 'Technology Component', 'technology_components', 'technology_id', 'uses', 'many-to-many', 'uses', 'Captures technology dependencies of business systems.', 'A system may use many technologies, and a technology may be used by many systems.', 'Use this relationship for technology lifecycle, deprecation, standards, and modernization impact analysis.', 'Claims Core Platform --uses--> Java.', NULL, 508
),
(
    'relationship.business_system_relates_to_business_data_entity', 'RELATIONSHIP', 'Data Architecture', 'Data Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, 'Business System relates to Business Data Entity', 'system_data_entities', 'Business System', 'business_systems', 'system_id', 'Business Data Entity', 'business_data_entities', 'data_entity_id', 'crud_type', 'many-to-many', 'create, read, update, delete, own, consume, produce', 'Captures data ownership, usage, and lineage between systems and business data entities.', 'A system may own, create, read, update, delete, consume, or produce a data entity.', 'Use own for system-of-record responsibility. Use consume/produce for integration or analytical data movement.', 'Billing Platform --own--> Invoice.', NULL, 509
),
(
    'value_set.relationship_type.domain_capabilities', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'owns, uses, supports', 'Defines allowed relationship verbs for domain_capabilities.', 'Controls how a business domain is associated with a business capability.', 'Use owns for primary domain ownership. Use uses/supports only when modeling non-owner dependencies.', 'Claims owns Assess Claim.', NULL, 701
),
(
    'value_set.relationship_type.capability_processes', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'realized_by', 'Defines allowed relationship verbs for capability_processes.', 'Controls how a capability is connected to business processes.', 'Use realized_by consistently to mean the process operationalizes the capability.', 'Assess Risk realized_by Evaluate Applicant Risk.', NULL, 702
),
(
    'value_set.relationship_type.domain_systems', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'owns, uses', 'Defines allowed relationship verbs for domain_systems.', 'Controls whether a domain owns or merely uses a system.', 'Use owns when the domain is accountable for the system; use uses for shared dependency.', 'Billing and Payments uses Policy Administration System.', NULL, 703
),
(
    'value_set.relationship_type.process_systems', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'supported_by', 'Defines allowed relationship verbs for process_systems.', 'Controls how processes connect to supporting systems.', 'Use supported_by when a system enables, automates, records, or supports a process.', 'Collect Payment supported_by Payment Gateway.', NULL, 704
),
(
    'value_set.relationship_type.capability_systems', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'supported_by', 'Defines allowed relationship verbs for capability_systems.', 'Controls direct capability-to-system traceability.', 'Use supported_by and set criticality where useful.', 'Issue Policy supported_by Policy Administration System.', NULL, 705
),
(
    'value_set.relationship_type.system_technologies', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'uses', 'Defines allowed relationship verbs for system_technologies.', 'Controls system-to-technology dependency mapping.', 'Use uses to indicate a system depends on the technology component.', 'Underwriting Workbench uses PostgreSQL.', NULL, 706
),
(
    'value_set.crud_type.system_data_entities', 'VALUE_SET', 'Metadata', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'create, read, update, delete, own, consume, produce', 'Defines allowed CRUD and data-lineage verbs for system_data_entities.', 'Controls how a system relates to a business data entity.', 'Use own for system-of-record responsibility, read/update for transactional access, consume/produce for integration and analytical data movement.', 'Policy Administration System own Policy.', NULL, 707
),
(
    'query_pattern.domain_capability_process_system_technology_path', 'QUERY_PATTERN', 'Architecture Repository', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shows the main business-to-technology traceability path.', 'Joins business_domains -> domain_capabilities -> business_capabilities -> capability_processes -> business_processes -> process_systems -> business_systems -> system_technologies -> technology_components.', 'Use for architecture path views, graph visualization, and domain-level technology impact analysis.', 'Claims --owns--> Validate Coverage --realized_by--> Validate Policy Coverage --supported_by--> Policy Administration System --uses--> Java.', NULL, 801
),
(
    'query_pattern.technology_impact_analysis', 'QUERY_PATTERN', 'Architecture Repository', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Finds business impact from a selected technology component.', 'Starts at technology_components and traverses to systems, processes, capabilities, domains, and optionally data entities.', 'Use when a technology is deprecated, vulnerable, non-standard, or targeted for modernization.', 'If Java is deprecated, identify impacted systems, owner teams, processes, capabilities, domains, and data entities.', NULL, 802
),
(
    'query_pattern.system_data_entity_lineage', 'QUERY_PATTERN', 'Architecture Repository', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shows which systems own, create, read, update, consume, or produce business data entities.', 'Joins business_systems -> system_data_entities -> business_data_entities and uses crud_type to describe data responsibility.', 'Use for system-of-record decisions, lineage, integration analysis, and data governance.', 'Billing Platform owns Invoice; Billing Data Warehouse consumes Invoice.', NULL, 803
),
(
    'query_pattern.shared_system_dependency', 'QUERY_PATTERN', 'Architecture Repository', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Identifies systems used across multiple domains.', 'Uses domain_systems to count domains related to a system and identify shared enterprise dependencies.', 'Use to find enterprise platforms, shared services, high-impact modernization candidates, and cross-domain dependencies.', 'Policy Administration System is used by Claims, Underwriting, Policy Administration, and Billing and Payments.', NULL, 804
),
(
    'governance_rule.reuse_shared_system_names', 'GOVERNANCE_RULE', 'Governance', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Prevents duplicate system records for shared enterprise systems.', 'business_systems.system_name is the natural reusable key for systems and should remain unique.', 'When a system is used by multiple domains, reuse the existing business_systems row and add relationships in domain_systems, process_systems, and capability_systems.', 'Do not create separate Policy Administration System records for Claims, Underwriting, and Policy Administration.', NULL, 901
),
(
    'governance_rule.reuse_shared_data_entities', 'GOVERNANCE_RULE', 'Governance', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Prevents duplicate business data entity records.', 'business_data_entities.entity_name is the natural reusable key for business data concepts.', 'When a data entity is used by multiple systems or domains, reuse the existing row and add system_data_entities relationships.', 'Reuse Policy and Customer across Claims, Underwriting, Policy Administration, and Billing.', NULL, 902
),
(
    'governance_rule.relationship_rows_are_business_facts', 'GOVERNANCE_RULE', 'Governance', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Ensures relationship tables represent explicit architecture facts.', 'Bridge tables are not just technical join tables; each row is a business or architecture relationship assertion.', 'Maintain notes, relationship_type, crud_type, and criticality where useful so architects can interpret the relationship correctly.', 'Billing Platform owns Invoice is an architecture fact about system-of-record responsibility.', NULL, 903
),
(
    'governance_rule.start_relational_project_graph_later', 'GOVERNANCE_RULE', 'Governance', 'Enterprise Architecture', NULL, NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Captures the current architecture decision to use PostgreSQL as system of record.', 'The current model has predictable paths and small volume, so relational modeling is appropriate. Graph visualization can be generated from relational queries.', 'Only introduce a graph database later if open-ended traversal, unknown-path analysis, circular dependency detection, or knowledge-graph exploration becomes central.', 'Use PostgreSQL views now; optionally project to Neo4j later.', NULL, 904
)
ON CONFLICT (metadata_key) DO UPDATE
SET
    metadata_type = EXCLUDED.metadata_type,
    subject_area = EXCLUDED.subject_area,
    model_layer = EXCLUDED.model_layer,
    entity_name = EXCLUDED.entity_name,
    table_name = EXCLUDED.table_name,
    attribute_name = EXCLUDED.attribute_name,
    column_name = EXCLUDED.column_name,
    data_type = EXCLUDED.data_type,
    is_required = EXCLUDED.is_required,
    is_primary_key = EXCLUDED.is_primary_key,
    is_foreign_key = EXCLUDED.is_foreign_key,
    referenced_entity_name = EXCLUDED.referenced_entity_name,
    referenced_table_name = EXCLUDED.referenced_table_name,
    relationship_name = EXCLUDED.relationship_name,
    relationship_table_name = EXCLUDED.relationship_table_name,
    from_entity_name = EXCLUDED.from_entity_name,
    from_table_name = EXCLUDED.from_table_name,
    from_column_name = EXCLUDED.from_column_name,
    to_entity_name = EXCLUDED.to_entity_name,
    to_table_name = EXCLUDED.to_table_name,
    to_column_name = EXCLUDED.to_column_name,
    relationship_type = EXCLUDED.relationship_type,
    cardinality = EXCLUDED.cardinality,
    allowed_values = EXCLUDED.allowed_values,
    purpose = EXCLUDED.purpose,
    definition = EXCLUDED.definition,
    usage_guidance = EXCLUDED.usage_guidance,
    example_usage = EXCLUDED.example_usage,
    governance_notes = EXCLUDED.governance_notes,
    sort_order = EXCLUDED.sort_order,
    updated_at = now();

COMMIT;

-- =========================================================
-- Useful metadata review queries
-- =========================================================

-- 1. List all model entities
-- SELECT metadata_key, entity_name, table_name, purpose, definition
-- FROM adm_metadata
-- WHERE metadata_type = 'ENTITY'
-- ORDER BY sort_order;

-- 2. List all attributes for one table
-- SELECT entity_name, column_name, data_type, is_required, is_primary_key, is_foreign_key,
--        referenced_table_name, purpose, definition, usage_guidance
-- FROM adm_metadata
-- WHERE metadata_type = 'ATTRIBUTE'
--   AND table_name = 'business_systems'
-- ORDER BY sort_order;

-- 3. List all relationships
-- SELECT relationship_name, from_entity_name, relationship_type, to_entity_name,
--        relationship_table_name, cardinality, purpose, usage_guidance
-- FROM adm_metadata
-- WHERE metadata_type = 'RELATIONSHIP'
-- ORDER BY sort_order;

-- 4. Search metadata by keyword
-- SELECT metadata_type, metadata_key, entity_name, attribute_name, relationship_name, purpose
-- FROM adm_metadata
-- WHERE purpose ILIKE '%impact%'
--    OR definition ILIKE '%impact%'
--    OR usage_guidance ILIKE '%impact%'
-- ORDER BY metadata_type, sort_order;
