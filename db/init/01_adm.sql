CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =========================================================
-- 1. Business Domains
-- Example: Claims, Billing, Underwriting, Customer Service
-- =========================================================

CREATE TABLE business_domains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_name VARCHAR(150) NOT NULL UNIQUE,
    domain_function TEXT,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- 2. Business Capabilities
-- Example: Manage Claims, Assess Risk, Issue Policy
-- Supports hierarchy through parent_capability_id
-- =========================================================

CREATE TABLE business_capabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    capability_name VARCHAR(150) NOT NULL,
    capability_description TEXT,
    capability_level INTEGER DEFAULT 1,
    parent_capability_id UUID NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT fk_capability_parent
        FOREIGN KEY (parent_capability_id)
        REFERENCES business_capabilities(id)
        ON DELETE SET NULL,

    CONSTRAINT uq_capability_name_parent
        UNIQUE (capability_name, parent_capability_id)
);

-- =========================================================
-- 3. Domain to Capability Mapping
-- Many domains can use many capabilities
-- =========================================================

CREATE TABLE domain_capabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL,
    capability_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'owns',
    notes TEXT,

    CONSTRAINT fk_domain_capabilities_domain
        FOREIGN KEY (domain_id)
        REFERENCES business_domains(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_domain_capabilities_capability
        FOREIGN KEY (capability_id)
        REFERENCES business_capabilities(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_domain_capability
        UNIQUE (domain_id, capability_id, relationship_type)
);

-- =========================================================
-- 4. Business Processes
-- Example: Submit Claim, Review Claim, Approve Claim
-- Supports process hierarchy
-- =========================================================

CREATE TABLE business_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    process_name VARCHAR(150) NOT NULL,
    process_description TEXT,
    process_level INTEGER DEFAULT 1,
    parent_process_id UUID NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT fk_process_parent
        FOREIGN KEY (parent_process_id)
        REFERENCES business_processes(id)
        ON DELETE SET NULL,

    CONSTRAINT uq_process_name_parent
        UNIQUE (process_name, parent_process_id)
);

-- =========================================================
-- 5. Capability to Process Mapping
-- A capability is realized by one or more processes
-- =========================================================

CREATE TABLE capability_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    capability_id UUID NOT NULL,
    process_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'realized_by',
    notes TEXT,

    CONSTRAINT fk_capability_processes_capability
        FOREIGN KEY (capability_id)
        REFERENCES business_capabilities(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_capability_processes_process
        FOREIGN KEY (process_id)
        REFERENCES business_processes(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_capability_process
        UNIQUE (capability_id, process_id, relationship_type)
);

-- =========================================================
-- 6. Business Systems / Applications
-- Example: Guidewire ClaimCenter, Salesforce, Billing System
-- =========================================================

CREATE TABLE business_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_name VARCHAR(150) NOT NULL UNIQUE,
    system_type VARCHAR(75),
    lifecycle_status VARCHAR(50) DEFAULT 'active',
    owner_team VARCHAR(150),
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- 7. Domain to System Mapping
-- A domain may own/use multiple systems
-- =========================================================

CREATE TABLE domain_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL,
    system_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'uses',
    notes TEXT,

    CONSTRAINT fk_domain_systems_domain
        FOREIGN KEY (domain_id)
        REFERENCES business_domains(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_domain_systems_system
        FOREIGN KEY (system_id)
        REFERENCES business_systems(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_domain_system
        UNIQUE (domain_id, system_id, relationship_type)
);

-- =========================================================
-- 8. Process to System Mapping
-- A process is automated/supported by one or more systems
-- =========================================================

CREATE TABLE process_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    process_id UUID NOT NULL,
    system_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'supported_by',
    notes TEXT,

    CONSTRAINT fk_process_systems_process
        FOREIGN KEY (process_id)
        REFERENCES business_processes(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_process_systems_system
        FOREIGN KEY (system_id)
        REFERENCES business_systems(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_process_system
        UNIQUE (process_id, system_id, relationship_type)
);

-- =========================================================
-- 9. Capability to System Mapping
-- Useful for direct APM reporting:
-- "Which systems support this capability?"
-- =========================================================

CREATE TABLE capability_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    capability_id UUID NOT NULL,
    system_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'supported_by',
    criticality VARCHAR(50),
    notes TEXT,

    CONSTRAINT fk_capability_systems_capability
        FOREIGN KEY (capability_id)
        REFERENCES business_capabilities(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_capability_systems_system
        FOREIGN KEY (system_id)
        REFERENCES business_systems(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_capability_system
        UNIQUE (capability_id, system_id, relationship_type)
);

-- =========================================================
-- 10. Technology Components
-- Example: PostgreSQL, Java, React, AWS Lambda, Kubernetes
-- =========================================================

CREATE TABLE technology_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technology_name VARCHAR(150) NOT NULL UNIQUE,
    technology_type VARCHAR(75),
    vendor_name VARCHAR(150),
    lifecycle_status VARCHAR(50) DEFAULT 'active',
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- 11. System to Technology Mapping
-- A system may use many technologies
-- =========================================================

CREATE TABLE system_technologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID NOT NULL,
    technology_id UUID NOT NULL,
    relationship_type VARCHAR(50) DEFAULT 'uses',
    usage_description TEXT,

    CONSTRAINT fk_system_technologies_system
        FOREIGN KEY (system_id)
        REFERENCES business_systems(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_system_technologies_technology
        FOREIGN KEY (technology_id)
        REFERENCES technology_components(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_system_technology
        UNIQUE (system_id, technology_id, relationship_type)
);

-- =========================================================
-- 12. Business Data Entities
-- Example: Customer, Policy, Claim, Invoice, Payment
-- =========================================================

CREATE TABLE business_data_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_name VARCHAR(150) NOT NULL UNIQUE,
    entity_description TEXT,
    data_domain VARCHAR(150),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- 13. System to Data Entity Mapping
-- A system creates, reads, updates, deletes, or owns data
-- =========================================================

CREATE TABLE system_data_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID NOT NULL,
    data_entity_id UUID NOT NULL,
    crud_type VARCHAR(20) NOT NULL,
    notes TEXT,

    CONSTRAINT fk_system_data_entities_system
        FOREIGN KEY (system_id)
        REFERENCES business_systems(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_system_data_entities_data_entity
        FOREIGN KEY (data_entity_id)
        REFERENCES business_data_entities(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_crud_type
        CHECK (crud_type IN ('create', 'read', 'update', 'delete', 'own', 'consume', 'produce')),

    CONSTRAINT uq_system_data_entity_crud
        UNIQUE (system_id, data_entity_id, crud_type)
);

-- =========================================================
-- 14. Helpful Indexes for Relationship Queries
-- =========================================================

CREATE INDEX idx_domain_capabilities_domain_id
    ON domain_capabilities(domain_id);

CREATE INDEX idx_domain_capabilities_capability_id
    ON domain_capabilities(capability_id);

CREATE INDEX idx_capability_processes_capability_id
    ON capability_processes(capability_id);

CREATE INDEX idx_capability_processes_process_id
    ON capability_processes(process_id);

CREATE INDEX idx_process_systems_process_id
    ON process_systems(process_id);

CREATE INDEX idx_process_systems_system_id
    ON process_systems(system_id);

CREATE INDEX idx_capability_systems_capability_id
    ON capability_systems(capability_id);

CREATE INDEX idx_capability_systems_system_id
    ON capability_systems(system_id);

CREATE INDEX idx_system_technologies_system_id
    ON system_technologies(system_id);

CREATE INDEX idx_system_technologies_technology_id
    ON system_technologies(technology_id);

CREATE INDEX idx_system_data_entities_system_id
    ON system_data_entities(system_id);

CREATE INDEX idx_system_data_entities_data_entity_id
    ON system_data_entities(data_entity_id);
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   BEGIN;

-- Optional reset for prototype testing only
-- TRUNCATE TABLE
--     system_data_entities,
--     business_data_entities,
--     system_technologies,
--     technology_components,
--     capability_systems,
--     process_systems,
--     domain_systems,
--     business_systems,
--     capability_processes,
--     business_processes,
--     domain_capabilities,
--     business_capabilities,
--     business_domains
-- RESTART IDENTITY CASCADE;

-- =========================================================
-- 1. Business Domain: Claims
-- =========================================================

INSERT INTO business_domains (
    id,
    domain_name,
    domain_function,
    description
)
VALUES (
    '10000000-0000-0000-0000-000000000001',
    'Claims',
    'Manage insurance claims from first notice of loss through settlement and closure',
    'Business domain responsible for claim intake, assessment, adjudication, payment, recovery, and claim closure.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 2. Business Capabilities
-- =========================================================

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    'Manage Claims',
    'End-to-end ability to manage insurance claims lifecycle.',
    1,
    NULL
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES
(
    '20000000-0000-0000-0000-000000000002',
    'Capture First Notice of Loss',
    'Ability to capture initial claim notification from customer, broker, agent, or partner.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000003',
    'Validate Coverage',
    'Ability to confirm policy coverage, limits, deductibles, and claim eligibility.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000004',
    'Assess Claim',
    'Ability to review loss details, evaluate damages, and determine claim outcome.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000005',
    'Manage Reserves',
    'Ability to create and update financial reserves for expected claim cost.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000006',
    'Settle Claim',
    'Ability to approve settlements and issue claim payments.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000007',
    'Manage Claim Documents',
    'Ability to collect, classify, store, and retrieve claim-related documents.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000008',
    'Detect Claim Fraud',
    'Ability to identify suspicious claim patterns and refer claims for investigation.',
    2,
    '20000000-0000-0000-0000-000000000001'
),
(
    '20000000-0000-0000-0000-000000000009',
    'Close Claim',
    'Ability to complete final claim review and formally close the claim record.',
    2,
    '20000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 3. Domain to Capability Mapping
-- =========================================================

INSERT INTO domain_capabilities (
    id,
    domain_id,
    capability_id,
    relationship_type,
    notes
)
VALUES
(
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'owns',
    'Claims domain owns the end-to-end claims capability.'
),
(
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    'owns',
    'Claims domain owns FNOL intake capability.'
),
(
    '30000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000003',
    'owns',
    'Claims domain owns coverage validation capability.'
),
(
    '30000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000004',
    'owns',
    'Claims domain owns claim assessment capability.'
),
(
    '30000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000005',
    'owns',
    'Claims domain owns reserve management capability.'
),
(
    '30000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000006',
    'owns',
    'Claims domain owns settlement capability.'
),
(
    '30000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000007',
    'owns',
    'Claims domain owns claim document management capability.'
),
(
    '30000000-0000-0000-0000-000000000008',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000008',
    'owns',
    'Claims domain owns fraud detection capability.'
),
(
    '30000000-0000-0000-0000-000000000009',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000009',
    'owns',
    'Claims domain owns claim closure capability.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 4. Business Processes
-- =========================================================

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES (
    '40000000-0000-0000-0000-000000000001',
    'End-to-End Claims Handling',
    'Overall process from claim intake to claim closure.',
    1,
    NULL
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES
(
    '40000000-0000-0000-0000-000000000002',
    'Submit First Notice of Loss',
    'Customer, broker, agent, or partner submits initial claim notification.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000003',
    'Create Claim Record',
    'A claim record is created and associated with policy, customer, and loss details.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000004',
    'Validate Policy Coverage',
    'Policy, coverage, limits, deductibles, and eligibility are validated.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000005',
    'Assign Adjuster',
    'Claim is assigned to an adjuster or claims team.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000006',
    'Review Loss Details',
    'Adjuster reviews loss facts, documents, parties involved, and claim context.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000007',
    'Estimate Damages',
    'Damage estimate is prepared directly or through vendors and appraisers.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000008',
    'Set Claim Reserve',
    'Initial and revised financial reserves are established for the claim.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000009',
    'Approve Settlement',
    'Settlement recommendation is reviewed and approved.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000010',
    'Issue Claim Payment',
    'Approved claim payment is issued to claimant, vendor, or third party.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000011',
    'Investigate Fraud Referral',
    'Suspicious claim is referred for fraud review or special investigation.',
    2,
    '40000000-0000-0000-0000-000000000001'
),
(
    '40000000-0000-0000-0000-000000000012',
    'Close Claim',
    'Claim is reviewed, finalized, and closed.',
    2,
    '40000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 5. Capability to Process Mapping
-- =========================================================

INSERT INTO capability_processes (
    id,
    capability_id,
    process_id,
    relationship_type,
    notes
)
VALUES
(
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000002',
    'realized_by',
    'FNOL capability is realized by the submit first notice of loss process.'
),
(
    '50000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000003',
    'realized_by',
    'FNOL capability includes claim record creation.'
),
(
    '50000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000004',
    'realized_by',
    'Coverage validation capability is realized by policy coverage validation.'
),
(
    '50000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000005',
    'realized_by',
    'Claim assessment includes adjuster assignment.'
),
(
    '50000000-0000-0000-0000-000000000005',
    '20000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000006',
    'realized_by',
    'Claim assessment includes loss detail review.'
),
(
    '50000000-0000-0000-0000-000000000006',
    '20000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000007',
    'realized_by',
    'Claim assessment includes damage estimation.'
),
(
    '50000000-0000-0000-0000-000000000007',
    '20000000-0000-0000-0000-000000000005',
    '40000000-0000-0000-0000-000000000008',
    'realized_by',
    'Reserve management is realized by reserve setting.'
),
(
    '50000000-0000-0000-0000-000000000008',
    '20000000-0000-0000-0000-000000000006',
    '40000000-0000-0000-0000-000000000009',
    'realized_by',
    'Settlement capability includes settlement approval.'
),
(
    '50000000-0000-0000-0000-000000000009',
    '20000000-0000-0000-0000-000000000006',
    '40000000-0000-0000-0000-000000000010',
    'realized_by',
    'Settlement capability includes issuing claim payment.'
),
(
    '50000000-0000-0000-0000-000000000010',
    '20000000-0000-0000-0000-000000000008',
    '40000000-0000-0000-0000-000000000011',
    'realized_by',
    'Fraud detection capability is realized by fraud referral investigation.'
),
(
    '50000000-0000-0000-0000-000000000011',
    '20000000-0000-0000-0000-000000000009',
    '40000000-0000-0000-0000-000000000012',
    'realized_by',
    'Claim closure capability is realized by close claim process.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 6. Business Systems / Applications
-- =========================================================

INSERT INTO business_systems (
    id,
    system_name,
    system_type,
    lifecycle_status,
    owner_team,
    description
)
VALUES
(
    '60000000-0000-0000-0000-000000000001',
    'Claims Core Platform',
    'Core Claims System',
    'active',
    'Claims Technology',
    'Primary claims management platform for claim creation, assignment, adjudication, reserve management, and closure.'
),
(
    '60000000-0000-0000-0000-000000000002',
    'Customer Claims Portal',
    'Digital Portal',
    'active',
    'Digital Channels',
    'Customer-facing portal used for FNOL submission, claim status, and document upload.'
),
(
    '60000000-0000-0000-0000-000000000003',
    'Policy Administration System',
    'Core Policy System',
    'active',
    'Policy Technology',
    'System of record for policies, coverages, limits, endorsements, and policyholder information.'
),
(
    '60000000-0000-0000-0000-000000000004',
    'Claims Document Management',
    'Document Management System',
    'active',
    'Enterprise Content Management',
    'Repository for claim documents, photos, estimates, correspondence, and supporting evidence.'
),
(
    '60000000-0000-0000-0000-000000000005',
    'Claims Payment Platform',
    'Payment System',
    'active',
    'Finance Technology',
    'Platform used to issue approved claim payments to claimants, vendors, and third parties.'
),
(
    '60000000-0000-0000-0000-000000000006',
    'Fraud Analytics Platform',
    'Analytics System',
    'active',
    'Data and Analytics',
    'Analytics platform used to identify claim fraud indicators and suspicious claim patterns.'
),
(
    '60000000-0000-0000-0000-000000000007',
    'Vendor Network Portal',
    'Partner Portal',
    'active',
    'Claims Vendor Management',
    'Portal used to assign work to repair vendors, appraisers, adjusters, and service providers.'
),
(
    '60000000-0000-0000-0000-000000000008',
    'Claims Data Warehouse',
    'Data Warehouse',
    'active',
    'Enterprise Data',
    'Analytical repository for claims reporting, metrics, dashboards, and portfolio analytics.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 7. Domain to System Mapping
-- =========================================================

INSERT INTO domain_systems (
    id,
    domain_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '70000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'owns',
    'Claims owns the core claims platform.'
),
(
    '70000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000002',
    'uses',
    'Claims uses customer portal for digital FNOL and claim status.'
),
(
    '70000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000003',
    'uses',
    'Claims uses policy administration system for coverage validation.'
),
(
    '70000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000004',
    'uses',
    'Claims uses document management for claim documents.'
),
(
    '70000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000005',
    'uses',
    'Claims uses payment platform for settlement payments.'
),
(
    '70000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000006',
    'uses',
    'Claims uses fraud analytics for suspicious claim detection.'
),
(
    '70000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000007',
    'uses',
    'Claims uses vendor portal for external service provider coordination.'
),
(
    '70000000-0000-0000-0000-000000000008',
    '10000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000008',
    'uses',
    'Claims uses data warehouse for reporting and analytics.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 8. Process to System Mapping
-- =========================================================

INSERT INTO process_systems (
    id,
    process_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '80000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'supported_by',
    'FNOL submission is supported by the customer claims portal.'
),
(
    '80000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Claim record creation is supported by the claims core platform.'
),
(
    '80000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000003',
    'supported_by',
    'Coverage validation depends on policy administration data.'
),
(
    '80000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Adjuster assignment is supported by the claims core platform.'
),
(
    '80000000-0000-0000-0000-000000000005',
    '40000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Loss detail review is supported by the claims core platform.'
),
(
    '80000000-0000-0000-0000-000000000006',
    '40000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000004',
    'supported_by',
    'Loss detail review uses claim documents from document management.'
),
(
    '80000000-0000-0000-0000-000000000007',
    '40000000-0000-0000-0000-000000000007',
    '60000000-0000-0000-0000-000000000007',
    'supported_by',
    'Damage estimation may be supported by vendor network portal.'
),
(
    '80000000-0000-0000-0000-000000000008',
    '40000000-0000-0000-0000-000000000008',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Reserve setting is managed in the claims core platform.'
),
(
    '80000000-0000-0000-0000-000000000009',
    '40000000-0000-0000-0000-000000000009',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Settlement approval is supported by the claims core platform.'
),
(
    '80000000-0000-0000-0000-000000000010',
    '40000000-0000-0000-0000-000000000010',
    '60000000-0000-0000-0000-000000000005',
    'supported_by',
    'Claim payment issuance is supported by the payment platform.'
),
(
    '80000000-0000-0000-0000-000000000011',
    '40000000-0000-0000-0000-000000000011',
    '60000000-0000-0000-0000-000000000006',
    'supported_by',
    'Fraud referral investigation is supported by fraud analytics platform.'
),
(
    '80000000-0000-0000-0000-000000000012',
    '40000000-0000-0000-0000-000000000012',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'Claim closure is completed in the claims core platform.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 9. Capability to System Mapping
-- =========================================================

INSERT INTO capability_systems (
    id,
    capability_id,
    system_id,
    relationship_type,
    criticality,
    notes
)
VALUES
(
    '90000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'supported_by',
    'high',
    'FNOL capability is highly dependent on the customer claims portal.'
),
(
    '90000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Claims core platform creates and manages the claim record.'
),
(
    '90000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000003',
    'supported_by',
    'high',
    'Coverage validation depends on the policy administration system.'
),
(
    '90000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Claim assessment is primarily supported by the claims core platform.'
),
(
    '90000000-0000-0000-0000-000000000005',
    '20000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Reserve management is handled in the claims core platform.'
),
(
    '90000000-0000-0000-0000-000000000006',
    '20000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000005',
    'supported_by',
    'high',
    'Settlement payment capability depends on payment platform.'
),
(
    '90000000-0000-0000-0000-000000000007',
    '20000000-0000-0000-0000-000000000007',
    '60000000-0000-0000-0000-000000000004',
    'supported_by',
    'medium',
    'Claim document management capability depends on document management system.'
),
(
    '90000000-0000-0000-0000-000000000008',
    '20000000-0000-0000-0000-000000000008',
    '60000000-0000-0000-0000-000000000006',
    'supported_by',
    'medium',
    'Fraud detection capability is supported by fraud analytics platform.'
),
(
    '90000000-0000-0000-0000-000000000009',
    '20000000-0000-0000-0000-000000000009',
    '60000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Claim closure is supported by claims core platform.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 10. Technology Components
-- =========================================================

INSERT INTO technology_components (
    id,
    technology_name,
    technology_type,
    vendor_name,
    lifecycle_status,
    description
)
VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'PostgreSQL',
    'Database',
    'PostgreSQL Global Development Group',
    'active',
    'Relational database used for claims transactional or analytical storage.'
),
(
    'a0000000-0000-0000-0000-000000000002',
    'React',
    'Frontend Framework',
    'Meta',
    'active',
    'Frontend library used for web interfaces.'
),
(
    'a0000000-0000-0000-0000-000000000003',
    'Next.js',
    'Web Application Framework',
    'Vercel',
    'active',
    'React framework used for customer and internal web applications.'
),
(
    'a0000000-0000-0000-0000-000000000004',
    'Java',
    'Programming Language',
    'Oracle / OpenJDK',
    'active',
    'Backend language used for enterprise core services.'
),
(
    'a0000000-0000-0000-0000-000000000005',
    'AWS Lambda',
    'Serverless Compute',
    'Amazon Web Services',
    'active',
    'Serverless runtime for event-driven processing.'
),
(
    'a0000000-0000-0000-0000-000000000006',
    'Amazon S3',
    'Object Storage',
    'Amazon Web Services',
    'active',
    'Object storage for documents and claim attachments.'
),
(
    'a0000000-0000-0000-0000-000000000007',
    'Kafka',
    'Event Streaming',
    'Apache',
    'active',
    'Event streaming platform for integration between systems.'
),
(
    'a0000000-0000-0000-0000-000000000008',
    'REST API Gateway',
    'Integration Technology',
    'Enterprise Platform',
    'active',
    'API gateway used to expose and secure service APIs.'
),
(
    'a0000000-0000-0000-0000-000000000009',
    'OAuth 2.0 / OIDC',
    'Identity and Access Management',
    'Enterprise IAM',
    'active',
    'Authentication and authorization standard for claims applications.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 11. System to Technology Mapping
-- =========================================================

INSERT INTO system_technologies (
    id,
    system_id,
    technology_id,
    relationship_type,
    usage_description
)
VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'uses',
    'Claims core platform uses PostgreSQL for claim transaction data.'
),
(
    'b0000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000004',
    'uses',
    'Claims core platform uses Java for backend services.'
),
(
    'b0000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000007',
    'uses',
    'Claims core platform publishes and consumes claims events through Kafka.'
),
(
    'b0000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    'uses',
    'Customer claims portal uses React for frontend.'
),
(
    'b0000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000003',
    'uses',
    'Customer claims portal uses Next.js for web application delivery.'
),
(
    'b0000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000009',
    'uses',
    'Customer claims portal uses OAuth/OIDC for secure authentication.'
),
(
    'b0000000-0000-0000-0000-000000000007',
    '60000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000006',
    'uses',
    'Claims document management uses S3 for object storage.'
),
(
    'b0000000-0000-0000-0000-000000000008',
    '60000000-0000-0000-0000-000000000005',
    'a0000000-0000-0000-0000-000000000008',
    'uses',
    'Payment platform exposes payment services through REST APIs.'
),
(
    'b0000000-0000-0000-0000-000000000009',
    '60000000-0000-0000-0000-000000000006',
    'a0000000-0000-0000-0000-000000000005',
    'uses',
    'Fraud analytics platform uses serverless functions for scoring jobs.'
),
(
    'b0000000-0000-0000-0000-000000000010',
    '60000000-0000-0000-0000-000000000008',
    'a0000000-0000-0000-0000-000000000001',
    'uses',
    'Claims data warehouse uses PostgreSQL-compatible analytical storage in this prototype.'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 12. Business Data Entities
-- =========================================================

INSERT INTO business_data_entities (
    id,
    entity_name,
    entity_description,
    data_domain
)
VALUES
(
    'c0000000-0000-0000-0000-000000000001',
    'Claim',
    'Primary record representing an insurance claim.',
    'Claims'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Policy',
    'Insurance policy against which claim coverage is validated.',
    'Policy'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'Customer',
    'Policyholder, claimant, or customer associated with a claim.',
    'Customer'
),
(
    'c0000000-0000-0000-0000-000000000004',
    'Loss Event',
    'Incident or event that caused the claim.',
    'Claims'
),
(
    'c0000000-0000-0000-0000-000000000005',
    'Adjuster',
    'Claims professional assigned to investigate and manage the claim.',
    'Claims'
),
(
    'c0000000-0000-0000-0000-000000000006',
    'Reserve',
    'Financial reserve established for expected claim cost.',
    'Claims Financials'
),
(
    'c0000000-0000-0000-0000-000000000007',
    'Claim Payment',
    'Payment issued against an approved claim settlement.',
    'Claims Financials'
),
(
    'c0000000-0000-0000-0000-000000000008',
    'Claim Document',
    'Document, image, estimate, communication, or attachment related to a claim.',
    'Claims'
),
(
    'c0000000-0000-0000-0000-000000000009',
    'Vendor',
    'External service provider involved in damage assessment, repair, or service delivery.',
    'Vendor Management'
),
(
    'c0000000-0000-0000-0000-000000000010',
    'Fraud Referral',
    'Referral record for suspicious claim investigation.',
    'Claims Fraud'
)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 13. System to Data Entity Mapping
-- =========================================================

INSERT INTO system_data_entities (
    id,
    system_id,
    data_entity_id,
    crud_type,
    notes
)
VALUES
(
    'd0000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'own',
    'Claims core platform is the system of record for Claim.'
),
(
    'd0000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000004',
    'create',
    'Claims core platform creates loss event details.'
),
(
    'd0000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000005',
    'update',
    'Claims core platform assigns and updates adjuster information.'
),
(
    'd0000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000006',
    'own',
    'Claims core platform owns reserve records.'
),
(
    'd0000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'create',
    'Customer portal initiates claim creation through FNOL submission.'
),
(
    'd0000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000008',
    'create',
    'Customer portal allows customers to upload claim documents.'
),
(
    'd0000000-0000-0000-0000-000000000007',
    '60000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000002',
    'own',
    'Policy administration system owns policy data.'
),
(
    'd0000000-0000-0000-0000-000000000008',
    '60000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000003',
    'read',
    'Policy administration system reads customer data for policy context.'
),
(
    'd0000000-0000-0000-0000-000000000009',
    '60000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000008',
    'own',
    'Document management system owns claim document storage.'
),
(
    'd0000000-0000-0000-0000-000000000010',
    '60000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000007',
    'own',
    'Payment platform owns claim payment execution records.'
),
(
    'd0000000-0000-0000-0000-000000000011',
    '60000000-0000-0000-0000-000000000006',
    'c0000000-0000-0000-0000-000000000010',
    'create',
    'Fraud analytics platform creates fraud referral recommendations.'
),
(
    'd0000000-0000-0000-0000-000000000012',
    '60000000-0000-0000-0000-000000000007',
    'c0000000-0000-0000-0000-000000000009',
    'own',
    'Vendor network portal owns vendor profile and assignment information.'
),
(
    'd0000000-0000-0000-0000-000000000013',
    '60000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000001',
    'consume',
    'Claims data warehouse consumes claim data for reporting.'
),
(
    'd0000000-0000-0000-0000-000000000014',
    '60000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000006',
    'consume',
    'Claims data warehouse consumes reserve data for financial reporting.'
),
(
    'd0000000-0000-0000-0000-000000000015',
    '60000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000007',
    'consume',
    'Claims data warehouse consumes payment data for settlement analytics.'
)
ON CONFLICT (id) DO NOTHING;

COMMIT;
















-- Underwtiting
rollback;
BEGIN;

-- =========================================================
-- 1. Business Domain: Underwriting
-- =========================================================

INSERT INTO business_domains (
    id,
    domain_name,
    domain_function,
    description
)
VALUES (
    '10000000-0000-0000-0000-000000000002',
    'Underwriting',
    'Evaluate insurance risk, determine eligibility, price risk, and approve or decline insurance submissions',
    'Business domain responsible for risk assessment, underwriting decisions, quote evaluation, pricing, referrals, and policy approval.'
)
ON CONFLICT (domain_name) DO UPDATE
SET
    domain_function = EXCLUDED.domain_function,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 2. Business Capabilities
-- =========================================================

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Manage Underwriting',
    'End-to-end ability to evaluate, price, approve, decline, and manage insurance risk.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES
(
    '21000000-0000-0000-0000-000000000002',
    'Receive Insurance Submission',
    'Ability to receive new business or renewal submissions from brokers, agents, portals, or internal teams.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000003',
    'Assess Risk',
    'Ability to evaluate applicant, exposure, coverage, loss history, and other risk factors.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000004',
    'Rate and Price Risk',
    'Ability to calculate premium, apply rating factors, discounts, surcharges, and underwriting pricing rules.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000005',
    'Apply Underwriting Rules',
    'Ability to apply eligibility, referral, decline, approval, and exception rules.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000006',
    'Manage Underwriting Referral',
    'Ability to route complex, high-risk, or exception cases to underwriting specialists.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000007',
    'Issue Quote',
    'Ability to generate, review, approve, and present insurance quotes.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000008',
    'Approve or Decline Risk',
    'Ability to make final underwriting decision to accept, decline, or conditionally approve risk.',
    2,
    '21000000-0000-0000-0000-000000000001'
),
(
    '21000000-0000-0000-0000-000000000009',
    'Bind Coverage',
    'Ability to convert an accepted quote into bound coverage or policy issuance request.',
    2,
    '21000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

-- =========================================================
-- 3. Domain to Capability Mapping
-- =========================================================

INSERT INTO domain_capabilities (
    id,
    domain_id,
    capability_id,
    relationship_type,
    notes
)
VALUES
(
    '31000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000001',
    'owns',
    'Underwriting domain owns the end-to-end underwriting capability.'
),
(
    '31000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000002',
    'owns',
    'Underwriting owns insurance submission intake capability.'
),
(
    '31000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000003',
    'owns',
    'Underwriting owns risk assessment capability.'
),
(
    '31000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000004',
    'owns',
    'Underwriting owns risk rating and pricing capability.'
),
(
    '31000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000005',
    'owns',
    'Underwriting owns underwriting rules capability.'
),
(
    '31000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000006',
    'owns',
    'Underwriting owns referral management capability.'
),
(
    '31000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000007',
    'owns',
    'Underwriting owns quote issuance capability.'
),
(
    '31000000-0000-0000-0000-000000000008',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000008',
    'owns',
    'Underwriting owns risk approval and decline capability.'
),
(
    '31000000-0000-0000-0000-000000000009',
    '10000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000009',
    'owns',
    'Underwriting owns bind coverage capability.'
)
ON CONFLICT ON CONSTRAINT uq_domain_capability DO NOTHING;

-- =========================================================
-- 4. Business Processes
-- =========================================================

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES (
    '41000000-0000-0000-0000-000000000001',
    'End-to-End Underwriting',
    'Overall process from submission intake through underwriting decision and binding.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES
(
    '41000000-0000-0000-0000-000000000002',
    'Receive Submission',
    'Receive new business or renewal submission from broker, agent, customer, or portal.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000003',
    'Validate Submission Completeness',
    'Confirm that required application data, documents, coverages, and supporting information are present.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000004',
    'Evaluate Applicant Risk',
    'Review applicant, property, vehicle, business, exposure, history, and other risk attributes.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000005',
    'Check Loss History',
    'Review prior claims, losses, and risk events relevant to the underwriting decision.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000006',
    'Run Rating Calculation',
    'Calculate base premium, adjustments, discounts, surcharges, taxes, and fees.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000007',
    'Apply Eligibility Rules',
    'Apply underwriting rules to determine acceptability, referral, or decline conditions.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000008',
    'Refer Case to Underwriter',
    'Route complex or exception cases to an underwriter for manual review.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000009',
    'Prepare Quote',
    'Prepare quote package including premium, coverage terms, limits, deductibles, and conditions.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000010',
    'Approve or Decline Submission',
    'Make final underwriting decision to approve, decline, or approve with conditions.',
    2,
    '41000000-0000-0000-0000-000000000001'
),
(
    '41000000-0000-0000-0000-000000000011',
    'Bind Coverage',
    'Bind accepted quote and initiate policy issuance or policy update.',
    2,
    '41000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

-- =========================================================
-- 5. Capability to Process Mapping
-- =========================================================

INSERT INTO capability_processes (
    id,
    capability_id,
    process_id,
    relationship_type,
    notes
)
VALUES
(
    '51000000-0000-0000-0000-000000000001',
    '21000000-0000-0000-0000-000000000002',
    '41000000-0000-0000-0000-000000000002',
    'realized_by',
    'Submission intake capability is realized by receiving submissions.'
),
(
    '51000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000002',
    '41000000-0000-0000-0000-000000000003',
    'realized_by',
    'Submission intake includes completeness validation.'
),
(
    '51000000-0000-0000-0000-000000000003',
    '21000000-0000-0000-0000-000000000003',
    '41000000-0000-0000-0000-000000000004',
    'realized_by',
    'Risk assessment is realized by evaluating applicant risk.'
),
(
    '51000000-0000-0000-0000-000000000004',
    '21000000-0000-0000-0000-000000000003',
    '41000000-0000-0000-0000-000000000005',
    'realized_by',
    'Risk assessment includes loss history review.'
),
(
    '51000000-0000-0000-0000-000000000005',
    '21000000-0000-0000-0000-000000000004',
    '41000000-0000-0000-0000-000000000006',
    'realized_by',
    'Pricing capability is realized by rating calculation.'
),
(
    '51000000-0000-0000-0000-000000000006',
    '21000000-0000-0000-0000-000000000005',
    '41000000-0000-0000-0000-000000000007',
    'realized_by',
    'Underwriting rules capability is realized by applying eligibility rules.'
),
(
    '51000000-0000-0000-0000-000000000007',
    '21000000-0000-0000-0000-000000000006',
    '41000000-0000-0000-0000-000000000008',
    'realized_by',
    'Referral capability is realized by routing case to underwriter.'
),
(
    '51000000-0000-0000-0000-000000000008',
    '21000000-0000-0000-0000-000000000007',
    '41000000-0000-0000-0000-000000000009',
    'realized_by',
    'Quote issuance capability is realized by preparing quote.'
),
(
    '51000000-0000-0000-0000-000000000009',
    '21000000-0000-0000-0000-000000000008',
    '41000000-0000-0000-0000-000000000010',
    'realized_by',
    'Approve or decline capability is realized by final underwriting decision.'
),
(
    '51000000-0000-0000-0000-000000000010',
    '21000000-0000-0000-0000-000000000009',
    '41000000-0000-0000-0000-000000000011',
    'realized_by',
    'Bind coverage capability is realized by binding accepted coverage.'
)
ON CONFLICT ON CONSTRAINT uq_capability_process DO NOTHING;

-- =========================================================
-- 6. Business Systems / Applications
-- Includes Policy Administration System as a reusable shared system.
-- If Claims already inserted it, this updates/reuses the same record.
-- =========================================================

INSERT INTO business_systems (
    id,
    system_name,
    system_type,
    lifecycle_status,
    owner_team,
    description
)
VALUES
(
    '61000000-0000-0000-0000-000000000001',
    'Underwriting Workbench',
    'Underwriting Platform',
    'active',
    'Underwriting Technology',
    'Primary platform used by underwriters to review submissions, assess risk, manage referrals, and make decisions.'
),
(
    '61000000-0000-0000-0000-000000000002',
    'Broker Submission Portal',
    'Digital Portal',
    'active',
    'Digital Channels',
    'Portal used by brokers and agents to submit new business and renewal applications.'
),
(
    '61000000-0000-0000-0000-000000000003',
    'Rating Engine',
    'Rating System',
    'active',
    'Product and Pricing Technology',
    'System used to calculate premiums, rating factors, discounts, surcharges, taxes, and fees.'
),
(
    '61000000-0000-0000-0000-000000000004',
    'Underwriting Rules Engine',
    'Rules Engine',
    'active',
    'Underwriting Technology',
    'System used to apply eligibility, referral, approval, and decline rules.'
),
(
    '60000000-0000-0000-0000-000000000003',
    'Policy Administration System',
    'Core Policy System',
    'active',
    'Policy Technology',
    'System of record for policies, coverages, limits, endorsements, policy issuance, and policy changes.'
),
(
    '61000000-0000-0000-0000-000000000006',
    'Risk Data Provider Integration',
    'External Data Integration',
    'active',
    'Enterprise Integration',
    'Integration layer used to retrieve external risk, credit, property, vehicle, or business data.'
),
(
    '61000000-0000-0000-0000-000000000007',
    'Underwriting Document Management',
    'Document Management System',
    'active',
    'Enterprise Content Management',
    'Repository for applications, inspections, quotes, underwriting notes, and supporting documents.'
),
(
    '61000000-0000-0000-0000-000000000008',
    'Underwriting Analytics Platform',
    'Analytics System',
    'active',
    'Data and Analytics',
    'Analytics platform used for risk scoring, underwriting performance, referral analysis, and portfolio monitoring.'
)
ON CONFLICT (system_name) DO UPDATE
SET
    system_type = EXCLUDED.system_type,
    lifecycle_status = EXCLUDED.lifecycle_status,
    owner_team = EXCLUDED.owner_team,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 7. Domain to System Mapping
-- Policy Administration System is referenced by name to avoid duplicate ID issues.
-- =========================================================

INSERT INTO domain_systems (
    id,
    domain_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '71000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000001',
    'owns',
    'Underwriting owns the underwriting workbench.'
),
(
    '71000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000002',
    'uses',
    'Underwriting uses broker portal for submission intake.'
),
(
    '71000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000003',
    'uses',
    'Underwriting uses rating engine for pricing.'
),
(
    '71000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000004',
    'uses',
    'Underwriting uses rules engine for eligibility and referral rules.'
),
(
    '71000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'uses',
    'Underwriting uses policy administration system for binding and policy issuance.'
),
(
    '71000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000006',
    'uses',
    'Underwriting uses external risk data integration for risk enrichment.'
),
(
    '71000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000007',
    'uses',
    'Underwriting uses document management for submission and quote documents.'
),
(
    '71000000-0000-0000-0000-000000000008',
    '10000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000008',
    'uses',
    'Underwriting uses analytics platform for risk scoring and portfolio monitoring.'
)
ON CONFLICT ON CONSTRAINT uq_domain_system DO NOTHING;

-- =========================================================
-- 8. Process to System Mapping
-- =========================================================

INSERT INTO process_systems (
    id,
    process_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '81000000-0000-0000-0000-000000000001',
    '41000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000002',
    'supported_by',
    'Submission intake is supported by broker submission portal.'
),
(
    '81000000-0000-0000-0000-000000000002',
    '41000000-0000-0000-0000-000000000003',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'Submission completeness validation is supported by underwriting workbench.'
),
(
    '81000000-0000-0000-0000-000000000003',
    '41000000-0000-0000-0000-000000000004',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'Applicant risk evaluation is supported by underwriting workbench.'
),
(
    '81000000-0000-0000-0000-000000000004',
    '41000000-0000-0000-0000-000000000004',
    '61000000-0000-0000-0000-000000000006',
    'supported_by',
    'Risk evaluation uses external risk data provider integration.'
),
(
    '81000000-0000-0000-0000-000000000005',
    '41000000-0000-0000-0000-000000000005',
    '61000000-0000-0000-0000-000000000008',
    'supported_by',
    'Loss history review is supported by underwriting analytics platform.'
),
(
    '81000000-0000-0000-0000-000000000006',
    '41000000-0000-0000-0000-000000000006',
    '61000000-0000-0000-0000-000000000003',
    'supported_by',
    'Rating calculation is supported by rating engine.'
),
(
    '81000000-0000-0000-0000-000000000007',
    '41000000-0000-0000-0000-000000000007',
    '61000000-0000-0000-0000-000000000004',
    'supported_by',
    'Eligibility rules are supported by underwriting rules engine.'
),
(
    '81000000-0000-0000-0000-000000000008',
    '41000000-0000-0000-0000-000000000008',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'Referral case management is supported by underwriting workbench.'
),
(
    '81000000-0000-0000-0000-000000000009',
    '41000000-0000-0000-0000-000000000009',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'Quote preparation is supported by underwriting workbench.'
),
(
    '81000000-0000-0000-0000-000000000010',
    '41000000-0000-0000-0000-000000000009',
    '61000000-0000-0000-0000-000000000003',
    'supported_by',
    'Quote preparation uses pricing results from rating engine.'
),
(
    '81000000-0000-0000-0000-000000000011',
    '41000000-0000-0000-0000-000000000010',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'Final underwriting decision is recorded in underwriting workbench.'
),
(
    '81000000-0000-0000-0000-000000000012',
    '41000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Coverage binding is supported by policy administration system.'
)
ON CONFLICT ON CONSTRAINT uq_process_system DO NOTHING;

-- =========================================================
-- 9. Capability to System Mapping
-- =========================================================

INSERT INTO capability_systems (
    id,
    capability_id,
    system_id,
    relationship_type,
    criticality,
    notes
)
VALUES
(
    '91000000-0000-0000-0000-000000000001',
    '21000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000002',
    'supported_by',
    'high',
    'Submission intake is highly dependent on the broker submission portal.'
),
(
    '91000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000003',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Risk assessment is primarily supported by the underwriting workbench.'
),
(
    '91000000-0000-0000-0000-000000000003',
    '21000000-0000-0000-0000-000000000003',
    '61000000-0000-0000-0000-000000000006',
    'supported_by',
    'medium',
    'Risk assessment uses external risk data provider integration.'
),
(
    '91000000-0000-0000-0000-000000000004',
    '21000000-0000-0000-0000-000000000004',
    '61000000-0000-0000-0000-000000000003',
    'supported_by',
    'high',
    'Risk pricing is highly dependent on the rating engine.'
),
(
    '91000000-0000-0000-0000-000000000005',
    '21000000-0000-0000-0000-000000000005',
    '61000000-0000-0000-0000-000000000004',
    'supported_by',
    'high',
    'Eligibility and underwriting rules depend on the rules engine.'
),
(
    '91000000-0000-0000-0000-000000000006',
    '21000000-0000-0000-0000-000000000006',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Referral management is supported by underwriting workbench.'
),
(
    '91000000-0000-0000-0000-000000000007',
    '21000000-0000-0000-0000-000000000007',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Quote issuance is supported by underwriting workbench.'
),
(
    '91000000-0000-0000-0000-000000000008',
    '21000000-0000-0000-0000-000000000008',
    '61000000-0000-0000-0000-000000000001',
    'supported_by',
    'high',
    'Underwriting decisioning is recorded in the underwriting workbench.'
),
(
    '91000000-0000-0000-0000-000000000009',
    '21000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Binding coverage depends on the policy administration system.'
)
ON CONFLICT ON CONSTRAINT uq_capability_system DO NOTHING;

-- =========================================================
-- 10. Technology Components
-- Uses technology_name as natural reusable key.
-- =========================================================

INSERT INTO technology_components (
    id,
    technology_name,
    technology_type,
    vendor_name,
    lifecycle_status,
    description
)
VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'PostgreSQL',
    'Database',
    'PostgreSQL Global Development Group',
    'active',
    'Relational database used for transactional or analytical storage.'
),
(
    'a0000000-0000-0000-0000-000000000002',
    'React',
    'Frontend Framework',
    'Meta',
    'active',
    'Frontend library used for web interfaces.'
),
(
    'a0000000-0000-0000-0000-000000000003',
    'Next.js',
    'Web Application Framework',
    'Vercel',
    'active',
    'React framework used for customer and internal web applications.'
),
(
    'a0000000-0000-0000-0000-000000000004',
    'Java',
    'Programming Language',
    'Oracle / OpenJDK',
    'active',
    'Backend language used for enterprise core services.'
),
(
    'a0000000-0000-0000-0000-000000000005',
    'AWS Lambda',
    'Serverless Compute',
    'Amazon Web Services',
    'active',
    'Serverless runtime for event-driven processing.'
),
(
    'a0000000-0000-0000-0000-000000000007',
    'Kafka',
    'Event Streaming',
    'Apache',
    'active',
    'Event streaming platform for integration between systems.'
),
(
    'a0000000-0000-0000-0000-000000000008',
    'REST API Gateway',
    'Integration Technology',
    'Enterprise Platform',
    'active',
    'API gateway used to expose and secure service APIs.'
),
(
    'a0000000-0000-0000-0000-000000000009',
    'OAuth 2.0 / OIDC',
    'Identity and Access Management',
    'Enterprise IAM',
    'active',
    'Authentication and authorization standard for underwriting applications.'
),
(
    'a0000000-0000-0000-0000-000000000010',
    'Decision Rules Engine',
    'Rules Technology',
    'Enterprise Platform',
    'active',
    'Rules technology used to evaluate underwriting eligibility, referral, and decline rules.'
),
(
    'a0000000-0000-0000-0000-000000000011',
    'Machine Learning Risk Scoring',
    'AI / ML Component',
    'Enterprise Data Science',
    'active',
    'Machine learning scoring component used to calculate underwriting risk scores.'
)
ON CONFLICT (technology_name) DO UPDATE
SET
    technology_type = EXCLUDED.technology_type,
    vendor_name = EXCLUDED.vendor_name,
    lifecycle_status = EXCLUDED.lifecycle_status,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 11. System to Technology Mapping
-- =========================================================

INSERT INTO system_technologies (
    id,
    system_id,
    technology_id,
    relationship_type,
    usage_description
)
VALUES
(
    'bb000000-0000-0000-0000-000000000001',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM technology_components WHERE technology_name = 'PostgreSQL'),
    'uses',
    'Underwriting workbench uses PostgreSQL for underwriting case data.'
),
(
    'bb000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM technology_components WHERE technology_name = 'Java'),
    'uses',
    'Underwriting workbench uses Java for backend services.'
),
(
    'bb000000-0000-0000-0000-000000000003',
    '61000000-0000-0000-0000-000000000002',
    (SELECT id FROM technology_components WHERE technology_name = 'React'),
    'uses',
    'Broker portal uses React for frontend.'
),
(
    'bb000000-0000-0000-0000-000000000004',
    '61000000-0000-0000-0000-000000000002',
    (SELECT id FROM technology_components WHERE technology_name = 'Next.js'),
    'uses',
    'Broker portal uses Next.js for web application delivery.'
),
(
    'bb000000-0000-0000-0000-000000000005',
    '61000000-0000-0000-0000-000000000002',
    (SELECT id FROM technology_components WHERE technology_name = 'OAuth 2.0 / OIDC'),
    'uses',
    'Broker portal uses OAuth/OIDC for authentication.'
),
(
    'bb000000-0000-0000-0000-000000000006',
    '61000000-0000-0000-0000-000000000003',
    (SELECT id FROM technology_components WHERE technology_name = 'Java'),
    'uses',
    'Rating engine uses Java for rating services.'
),
(
    'bb000000-0000-0000-0000-000000000007',
    '61000000-0000-0000-0000-000000000004',
    (SELECT id FROM technology_components WHERE technology_name = 'Decision Rules Engine'),
    'uses',
    'Underwriting rules engine uses decision rules technology.'
),
(
    'bb000000-0000-0000-0000-000000000008',
    '61000000-0000-0000-0000-000000000006',
    (SELECT id FROM technology_components WHERE technology_name = 'REST API Gateway'),
    'uses',
    'Risk data integration exposes external data through REST APIs.'
),
(
    'bb000000-0000-0000-0000-000000000009',
    '61000000-0000-0000-0000-000000000008',
    (SELECT id FROM technology_components WHERE technology_name = 'Machine Learning Risk Scoring'),
    'uses',
    'Underwriting analytics platform uses machine learning risk scoring.'
),
(
    'bb000000-0000-0000-0000-000000000010',
    '61000000-0000-0000-0000-000000000008',
    (SELECT id FROM technology_components WHERE technology_name = 'AWS Lambda'),
    'uses',
    'Underwriting analytics platform uses AWS Lambda for scoring jobs.'
)
ON CONFLICT ON CONSTRAINT uq_system_technology DO NOTHING;

-- =========================================================
-- 12. Business Data Entities
-- Includes Policy as a reusable shared data entity.
-- If Claims already inserted Policy, this updates/reuses it.
-- =========================================================

INSERT INTO business_data_entities (
    id,
    entity_name,
    entity_description,
    data_domain
)
VALUES
(
    'cc000000-0000-0000-0000-000000000001',
    'Insurance Submission',
    'Request for insurance quote, renewal, or coverage evaluation.',
    'Underwriting'
),
(
    'cc000000-0000-0000-0000-000000000002',
    'Applicant',
    'Person, business, or organization applying for insurance coverage.',
    'Customer'
),
(
    'cc000000-0000-0000-0000-000000000003',
    'Risk Profile',
    'Collection of underwriting risk attributes and assessment results.',
    'Underwriting'
),
(
    'cc000000-0000-0000-0000-000000000004',
    'Quote',
    'Proposed insurance offer including premium, coverage, limits, deductibles, and conditions.',
    'Underwriting'
),
(
    'cc000000-0000-0000-0000-000000000005',
    'Premium Calculation',
    'Rating result containing calculated premium and pricing adjustments.',
    'Pricing'
),
(
    'cc000000-0000-0000-0000-000000000006',
    'Underwriting Rule',
    'Business rule used to determine eligibility, referral, decline, or approval condition.',
    'Underwriting Rules'
),
(
    'cc000000-0000-0000-0000-000000000007',
    'Underwriting Referral',
    'Case routed for manual underwriting review due to exception, risk, or rule outcome.',
    'Underwriting'
),
(
    'cc000000-0000-0000-0000-000000000008',
    'Underwriting Decision',
    'Final accept, decline, referral, or conditional approval decision.',
    'Underwriting'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Policy',
    'Insurance policy created or updated after binding coverage.',
    'Policy'
),
(
    'cc000000-0000-0000-0000-000000000010',
    'Underwriting Document',
    'Application, inspection, quote, endorsement, note, or document used in underwriting.',
    'Underwriting'
)
ON CONFLICT (entity_name) DO UPDATE
SET
    entity_description = EXCLUDED.entity_description,
    data_domain = EXCLUDED.data_domain,
    updated_at = now();

-- =========================================================
-- 13. System to Data Entity Mapping
-- Policy is referenced by name to avoid duplicate ID issues.
-- =========================================================

INSERT INTO system_data_entities (
    id,
    system_id,
    data_entity_id,
    crud_type,
    notes
)
VALUES
(
    'dd000000-0000-0000-0000-000000000001',
    '61000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Insurance Submission'),
    'create',
    'Broker portal creates insurance submissions.'
),
(
    'dd000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Applicant'),
    'create',
    'Broker portal captures applicant information.'
),
(
    'dd000000-0000-0000-0000-000000000003',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Insurance Submission'),
    'own',
    'Underwriting workbench manages underwriting submissions.'
),
(
    'dd000000-0000-0000-0000-000000000004',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Risk Profile'),
    'own',
    'Underwriting workbench owns risk profile assessment data.'
),
(
    'dd000000-0000-0000-0000-000000000005',
    '61000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Premium Calculation'),
    'own',
    'Rating engine owns premium calculation outputs.'
),
(
    'dd000000-0000-0000-0000-000000000006',
    '61000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Underwriting Rule'),
    'own',
    'Rules engine owns underwriting rules.'
),
(
    'dd000000-0000-0000-0000-000000000007',
    '61000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Underwriting Referral'),
    'create',
    'Rules engine creates referral outcomes when rules require manual review.'
),
(
    'dd000000-0000-0000-0000-000000000008',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Underwriting Decision'),
    'own',
    'Underwriting workbench owns underwriting decision records.'
),
(
    'dd000000-0000-0000-0000-000000000009',
    '61000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Quote'),
    'create',
    'Underwriting workbench creates quote records.'
),
(
    'dd000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy'),
    'own',
    'Policy administration system owns policy records created after binding.'
),
(
    'dd000000-0000-0000-0000-000000000011',
    '61000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Underwriting Document'),
    'own',
    'Underwriting document management owns underwriting document records.'
),
(
    'dd000000-0000-0000-0000-000000000012',
    '61000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Risk Profile'),
    'consume',
    'Underwriting analytics platform consumes risk profile data.'
),
(
    'dd000000-0000-0000-0000-000000000013',
    '61000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_data_entities WHERE entity_name = 'Underwriting Decision'),
    'consume',
    'Underwriting analytics platform consumes underwriting decision data.'
)
ON CONFLICT ON CONSTRAINT uq_system_data_entity_crud DO NOTHING;

COMMIT;
















--policy administration
BEGIN;

-- =========================================================
-- 1. Business Domain: Policy Administration
-- =========================================================

INSERT INTO business_domains (
    id,
    domain_name,
    domain_function,
    description
)
VALUES (
    '10000000-0000-0000-0000-000000000003',
    'Policy Administration',
    'Manage the lifecycle of insurance policies from issuance through servicing, renewal, cancellation, and reinstatement',
    'Business domain responsible for policy issuance, maintenance, endorsements, renewals, cancellations, reinstatements, documents, and policyholder servicing.'
)
ON CONFLICT (domain_name) DO UPDATE
SET
    domain_function = EXCLUDED.domain_function,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 2. Business Capabilities
-- =========================================================

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES (
    '22000000-0000-0000-0000-000000000001',
    'Manage Policy Administration',
    'End-to-end ability to issue, maintain, renew, cancel, reinstate, and service insurance policies.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES
(
    '22000000-0000-0000-0000-000000000002',
    'Issue Policy',
    'Ability to create and issue a policy after coverage has been bound or approved.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000003',
    'Maintain Policy',
    'Ability to maintain active policy records, policyholder details, coverages, limits, and terms.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000004',
    'Manage Endorsements',
    'Ability to process policy endorsements and policy changes.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000005',
    'Manage Renewals',
    'Ability to evaluate, generate, issue, and manage policy renewals.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000006',
    'Manage Cancellations and Reinstatements',
    'Ability to cancel policies, reverse cancellations, and reinstate eligible policies.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000007',
    'Manage Coverage Changes',
    'Ability to add, remove, or update coverages, limits, deductibles, and policy terms.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000008',
    'Generate Policy Documents',
    'Ability to generate, store, and distribute policy documents, declarations, endorsements, and notices.',
    2,
    '22000000-0000-0000-0000-000000000001'
),
(
    '22000000-0000-0000-0000-000000000009',
    'Manage Policyholder Information',
    'Ability to maintain customer and policyholder information associated with a policy.',
    2,
    '22000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

-- =========================================================
-- 3. Domain to Capability Mapping
-- =========================================================

INSERT INTO domain_capabilities (
    id,
    domain_id,
    capability_id,
    relationship_type,
    notes
)
VALUES
(
    '32000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000001',
    'owns',
    'Policy Administration owns the end-to-end policy administration capability.'
),
(
    '32000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000002',
    'owns',
    'Policy Administration owns policy issuance capability.'
),
(
    '32000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000003',
    'owns',
    'Policy Administration owns policy maintenance capability.'
),
(
    '32000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000004',
    'owns',
    'Policy Administration owns endorsement management capability.'
),
(
    '32000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000005',
    'owns',
    'Policy Administration owns renewal management capability.'
),
(
    '32000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000006',
    'owns',
    'Policy Administration owns cancellation and reinstatement capability.'
),
(
    '32000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000007',
    'owns',
    'Policy Administration owns coverage change capability.'
),
(
    '32000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000008',
    'owns',
    'Policy Administration owns policy document generation capability.'
),
(
    '32000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    '22000000-0000-0000-0000-000000000009',
    'owns',
    'Policy Administration owns policyholder information management capability.'
)
ON CONFLICT ON CONSTRAINT uq_domain_capability DO NOTHING;

-- =========================================================
-- 4. Business Processes
-- =========================================================

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES (
    '42000000-0000-0000-0000-000000000001',
    'End-to-End Policy Administration',
    'Overall process from policy issuance through servicing, renewal, cancellation, reinstatement, and policy closure.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES
(
    '42000000-0000-0000-0000-000000000002',
    'Validate Bound Quote',
    'Validate that an approved or bound quote is ready for policy issuance.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000003',
    'Create Policy',
    'Create the policy record, assign policy number, and establish effective dates.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000004',
    'Issue Policy Contract',
    'Issue finalized policy contract, declarations, and related policy documents.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000005',
    'Update Policyholder Details',
    'Update customer and policyholder information associated with the policy.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000006',
    'Process Endorsement',
    'Process policy endorsement request and apply approved changes.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000007',
    'Change Coverage',
    'Add, remove, or update coverages, limits, deductibles, and policy terms.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000008',
    'Generate Policy Documents',
    'Generate policy documents, declarations, endorsements, notices, and correspondence.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000009',
    'Run Renewal',
    'Evaluate policy renewal, generate renewal offer, and prepare renewal documents.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000010',
    'Cancel Policy',
    'Cancel policy due to customer request, non-payment, underwriting decision, or other cancellation reason.',
    2,
    '42000000-0000-0000-0000-000000000001'
),
(
    '42000000-0000-0000-0000-000000000011',
    'Reinstate Policy',
    'Reinstate a cancelled policy when eligibility and business rules allow.',
    2,
    '42000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

-- =========================================================
-- 5. Capability to Process Mapping
-- =========================================================

INSERT INTO capability_processes (
    id,
    capability_id,
    process_id,
    relationship_type,
    notes
)
VALUES
(
    '52000000-0000-0000-0000-000000000001',
    '22000000-0000-0000-0000-000000000002',
    '42000000-0000-0000-0000-000000000002',
    'realized_by',
    'Policy issuance starts by validating the bound quote.'
),
(
    '52000000-0000-0000-0000-000000000002',
    '22000000-0000-0000-0000-000000000002',
    '42000000-0000-0000-0000-000000000003',
    'realized_by',
    'Policy issuance includes creating the policy record.'
),
(
    '52000000-0000-0000-0000-000000000003',
    '22000000-0000-0000-0000-000000000002',
    '42000000-0000-0000-0000-000000000004',
    'realized_by',
    'Policy issuance includes issuing the policy contract.'
),
(
    '52000000-0000-0000-0000-000000000004',
    '22000000-0000-0000-0000-000000000009',
    '42000000-0000-0000-0000-000000000005',
    'realized_by',
    'Policyholder information management is realized by updating policyholder details.'
),
(
    '52000000-0000-0000-0000-000000000005',
    '22000000-0000-0000-0000-000000000004',
    '42000000-0000-0000-0000-000000000006',
    'realized_by',
    'Endorsement management is realized by processing endorsements.'
),
(
    '52000000-0000-0000-0000-000000000006',
    '22000000-0000-0000-0000-000000000007',
    '42000000-0000-0000-0000-000000000007',
    'realized_by',
    'Coverage change capability is realized by changing coverage.'
),
(
    '52000000-0000-0000-0000-000000000007',
    '22000000-0000-0000-0000-000000000008',
    '42000000-0000-0000-0000-000000000008',
    'realized_by',
    'Policy document generation capability is realized by generating policy documents.'
),
(
    '52000000-0000-0000-0000-000000000008',
    '22000000-0000-0000-0000-000000000005',
    '42000000-0000-0000-0000-000000000009',
    'realized_by',
    'Renewal management is realized by running renewals.'
),
(
    '52000000-0000-0000-0000-000000000009',
    '22000000-0000-0000-0000-000000000006',
    '42000000-0000-0000-0000-000000000010',
    'realized_by',
    'Cancellation management is realized by cancelling policies.'
),
(
    '52000000-0000-0000-0000-000000000010',
    '22000000-0000-0000-0000-000000000006',
    '42000000-0000-0000-0000-000000000011',
    'realized_by',
    'Reinstatement management is realized by reinstating policies.'
)
ON CONFLICT ON CONSTRAINT uq_capability_process DO NOTHING;

-- =========================================================
-- 6. Business Systems / Applications
-- Reuses Policy Administration System if it already exists.
-- =========================================================

INSERT INTO business_systems (
    id,
    system_name,
    system_type,
    lifecycle_status,
    owner_team,
    description
)
VALUES
(
    '60000000-0000-0000-0000-000000000003',
    'Policy Administration System',
    'Core Policy System',
    'active',
    'Policy Technology',
    'System of record for policies, coverages, limits, endorsements, policy issuance, renewals, cancellations, and policy changes.'
),
(
    '62000000-0000-0000-0000-000000000002',
    'Customer Self-Service Portal',
    'Digital Portal',
    'active',
    'Digital Channels',
    'Customer-facing portal used to view policies, request changes, download documents, and manage policyholder information.'
),
(
    '62000000-0000-0000-0000-000000000003',
    'Broker Service Portal',
    'Broker Portal',
    'active',
    'Digital Channels',
    'Broker-facing portal used to service policies, submit endorsements, and access policy documents.'
),
(
    '62000000-0000-0000-0000-000000000004',
    'Product Configuration System',
    'Product Management System',
    'active',
    'Product Technology',
    'System used to configure insurance products, coverages, limits, deductibles, and eligibility attributes.'
),
(
    '62000000-0000-0000-0000-000000000005',
    'Document Generation Service',
    'Document Generation System',
    'active',
    'Enterprise Content Management',
    'Service used to generate policy contracts, declarations, endorsements, notices, and renewal documents.'
),
(
    '62000000-0000-0000-0000-000000000006',
    'Enterprise Document Management',
    'Document Management System',
    'active',
    'Enterprise Content Management',
    'Repository for policy documents, endorsements, notices, correspondence, and generated documents.'
),
(
    '62000000-0000-0000-0000-000000000007',
    'Notification Service',
    'Communication Platform',
    'active',
    'Customer Communications',
    'Service used to send policy notices, renewal reminders, cancellation notices, and document availability notifications.'
),
(
    '62000000-0000-0000-0000-000000000008',
    'Policy Data Warehouse',
    'Data Warehouse',
    'active',
    'Enterprise Data',
    'Analytical repository for policy reporting, policy lifecycle metrics, renewal analytics, and portfolio insights.'
)
ON CONFLICT (system_name) DO UPDATE
SET
    system_type = EXCLUDED.system_type,
    lifecycle_status = EXCLUDED.lifecycle_status,
    owner_team = EXCLUDED.owner_team,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 7. Domain to System Mapping
-- =========================================================

INSERT INTO domain_systems (
    id,
    domain_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '72000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'owns',
    'Policy Administration owns the policy administration system.'
),
(
    '72000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'uses',
    'Policy Administration uses customer portal for policy servicing.'
),
(
    '72000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Broker Service Portal'),
    'uses',
    'Policy Administration uses broker service portal for broker-assisted servicing.'
),
(
    '72000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Product Configuration System'),
    'uses',
    'Policy Administration uses product configuration to validate available coverages and products.'
),
(
    '72000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    'uses',
    'Policy Administration uses document generation service for policy documents.'
),
(
    '72000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Enterprise Document Management'),
    'uses',
    'Policy Administration uses document management for policy document storage.'
),
(
    '72000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    'uses',
    'Policy Administration uses notification service for policy communications.'
),
(
    '72000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_domains WHERE domain_name = 'Policy Administration'),
    (SELECT id FROM business_systems WHERE system_name = 'Policy Data Warehouse'),
    'uses',
    'Policy Administration uses policy data warehouse for analytics and reporting.'
)
ON CONFLICT ON CONSTRAINT uq_domain_system DO NOTHING;

-- =========================================================
-- 8. Process to System Mapping
-- =========================================================

INSERT INTO process_systems (
    id,
    process_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '82000000-0000-0000-0000-000000000001',
    '42000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Bound quote validation is supported by policy administration system.'
),
(
    '82000000-0000-0000-0000-000000000002',
    '42000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Policy creation is supported by policy administration system.'
),
(
    '82000000-0000-0000-0000-000000000003',
    '42000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    'supported_by',
    'Policy contract issuance uses document generation service.'
),
(
    '82000000-0000-0000-0000-000000000004',
    '42000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Enterprise Document Management'),
    'supported_by',
    'Issued policy documents are stored in enterprise document management.'
),
(
    '82000000-0000-0000-0000-000000000005',
    '42000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'supported_by',
    'Policyholder updates can be initiated by customers through self-service portal.'
),
(
    '82000000-0000-0000-0000-000000000006',
    '42000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Broker Service Portal'),
    'supported_by',
    'Endorsement requests can be submitted through broker service portal.'
),
(
    '82000000-0000-0000-0000-000000000007',
    '42000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Endorsements are processed in policy administration system.'
),
(
    '82000000-0000-0000-0000-000000000008',
    '42000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Product Configuration System'),
    'supported_by',
    'Coverage changes are validated against product configuration.'
),
(
    '82000000-0000-0000-0000-000000000009',
    '42000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    'supported_by',
    'Policy documents are generated by document generation service.'
),
(
    '82000000-0000-0000-0000-000000000010',
    '42000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Renewals are processed in policy administration system.'
),
(
    '82000000-0000-0000-0000-000000000011',
    '42000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Policy cancellations are processed in policy administration system.'
),
(
    '82000000-0000-0000-0000-000000000012',
    '42000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Policy reinstatements are processed in policy administration system.'
)
ON CONFLICT ON CONSTRAINT uq_process_system DO NOTHING;

-- =========================================================
-- 9. Capability to System Mapping
-- =========================================================

INSERT INTO capability_systems (
    id,
    capability_id,
    system_id,
    relationship_type,
    criticality,
    notes
)
VALUES
(
    '92000000-0000-0000-0000-000000000001',
    '22000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Policy issuance is highly dependent on policy administration system.'
),
(
    '92000000-0000-0000-0000-000000000002',
    '22000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Policy maintenance is primarily supported by policy administration system.'
),
(
    '92000000-0000-0000-0000-000000000003',
    '22000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Endorsement processing is supported by policy administration system.'
),
(
    '92000000-0000-0000-0000-000000000004',
    '22000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Renewal management is supported by policy administration system.'
),
(
    '92000000-0000-0000-0000-000000000005',
    '22000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'high',
    'Cancellation and reinstatement are supported by policy administration system.'
),
(
    '92000000-0000-0000-0000-000000000006',
    '22000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Product Configuration System'),
    'supported_by',
    'medium',
    'Coverage changes depend on product configuration.'
),
(
    '92000000-0000-0000-0000-000000000007',
    '22000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    'supported_by',
    'high',
    'Policy document generation is supported by document generation service.'
),
(
    '92000000-0000-0000-0000-000000000008',
    '22000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Enterprise Document Management'),
    'supported_by',
    'medium',
    'Policy documents are stored in document management.'
),
(
    '92000000-0000-0000-0000-000000000009',
    '22000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'supported_by',
    'medium',
    'Policyholder information can be maintained through customer portal.'
)
ON CONFLICT ON CONSTRAINT uq_capability_system DO NOTHING;

-- =========================================================
-- 10. Technology Components
-- Reuses existing technologies when already loaded.
-- =========================================================

INSERT INTO technology_components (
    id,
    technology_name,
    technology_type,
    vendor_name,
    lifecycle_status,
    description
)
VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'PostgreSQL',
    'Database',
    'PostgreSQL Global Development Group',
    'active',
    'Relational database used for transactional or analytical storage.'
),
(
    'a0000000-0000-0000-0000-000000000002',
    'React',
    'Frontend Framework',
    'Meta',
    'active',
    'Frontend library used for web interfaces.'
),
(
    'a0000000-0000-0000-0000-000000000003',
    'Next.js',
    'Web Application Framework',
    'Vercel',
    'active',
    'React framework used for customer and internal web applications.'
),
(
    'a0000000-0000-0000-0000-000000000004',
    'Java',
    'Programming Language',
    'Oracle / OpenJDK',
    'active',
    'Backend language used for enterprise core services.'
),
(
    'a0000000-0000-0000-0000-000000000005',
    'AWS Lambda',
    'Serverless Compute',
    'Amazon Web Services',
    'active',
    'Serverless runtime for event-driven processing.'
),
(
    'a0000000-0000-0000-0000-000000000006',
    'Amazon S3',
    'Object Storage',
    'Amazon Web Services',
    'active',
    'Object storage for documents and attachments.'
),
(
    'a0000000-0000-0000-0000-000000000007',
    'Kafka',
    'Event Streaming',
    'Apache',
    'active',
    'Event streaming platform for integration between systems.'
),
(
    'a0000000-0000-0000-0000-000000000008',
    'REST API Gateway',
    'Integration Technology',
    'Enterprise Platform',
    'active',
    'API gateway used to expose and secure service APIs.'
),
(
    'a0000000-0000-0000-0000-000000000009',
    'OAuth 2.0 / OIDC',
    'Identity and Access Management',
    'Enterprise IAM',
    'active',
    'Authentication and authorization standard for policy applications.'
),
(
    'a0000000-0000-0000-0000-000000000012',
    'Document Template Engine',
    'Document Generation Technology',
    'Enterprise Platform',
    'active',
    'Template and rules technology used to generate policy documents.'
),
(
    'a0000000-0000-0000-0000-000000000013',
    'Enterprise Messaging Service',
    'Communication Technology',
    'Enterprise Platform',
    'active',
    'Messaging service used for customer notifications, email, SMS, and event-based communications.'
)
ON CONFLICT (technology_name) DO UPDATE
SET
    technology_type = EXCLUDED.technology_type,
    vendor_name = EXCLUDED.vendor_name,
    lifecycle_status = EXCLUDED.lifecycle_status,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 11. System to Technology Mapping
-- =========================================================

INSERT INTO system_technologies (
    id,
    system_id,
    technology_id,
    relationship_type,
    usage_description
)
VALUES
(
    'be000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM technology_components WHERE technology_name = 'PostgreSQL'),
    'uses',
    'Policy administration system uses PostgreSQL for policy transaction data.'
),
(
    'be000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM technology_components WHERE technology_name = 'Java'),
    'uses',
    'Policy administration system uses Java for backend services.'
),
(
    'be000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM technology_components WHERE technology_name = 'Kafka'),
    'uses',
    'Policy administration system publishes and consumes policy lifecycle events.'
),
(
    'be000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'React'),
    'uses',
    'Customer self-service portal uses React for frontend.'
),
(
    'be000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'Next.js'),
    'uses',
    'Customer self-service portal uses Next.js for web delivery.'
),
(
    'be000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'OAuth 2.0 / OIDC'),
    'uses',
    'Customer self-service portal uses OAuth/OIDC for authentication.'
),
(
    'be000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Broker Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'React'),
    'uses',
    'Broker service portal uses React for frontend.'
),
(
    'be000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Broker Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'Next.js'),
    'uses',
    'Broker service portal uses Next.js for web delivery.'
),
(
    'be000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'Document Template Engine'),
    'uses',
    'Document generation service uses document template engine.'
),
(
    'be000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'AWS Lambda'),
    'uses',
    'Document generation service uses AWS Lambda for document generation workloads.'
),
(
    'be000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Enterprise Document Management'),
    (SELECT id FROM technology_components WHERE technology_name = 'Amazon S3'),
    'uses',
    'Enterprise document management uses object storage for policy documents.'
),
(
    'be000000-0000-0000-0000-000000000012',
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'Enterprise Messaging Service'),
    'uses',
    'Notification service uses enterprise messaging service.'
),
(
    'be000000-0000-0000-0000-000000000013',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Data Warehouse'),
    (SELECT id FROM technology_components WHERE technology_name = 'PostgreSQL'),
    'uses',
    'Policy data warehouse uses PostgreSQL-compatible analytical storage in this prototype.'
)
ON CONFLICT ON CONSTRAINT uq_system_technology DO NOTHING;

-- =========================================================
-- 12. Business Data Entities
-- Reuses Policy, Customer, and Quote if they already exist.
-- =========================================================

INSERT INTO business_data_entities (
    id,
    entity_name,
    entity_description,
    data_domain
)
VALUES
(
    'c0000000-0000-0000-0000-000000000002',
    'Policy',
    'Insurance policy representing issued coverage, terms, limits, effective dates, and status.',
    'Policy'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'Customer',
    'Person, organization, policyholder, insured, or customer associated with a policy.',
    'Customer'
),
(
    'cc000000-0000-0000-0000-000000000004',
    'Quote',
    'Proposed insurance offer that may be converted into a policy after binding.',
    'Underwriting'
),
(
    'ce000000-0000-0000-0000-000000000001',
    'Policyholder',
    'Primary person or organization that owns or holds the policy.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000002',
    'Coverage',
    'Coverage component, limit, deductible, or insured risk associated with a policy.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000003',
    'Endorsement',
    'Policy change record that amends coverage, terms, policyholder details, or other policy attributes.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000004',
    'Policy Transaction',
    'Transaction event such as issue, endorse, renew, cancel, reinstate, or change policy.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000005',
    'Renewal',
    'Policy renewal record representing renewal offer, renewal terms, and renewal status.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000006',
    'Cancellation',
    'Policy cancellation record including cancellation reason, effective date, and status.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000007',
    'Policy Document',
    'Generated or uploaded document associated with a policy, endorsement, renewal, or cancellation.',
    'Policy'
),
(
    'ce000000-0000-0000-0000-000000000008',
    'Insurance Product',
    'Insurance product definition including product rules, available coverages, and product attributes.',
    'Product'
),
(
    'ce000000-0000-0000-0000-000000000009',
    'Billing Account',
    'Billing account associated with policy premium, invoices, payments, and billing preferences.',
    'Billing'
)
ON CONFLICT (entity_name) DO UPDATE
SET
    entity_description = EXCLUDED.entity_description,
    data_domain = EXCLUDED.data_domain,
    updated_at = now();

-- =========================================================
-- 13. System to Data Entity Mapping
-- =========================================================

INSERT INTO system_data_entities (
    id,
    system_id,
    data_entity_id,
    crud_type,
    notes
)
VALUES
(
    'de000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy'),
    'own',
    'Policy administration system is the system of record for policies.'
),
(
    'de000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy Transaction'),
    'own',
    'Policy administration system owns policy transaction records.'
),
(
    'de000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Coverage'),
    'own',
    'Policy administration system owns policy coverage records.'
),
(
    'de000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Endorsement'),
    'own',
    'Policy administration system owns endorsement records.'
),
(
    'de000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Renewal'),
    'own',
    'Policy administration system owns renewal records.'
),
(
    'de000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Cancellation'),
    'own',
    'Policy administration system owns cancellation records.'
),
(
    'de000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Customer'),
    'update',
    'Customer portal can update customer and contact information.'
),
(
    'de000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy'),
    'read',
    'Customer portal reads policy information for customer self-service.'
),
(
    'de000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Broker Service Portal'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Endorsement'),
    'create',
    'Broker service portal creates endorsement requests.'
),
(
    'de000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Product Configuration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Insurance Product'),
    'own',
    'Product configuration system owns insurance product definitions.'
),
(
    'de000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Document Generation Service'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy Document'),
    'create',
    'Document generation service creates policy documents.'
),
(
    'de000000-0000-0000-0000-000000000012',
    (SELECT id FROM business_systems WHERE system_name = 'Enterprise Document Management'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy Document'),
    'own',
    'Enterprise document management owns stored policy documents.'
),
(
    'de000000-0000-0000-0000-000000000013',
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy Document'),
    'read',
    'Notification service reads policy document metadata to notify customers.'
),
(
    'de000000-0000-0000-0000-000000000014',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Data Warehouse'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy'),
    'consume',
    'Policy data warehouse consumes policy data for reporting.'
),
(
    'de000000-0000-0000-0000-000000000015',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Data Warehouse'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy Transaction'),
    'consume',
    'Policy data warehouse consumes policy transaction data for lifecycle analytics.'
),
(
    'de000000-0000-0000-0000-000000000016',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Quote'),
    'read',
    'Policy administration system reads bound quote data during policy issuance.'
),
(
    'de000000-0000-0000-0000-000000000017',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Billing Account'),
    'produce',
    'Policy administration system produces billing account initiation events for billing setup.'
)
ON CONFLICT ON CONSTRAINT uq_system_data_entity_crud DO NOTHING;

COMMIT;



















--Billing and Payments
BEGIN;

-- =========================================================
-- 1. Business Domain: Billing and Payments
-- =========================================================

INSERT INTO business_domains (
    id,
    domain_name,
    domain_function,
    description
)
VALUES (
    '10000000-0000-0000-0000-000000000004',
    'Billing and Payments',
    'Manage premium billing, invoicing, payment collection, refunds, adjustments, delinquency, and financial reconciliation',
    'Business domain responsible for billing accounts, invoices, premium charges, payment methods, collections, refunds, adjustments, reconciliation, and financial postings.'
)
ON CONFLICT (domain_name) DO UPDATE
SET
    domain_function = EXCLUDED.domain_function,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 2. Business Capabilities
-- =========================================================

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES (
    '23000000-0000-0000-0000-000000000001',
    'Manage Billing and Payments',
    'End-to-end ability to manage billing accounts, invoices, payments, refunds, adjustments, collections, and financial reconciliation.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

INSERT INTO business_capabilities (
    id,
    capability_name,
    capability_description,
    capability_level,
    parent_capability_id
)
VALUES
(
    '23000000-0000-0000-0000-000000000002',
    'Manage Billing Account',
    'Ability to create and maintain billing accounts, billing preferences, and billing relationships.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000003',
    'Generate Invoice',
    'Ability to generate invoices, statements, premium bills, and billing schedules.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000004',
    'Calculate Premium Billing',
    'Ability to calculate premium charges, taxes, fees, installment amounts, and billing adjustments.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000005',
    'Collect Payment',
    'Ability to collect payments through card, bank transfer, cheque, electronic funds transfer, or other payment methods.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000006',
    'Manage Payment Methods',
    'Ability to store, update, validate, and manage customer payment methods.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000007',
    'Manage Refunds and Adjustments',
    'Ability to issue refunds, reverse payments, and apply billing adjustments or credits.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000008',
    'Manage Delinquency and Collections',
    'Ability to detect overdue balances, send notices, manage grace periods, and support collection actions.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000009',
    'Reconcile Payments',
    'Ability to reconcile received payments with invoices, bank files, payment gateway records, and ledger postings.',
    2,
    '23000000-0000-0000-0000-000000000001'
),
(
    '23000000-0000-0000-0000-000000000010',
    'Post Financial Transactions',
    'Ability to post billing, payment, refund, and adjustment transactions to financial systems.',
    2,
    '23000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    capability_name = EXCLUDED.capability_name,
    capability_description = EXCLUDED.capability_description,
    capability_level = EXCLUDED.capability_level,
    parent_capability_id = EXCLUDED.parent_capability_id,
    updated_at = now();

-- =========================================================
-- 3. Domain to Capability Mapping
-- =========================================================

INSERT INTO domain_capabilities (
    id,
    domain_id,
    capability_id,
    relationship_type,
    notes
)
VALUES
(
    '33000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000001',
    'owns',
    'Billing and Payments owns the end-to-end billing and payments capability.'
),
(
    '33000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000002',
    'owns',
    'Billing and Payments owns billing account management capability.'
),
(
    '33000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000003',
    'owns',
    'Billing and Payments owns invoice generation capability.'
),
(
    '33000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000004',
    'owns',
    'Billing and Payments owns premium billing calculation capability.'
),
(
    '33000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000005',
    'owns',
    'Billing and Payments owns payment collection capability.'
),
(
    '33000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000006',
    'owns',
    'Billing and Payments owns payment method management capability.'
),
(
    '33000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000007',
    'owns',
    'Billing and Payments owns refunds and adjustments capability.'
),
(
    '33000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000008',
    'owns',
    'Billing and Payments owns delinquency and collections capability.'
),
(
    '33000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000009',
    'owns',
    'Billing and Payments owns payment reconciliation capability.'
),
(
    '33000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    '23000000-0000-0000-0000-000000000010',
    'owns',
    'Billing and Payments owns financial transaction posting capability.'
)
ON CONFLICT ON CONSTRAINT uq_domain_capability DO NOTHING;

-- =========================================================
-- 4. Business Processes
-- =========================================================

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES (
    '43000000-0000-0000-0000-000000000001',
    'End-to-End Billing and Payments',
    'Overall process from billing account setup through invoicing, payment collection, refunds, collections, reconciliation, and financial posting.',
    1,
    NULL
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

INSERT INTO business_processes (
    id,
    process_name,
    process_description,
    process_level,
    parent_process_id
)
VALUES
(
    '43000000-0000-0000-0000-000000000002',
    'Create Billing Account',
    'Create a billing account for a customer, policy, or account relationship.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000003',
    'Maintain Billing Preferences',
    'Maintain billing frequency, payment plan, delivery preference, and communication preference.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000004',
    'Calculate Premium Charge',
    'Calculate premium, taxes, fees, installments, discounts, surcharges, and adjustments.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000005',
    'Generate Invoice',
    'Generate customer invoice, statement, or premium bill.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000006',
    'Set Up Payment Method',
    'Capture and validate customer payment method details.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000007',
    'Collect Payment',
    'Collect payment through payment gateway, bank file, cheque processing, or other channels.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000008',
    'Apply Billing Adjustment',
    'Apply billing adjustment, credit, debit, write-off, or correction.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000009',
    'Process Refund',
    'Issue refund or reverse payment when required.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000010',
    'Monitor Delinquency',
    'Identify overdue balances, failed payments, and accounts requiring collection action.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000011',
    'Send Billing Notice',
    'Send invoice notices, payment reminders, overdue notices, and cancellation warning notices.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000012',
    'Reconcile Payment',
    'Reconcile payments against invoices, payment gateway records, bank files, and billing ledger entries.',
    2,
    '43000000-0000-0000-0000-000000000001'
),
(
    '43000000-0000-0000-0000-000000000013',
    'Post to General Ledger',
    'Post billing, payment, adjustment, refund, and receivable transactions to financial systems.',
    2,
    '43000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE
SET
    process_name = EXCLUDED.process_name,
    process_description = EXCLUDED.process_description,
    process_level = EXCLUDED.process_level,
    parent_process_id = EXCLUDED.parent_process_id,
    updated_at = now();

-- =========================================================
-- 5. Capability to Process Mapping
-- =========================================================

INSERT INTO capability_processes (
    id,
    capability_id,
    process_id,
    relationship_type,
    notes
)
VALUES
(
    '53000000-0000-0000-0000-000000000001',
    '23000000-0000-0000-0000-000000000002',
    '43000000-0000-0000-0000-000000000002',
    'realized_by',
    'Billing account management is realized by creating billing accounts.'
),
(
    '53000000-0000-0000-0000-000000000002',
    '23000000-0000-0000-0000-000000000002',
    '43000000-0000-0000-0000-000000000003',
    'realized_by',
    'Billing account management includes maintaining billing preferences.'
),
(
    '53000000-0000-0000-0000-000000000003',
    '23000000-0000-0000-0000-000000000004',
    '43000000-0000-0000-0000-000000000004',
    'realized_by',
    'Premium billing calculation is realized by calculating premium charges.'
),
(
    '53000000-0000-0000-0000-000000000004',
    '23000000-0000-0000-0000-000000000003',
    '43000000-0000-0000-0000-000000000005',
    'realized_by',
    'Invoice generation is realized by generating invoices.'
),
(
    '53000000-0000-0000-0000-000000000005',
    '23000000-0000-0000-0000-000000000006',
    '43000000-0000-0000-0000-000000000006',
    'realized_by',
    'Payment method management is realized by setting up payment methods.'
),
(
    '53000000-0000-0000-0000-000000000006',
    '23000000-0000-0000-0000-000000000005',
    '43000000-0000-0000-0000-000000000007',
    'realized_by',
    'Payment collection is realized by collecting payments.'
),
(
    '53000000-0000-0000-0000-000000000007',
    '23000000-0000-0000-0000-000000000007',
    '43000000-0000-0000-0000-000000000008',
    'realized_by',
    'Refunds and adjustments capability includes billing adjustments.'
),
(
    '53000000-0000-0000-0000-000000000008',
    '23000000-0000-0000-0000-000000000007',
    '43000000-0000-0000-0000-000000000009',
    'realized_by',
    'Refunds and adjustments capability includes processing refunds.'
),
(
    '53000000-0000-0000-0000-000000000009',
    '23000000-0000-0000-0000-000000000008',
    '43000000-0000-0000-0000-000000000010',
    'realized_by',
    'Delinquency and collections capability is realized by monitoring delinquency.'
),
(
    '53000000-0000-0000-0000-000000000010',
    '23000000-0000-0000-0000-000000000008',
    '43000000-0000-0000-0000-000000000011',
    'realized_by',
    'Delinquency and collections capability includes billing notices.'
),
(
    '53000000-0000-0000-0000-000000000011',
    '23000000-0000-0000-0000-000000000009',
    '43000000-0000-0000-0000-000000000012',
    'realized_by',
    'Payment reconciliation is realized by reconciling payments.'
),
(
    '53000000-0000-0000-0000-000000000012',
    '23000000-0000-0000-0000-000000000010',
    '43000000-0000-0000-0000-000000000013',
    'realized_by',
    'Financial transaction posting is realized by posting to general ledger.'
)
ON CONFLICT ON CONSTRAINT uq_capability_process DO NOTHING;

-- =========================================================
-- 6. Business Systems / Applications
-- Reuses shared systems when they already exist.
-- =========================================================

INSERT INTO business_systems (
    id,
    system_name,
    system_type,
    lifecycle_status,
    owner_team,
    description
)
VALUES
(
    '63000000-0000-0000-0000-000000000001',
    'Billing Platform',
    'Billing System',
    'active',
    'Billing Technology',
    'Primary platform used to manage billing accounts, invoices, premium charges, adjustments, payments, refunds, and collections.'
),
(
    '63000000-0000-0000-0000-000000000002',
    'Payment Gateway',
    'Payment Processing System',
    'active',
    'Payments Technology',
    'System used to authorize, capture, refund, and settle electronic payments.'
),
(
    '63000000-0000-0000-0000-000000000003',
    'Invoice Generation Service',
    'Invoice Service',
    'active',
    'Billing Technology',
    'Service used to generate invoices, premium bills, statements, and billing schedules.'
),
(
    '62000000-0000-0000-0000-000000000002',
    'Customer Self-Service Portal',
    'Digital Portal',
    'active',
    'Digital Channels',
    'Customer-facing portal used to view invoices, make payments, manage payment methods, and view billing history.'
),
(
    '60000000-0000-0000-0000-000000000003',
    'Policy Administration System',
    'Core Policy System',
    'active',
    'Policy Technology',
    'System of record for policies, coverages, limits, endorsements, policy issuance, renewals, cancellations, and policy changes.'
),
(
    '62000000-0000-0000-0000-000000000007',
    'Notification Service',
    'Communication Platform',
    'active',
    'Customer Communications',
    'Service used to send invoices, payment reminders, overdue notices, cancellation notices, and payment confirmations.'
),
(
    '63000000-0000-0000-0000-000000000007',
    'General Ledger System',
    'Financial System',
    'active',
    'Finance Technology',
    'System used to record billing, receivable, payment, refund, and adjustment financial postings.'
),
(
    '63000000-0000-0000-0000-000000000008',
    'Banking Integration Service',
    'Banking Integration',
    'active',
    'Enterprise Integration',
    'Integration service used to exchange payment, settlement, bank file, and reconciliation information with financial institutions.'
),
(
    '63000000-0000-0000-0000-000000000009',
    'Billing Data Warehouse',
    'Data Warehouse',
    'active',
    'Enterprise Data',
    'Analytical repository for billing, payment, invoice, delinquency, collections, and receivables reporting.'
)
ON CONFLICT (system_name) DO UPDATE
SET
    system_type = EXCLUDED.system_type,
    lifecycle_status = EXCLUDED.lifecycle_status,
    owner_team = EXCLUDED.owner_team,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 7. Domain to System Mapping
-- =========================================================

INSERT INTO domain_systems (
    id,
    domain_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '73000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'owns',
    'Billing and Payments owns the billing platform.'
),
(
    '73000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'uses',
    'Billing and Payments uses payment gateway for electronic payment processing.'
),
(
    '73000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Invoice Generation Service'),
    'uses',
    'Billing and Payments uses invoice generation service for billing documents.'
),
(
    '73000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'uses',
    'Billing and Payments uses customer portal for invoice viewing and payment self-service.'
),
(
    '73000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'uses',
    'Billing and Payments uses policy administration system for policy and premium context.'
),
(
    '73000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    'uses',
    'Billing and Payments uses notification service for billing communications.'
),
(
    '73000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'General Ledger System'),
    'uses',
    'Billing and Payments uses general ledger system for financial postings.'
),
(
    '73000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Banking Integration Service'),
    'uses',
    'Billing and Payments uses banking integration for bank files, settlement, and reconciliation.'
),
(
    '73000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_domains WHERE domain_name = 'Billing and Payments'),
    (SELECT id FROM business_systems WHERE system_name = 'Billing Data Warehouse'),
    'uses',
    'Billing and Payments uses billing data warehouse for analytics and reporting.'
)
ON CONFLICT ON CONSTRAINT uq_domain_system DO NOTHING;

-- =========================================================
-- 8. Process to System Mapping
-- =========================================================

INSERT INTO process_systems (
    id,
    process_id,
    system_id,
    relationship_type,
    notes
)
VALUES
(
    '83000000-0000-0000-0000-000000000001',
    '43000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'Billing account creation is supported by billing platform.'
),
(
    '83000000-0000-0000-0000-000000000002',
    '43000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'Billing preference maintenance is supported by billing platform.'
),
(
    '83000000-0000-0000-0000-000000000003',
    '43000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'Premium charge calculation is supported by billing platform.'
),
(
    '83000000-0000-0000-0000-000000000004',
    '43000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    'supported_by',
    'Premium charge calculation uses policy and coverage context from policy administration system.'
),
(
    '83000000-0000-0000-0000-000000000005',
    '43000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Invoice Generation Service'),
    'supported_by',
    'Invoice generation is supported by invoice generation service.'
),
(
    '83000000-0000-0000-0000-000000000006',
    '43000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'supported_by',
    'Payment method setup can be initiated through customer self-service portal.'
),
(
    '83000000-0000-0000-0000-000000000007',
    '43000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'supported_by',
    'Payment method setup is tokenized and validated through payment gateway.'
),
(
    '83000000-0000-0000-0000-000000000008',
    '43000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'supported_by',
    'Payment collection is supported by payment gateway.'
),
(
    '83000000-0000-0000-0000-000000000009',
    '43000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'Billing adjustments are managed in billing platform.'
),
(
    '83000000-0000-0000-0000-000000000010',
    '43000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'supported_by',
    'Refunds are processed through payment gateway.'
),
(
    '83000000-0000-0000-0000-000000000011',
    '43000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'Delinquency monitoring is supported by billing platform.'
),
(
    '83000000-0000-0000-0000-000000000012',
    '43000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    'supported_by',
    'Billing notices are sent through notification service.'
),
(
    '83000000-0000-0000-0000-000000000013',
    '43000000-0000-0000-0000-000000000012',
    (SELECT id FROM business_systems WHERE system_name = 'Banking Integration Service'),
    'supported_by',
    'Payment reconciliation uses banking integration service.'
),
(
    '83000000-0000-0000-0000-000000000014',
    '43000000-0000-0000-0000-000000000013',
    (SELECT id FROM business_systems WHERE system_name = 'General Ledger System'),
    'supported_by',
    'General ledger posting is supported by general ledger system.'
)
ON CONFLICT ON CONSTRAINT uq_process_system DO NOTHING;

-- =========================================================
-- 9. Capability to System Mapping
-- =========================================================

INSERT INTO capability_systems (
    id,
    capability_id,
    system_id,
    relationship_type,
    criticality,
    notes
)
VALUES
(
    '93000000-0000-0000-0000-000000000001',
    '23000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'high',
    'Billing account management is highly dependent on billing platform.'
),
(
    '93000000-0000-0000-0000-000000000002',
    '23000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Invoice Generation Service'),
    'supported_by',
    'high',
    'Invoice generation is supported by invoice generation service.'
),
(
    '93000000-0000-0000-0000-000000000003',
    '23000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'high',
    'Premium billing calculation is supported by billing platform.'
),
(
    '93000000-0000-0000-0000-000000000004',
    '23000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'supported_by',
    'high',
    'Payment collection is supported by payment gateway.'
),
(
    '93000000-0000-0000-0000-000000000005',
    '23000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    'supported_by',
    'medium',
    'Payment methods can be managed through customer self-service portal.'
),
(
    '93000000-0000-0000-0000-000000000006',
    '23000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    'supported_by',
    'high',
    'Payment method tokenization and validation are supported by payment gateway.'
),
(
    '93000000-0000-0000-0000-000000000007',
    '23000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'high',
    'Refunds and billing adjustments are managed through billing platform.'
),
(
    '93000000-0000-0000-0000-000000000008',
    '23000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    'supported_by',
    'high',
    'Delinquency and collections monitoring is supported by billing platform.'
),
(
    '93000000-0000-0000-0000-000000000009',
    '23000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Banking Integration Service'),
    'supported_by',
    'medium',
    'Payment reconciliation depends on banking integration service.'
),
(
    '93000000-0000-0000-0000-000000000010',
    '23000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'General Ledger System'),
    'supported_by',
    'high',
    'Financial postings depend on general ledger system.'
)
ON CONFLICT ON CONSTRAINT uq_capability_system DO NOTHING;

-- =========================================================
-- 10. Technology Components
-- Reuses existing technologies when already loaded.
-- =========================================================

INSERT INTO technology_components (
    id,
    technology_name,
    technology_type,
    vendor_name,
    lifecycle_status,
    description
)
VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'PostgreSQL',
    'Database',
    'PostgreSQL Global Development Group',
    'active',
    'Relational database used for transactional or analytical storage.'
),
(
    'a0000000-0000-0000-0000-000000000002',
    'React',
    'Frontend Framework',
    'Meta',
    'active',
    'Frontend library used for web interfaces.'
),
(
    'a0000000-0000-0000-0000-000000000003',
    'Next.js',
    'Web Application Framework',
    'Vercel',
    'active',
    'React framework used for customer and internal web applications.'
),
(
    'a0000000-0000-0000-0000-000000000004',
    'Java',
    'Programming Language',
    'Oracle / OpenJDK',
    'active',
    'Backend language used for enterprise core services.'
),
(
    'a0000000-0000-0000-0000-000000000005',
    'AWS Lambda',
    'Serverless Compute',
    'Amazon Web Services',
    'active',
    'Serverless runtime for event-driven processing.'
),
(
    'a0000000-0000-0000-0000-000000000007',
    'Kafka',
    'Event Streaming',
    'Apache',
    'active',
    'Event streaming platform for integration between systems.'
),
(
    'a0000000-0000-0000-0000-000000000008',
    'REST API Gateway',
    'Integration Technology',
    'Enterprise Platform',
    'active',
    'API gateway used to expose and secure service APIs.'
),
(
    'a0000000-0000-0000-0000-000000000009',
    'OAuth 2.0 / OIDC',
    'Identity and Access Management',
    'Enterprise IAM',
    'active',
    'Authentication and authorization standard for customer and billing applications.'
),
(
    'a0000000-0000-0000-0000-000000000013',
    'Enterprise Messaging Service',
    'Communication Technology',
    'Enterprise Platform',
    'active',
    'Messaging service used for customer notifications, email, SMS, and event-based communications.'
),
(
    'a0000000-0000-0000-0000-000000000014',
    'Payment Tokenization Service',
    'Payment Security Technology',
    'Enterprise Payments',
    'active',
    'Technology used to securely tokenize and store payment method references.'
),
(
    'a0000000-0000-0000-0000-000000000015',
    'Bank File Transfer Service',
    'Financial Integration Technology',
    'Enterprise Integration',
    'active',
    'Technology used to exchange settlement, bank file, and reconciliation files with financial institutions.'
)
ON CONFLICT (technology_name) DO UPDATE
SET
    technology_type = EXCLUDED.technology_type,
    vendor_name = EXCLUDED.vendor_name,
    lifecycle_status = EXCLUDED.lifecycle_status,
    description = EXCLUDED.description,
    updated_at = now();

-- =========================================================
-- 11. System to Technology Mapping
-- =========================================================

INSERT INTO system_technologies (
    id,
    system_id,
    technology_id,
    relationship_type,
    usage_description
)
VALUES
(
    'bf000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM technology_components WHERE technology_name = 'PostgreSQL'),
    'uses',
    'Billing platform uses PostgreSQL for billing account, invoice, payment, and adjustment data.'
),
(
    'bf000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM technology_components WHERE technology_name = 'Java'),
    'uses',
    'Billing platform uses Java for backend billing services.'
),
(
    'bf000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM technology_components WHERE technology_name = 'Kafka'),
    'uses',
    'Billing platform publishes and consumes billing lifecycle events.'
),
(
    'bf000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    (SELECT id FROM technology_components WHERE technology_name = 'Payment Tokenization Service'),
    'uses',
    'Payment gateway uses tokenization for secure payment method handling.'
),
(
    'bf000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    (SELECT id FROM technology_components WHERE technology_name = 'REST API Gateway'),
    'uses',
    'Payment gateway exposes payment APIs through REST API gateway.'
),
(
    'bf000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Invoice Generation Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'AWS Lambda'),
    'uses',
    'Invoice generation service uses serverless compute for invoice generation workloads.'
),
(
    'bf000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'React'),
    'uses',
    'Customer self-service portal uses React for frontend.'
),
(
    'bf000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM technology_components WHERE technology_name = 'Next.js'),
    'uses',
    'Customer self-service portal uses Next.js for web delivery.'
),
(
    'bf000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'Enterprise Messaging Service'),
    'uses',
    'Notification service uses enterprise messaging service for billing communications.'
),
(
    'bf000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Banking Integration Service'),
    (SELECT id FROM technology_components WHERE technology_name = 'Bank File Transfer Service'),
    'uses',
    'Banking integration service uses bank file transfer service for settlement and reconciliation files.'
),
(
    'bf000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Data Warehouse'),
    (SELECT id FROM technology_components WHERE technology_name = 'PostgreSQL'),
    'uses',
    'Billing data warehouse uses PostgreSQL-compatible analytical storage in this prototype.'
)
ON CONFLICT ON CONSTRAINT uq_system_technology DO NOTHING;

-- =========================================================
-- 12. Business Data Entities
-- Reuses shared Policy, Customer, and Billing Account if already loaded.
-- =========================================================

INSERT INTO business_data_entities (
    id,
    entity_name,
    entity_description,
    data_domain
)
VALUES
(
    'ce000000-0000-0000-0000-000000000009',
    'Billing Account',
    'Billing account associated with policy premium, invoices, payments, and billing preferences.',
    'Billing'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Policy',
    'Insurance policy representing issued coverage, terms, limits, effective dates, and status.',
    'Policy'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'Customer',
    'Person, organization, policyholder, insured, or customer associated with a policy or billing account.',
    'Customer'
),
(
    'cf000000-0000-0000-0000-000000000001',
    'Invoice',
    'Invoice, premium bill, or statement issued to a customer or account holder.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000002',
    'Premium Charge',
    'Premium amount, tax, fee, surcharge, discount, or installment charge calculated for billing.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000003',
    'Payment',
    'Payment received against an invoice, billing account, or policy premium.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000004',
    'Payment Method',
    'Customer payment method such as card, bank account, EFT, cheque, or digital wallet reference.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000005',
    'Refund',
    'Refund issued to customer, payer, or other party.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000006',
    'Billing Adjustment',
    'Billing credit, debit, write-off, reversal, correction, or manual adjustment.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000007',
    'Delinquency Case',
    'Record representing overdue billing account, missed payment, failed payment, or collection case.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000008',
    'Payment Reconciliation',
    'Record used to reconcile payments with invoices, bank files, gateway transactions, and ledger entries.',
    'Billing'
),
(
    'cf000000-0000-0000-0000-000000000009',
    'Financial Posting',
    'Financial accounting entry for billing, receivable, payment, refund, adjustment, or revenue posting.',
    'Finance'
)
ON CONFLICT (entity_name) DO UPDATE
SET
    entity_description = EXCLUDED.entity_description,
    data_domain = EXCLUDED.data_domain,
    updated_at = now();

-- =========================================================
-- 13. System to Data Entity Mapping
-- =========================================================

INSERT INTO system_data_entities (
    id,
    system_id,
    data_entity_id,
    crud_type,
    notes
)
VALUES
(
    'df000000-0000-0000-0000-000000000001',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Billing Account'),
    'own',
    'Billing platform owns billing account records.'
),
(
    'df000000-0000-0000-0000-000000000002',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Premium Charge'),
    'own',
    'Billing platform owns premium charge records.'
),
(
    'df000000-0000-0000-0000-000000000003',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Invoice'),
    'own',
    'Billing platform owns invoice records.'
),
(
    'df000000-0000-0000-0000-000000000004',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Billing Adjustment'),
    'own',
    'Billing platform owns billing adjustment records.'
),
(
    'df000000-0000-0000-0000-000000000005',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Platform'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Delinquency Case'),
    'own',
    'Billing platform owns delinquency case records.'
),
(
    'df000000-0000-0000-0000-000000000006',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Payment'),
    'create',
    'Payment gateway creates payment transaction records.'
),
(
    'df000000-0000-0000-0000-000000000007',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Payment Method'),
    'own',
    'Payment gateway owns tokenized payment method references.'
),
(
    'df000000-0000-0000-0000-000000000008',
    (SELECT id FROM business_systems WHERE system_name = 'Payment Gateway'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Refund'),
    'create',
    'Payment gateway creates refund transaction records.'
),
(
    'df000000-0000-0000-0000-000000000009',
    (SELECT id FROM business_systems WHERE system_name = 'Invoice Generation Service'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Invoice'),
    'create',
    'Invoice generation service creates invoice documents and invoice output records.'
),
(
    'df000000-0000-0000-0000-000000000010',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Invoice'),
    'read',
    'Customer self-service portal reads invoices for customer display.'
),
(
    'df000000-0000-0000-0000-000000000011',
    (SELECT id FROM business_systems WHERE system_name = 'Customer Self-Service Portal'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Payment Method'),
    'update',
    'Customer self-service portal allows customers to update payment methods.'
),
(
    'df000000-0000-0000-0000-000000000012',
    (SELECT id FROM business_systems WHERE system_name = 'Policy Administration System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Policy'),
    'read',
    'Billing uses policy data from policy administration system for billing context.'
),
(
    'df000000-0000-0000-0000-000000000013',
    (SELECT id FROM business_systems WHERE system_name = 'Notification Service'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Invoice'),
    'read',
    'Notification service reads invoice metadata to send billing notices.'
),
(
    'df000000-0000-0000-0000-000000000014',
    (SELECT id FROM business_systems WHERE system_name = 'Banking Integration Service'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Payment Reconciliation'),
    'own',
    'Banking integration service owns payment reconciliation records from bank files and settlements.'
),
(
    'df000000-0000-0000-0000-000000000015',
    (SELECT id FROM business_systems WHERE system_name = 'General Ledger System'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Financial Posting'),
    'own',
    'General ledger system owns financial posting records.'
),
(
    'df000000-0000-0000-0000-000000000016',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Data Warehouse'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Billing Account'),
    'consume',
    'Billing data warehouse consumes billing account data for reporting.'
),
(
    'df000000-0000-0000-0000-000000000017',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Data Warehouse'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Invoice'),
    'consume',
    'Billing data warehouse consumes invoice data for reporting.'
),
(
    'df000000-0000-0000-0000-000000000018',
    (SELECT id FROM business_systems WHERE system_name = 'Billing Data Warehouse'),
    (SELECT id FROM business_data_entities WHERE entity_name = 'Payment'),
    'consume',
    'Billing data warehouse consumes payment data for reporting.'
)
ON CONFLICT ON CONSTRAINT uq_system_data_entity_crud DO NOTHING;

COMMIT;













SELECT
    d.domain_name,
    c.capability_name,
    p.process_name,
    s.system_name,
    t.technology_name
FROM business_domains d
JOIN domain_capabilities dc
    ON dc.domain_id = d.id
JOIN business_capabilities c
    ON c.id = dc.capability_id
LEFT JOIN capability_processes cp
    ON cp.capability_id = c.id
LEFT JOIN business_processes p
    ON p.id = cp.process_id
LEFT JOIN process_systems ps
    ON ps.process_id = p.id
LEFT JOIN business_systems s
    ON s.id = ps.system_id
LEFT JOIN system_technologies st
    ON st.system_id = s.id
LEFT JOIN technology_components t
    ON t.id = st.technology_id
WHERE d.domain_name in ('Claims','Underwriting','Policy Administration','Billing and Payments')
ORDER by
	d.domain_name, 
    c.capability_name,
    p.process_name,
    s.system_name,
    t.technology_name;
    
   
   
   
   
   
   
   
   
   
   SELECT
    d.domain_name,

    dc.relationship_type AS domain_to_capability_relationship,
    c.capability_name,

    cp.relationship_type AS capability_to_process_relationship,
    p.process_name,

    ps.relationship_type AS process_to_system_relationship,
    s.system_name,

    st.relationship_type AS system_to_technology_relationship,
    t.technology_name

FROM business_domains d
JOIN domain_capabilities dc
    ON dc.domain_id = d.id
JOIN business_capabilities c
    ON c.id = dc.capability_id

LEFT JOIN capability_processes cp
    ON cp.capability_id = c.id
LEFT JOIN business_processes p
    ON p.id = cp.process_id

LEFT JOIN process_systems ps
    ON ps.process_id = p.id
LEFT JOIN business_systems s
    ON s.id = ps.system_id

LEFT JOIN system_technologies st
    ON st.system_id = s.id
LEFT JOIN technology_components t
    ON t.id = st.technology_id

WHERE d.domain_name IN (
    'Claims',
    'Underwriting',
    'Policy Administration',
    'Billing and Payments'
)
ORDER BY
    d.domain_name,
    c.capability_name,
    p.process_name,
    s.system_name,
    t.technology_name;