Conversation Summary: APM / TOGAF Business Architecture Data Model Prototype
Role and Objective

The user is building a small prototype tool for business portfolio management / application portfolio management. The tool is intended to manage:

Business domains
Business capabilities
Business processes
Business systems / applications
Technology components
Business data entities
Relationships between business architecture and technology architecture

The conceptual target is similar to TOGAF-style business architecture modeling, where business domains, capabilities, processes, systems, technologies, and data entities are mapped together.

The user is a strong relational data modeler but is less familiar with graph databases. A major part of the conversation explored whether this prototype should use a relational database or a graph database.

Key Architecture Decision

The recommendation was to start with PostgreSQL / relational modeling, not a graph database.

Reasoning:

The expected dataset is small: roughly 10–15 domains and about 5,000 relationship-path rows.
The current relationship paths are predictable and structured.
PostgreSQL handles the required joins very well.
The model can still support graph-like visualizations by generating nodes and edges from relational tables.
A graph database may be useful later if the product needs open-ended traversal, deep dependency analysis, unknown path traversal, circular dependency detection, or knowledge-graph-style exploration.

Recommended architecture:

PostgreSQL = system of record
Application/API layer = relationship views and impact queries
UI = table views + graph visualization
Optional future graph DB = read-only projection if traversal complexity grows
Graph Database Teaching Summary

The user was taught graph database concepts using comparisons to relational modeling.

Graph Database Basics

A graph database stores:

Nodes = entities / records / things
Relationships = explicit connections between nodes

Important clarification:

A graph node is closer to a relational row/record, not the whole table.
A graph relationship is stored as a first-class record, unlike a relational foreign key which implies a relationship.

Example:

(:BusinessDomain)-[:OWNS]->(:BusinessCapability)
(:Capability)-[:REALIZED_BY]->(:BusinessProcess)
(:BusinessProcess)-[:SUPPORTED_BY]->(:BusinessSystem)
(:BusinessSystem)-[:USES]->(:TechnologyComponent)
Difference from Relational Model

In a relational database:

Relationships are represented through foreign keys and bridge tables.
Queries use SQL joins.

In a graph database:

Relationships are stored directly as edges.
Queries traverse paths through relationships.
Key Learning Outcome

The user understood that a relational model can mimic a graph model by storing:

nodes table
relationships table

or, more practically for this prototype, by using entity tables plus bridge/relationship tables.

PostgreSQL Database Setup

The user wanted a new PostgreSQL database named adm.

Command provided:

CREATE DATABASE adm;

Then connect to it:

\c adm

The DDL used UUID primary keys with:

id UUID PRIMARY KEY DEFAULT gen_random_uuid()

So the following extension was needed:

CREATE EXTENSION IF NOT EXISTS pgcrypto;

Reason:

gen_random_uuid()

comes from pgcrypto and automatically generates UUIDs during inserts.

Simplified Relational DDL Model

The initial user-proposed entities were:

BusinessDomains(id, domain_name, domain_function)
Capabilities(id, capability_name)
DomainCapabilities(id, domain_id, capability_id)
Systems(id, system_name, system_type, system_technology)
DomainSystems(id, domain_id, system_id)

This was expanded into a more TOGAF/APM-aligned model.

Core Entity Tables
business_domains
business_capabilities
business_processes
business_systems
technology_components
business_data_entities
Relationship / Bridge Tables
domain_capabilities
capability_processes
domain_systems
process_systems
capability_systems
system_technologies
system_data_entities
Important Relationship Paths
BusinessDomain
  -> BusinessCapability
    -> BusinessProcess
      -> BusinessSystem
        -> TechnologyComponent

and:

BusinessSystem
  -> BusinessDataEntity
Bridge Table Meanings
domain_capabilities     = Domain owns/uses Capability
capability_processes    = Capability realized_by Process
domain_systems          = Domain owns/uses System
process_systems         = Process supported_by System
capability_systems      = Capability supported_by System
system_technologies     = System uses Technology
system_data_entities    = System owns/reads/creates/updates/consumes/produces Data Entity
Relationship Types Used

Examples:

owns
uses
realized_by
supported_by
create
read
update
delete
own
consume
produce
DDL Design Notes

The DDL included:

UUID primary keys
created_at
updated_at
Self-referencing hierarchy on capabilities:
business_capabilities.parent_capability_id
Self-referencing hierarchy on processes:
business_processes.parent_process_id
Unique constraints on core names, for example:
business_systems.system_name UNIQUE
business_data_entities.entity_name UNIQUE
Unique constraints on relationship bridge tables, for example:
UNIQUE (domain_id, system_id, relationship_type)
UNIQUE (capability_id, process_id, relationship_type)
UNIQUE (system_id, technology_id, relationship_type)

These relationship-level unique constraints became important when making DML scripts idempotent.

DML Domains Created

DML insert scripts were created for the following domains:

Claims
Underwriting
Policy Administration
Billing and Payments

Each DML script inserted:

Domain
Capabilities
Domain-to-capability mappings
Processes
Capability-to-process mappings
Systems/applications
Domain-to-system mappings
Process-to-system mappings
Capability-to-system mappings
Technologies
System-to-technology mappings
Business data entities
System-to-data-entity mappings
Claims Domain Insert Summary

The first DML script created the Claims domain.

Claims Capabilities

Examples:

Manage Claims
Capture First Notice of Loss
Validate Coverage
Assess Claim
Manage Reserves
Settle Claim
Manage Claim Documents
Detect Claim Fraud
Close Claim
Claims Processes

Examples:

End-to-End Claims Handling
Submit First Notice of Loss
Create Claim Record
Validate Policy Coverage
Assign Adjuster
Review Loss Details
Estimate Damages
Set Claim Reserve
Approve Settlement
Issue Claim Payment
Investigate Fraud Referral
Close Claim
Claims Systems

Examples:

Claims Core Platform
Customer Claims Portal
Policy Administration System
Claims Document Management
Claims Payment Platform
Fraud Analytics Platform
Vendor Network Portal
Claims Data Warehouse
Claims Technologies

Examples:

PostgreSQL
React
Next.js
Java
AWS Lambda
Amazon S3
Kafka
REST API Gateway
OAuth 2.0 / OIDC
Claims Data Entities

Examples:

Claim
Policy
Customer
Loss Event
Adjuster
Reserve
Claim Payment
Claim Document
Vendor
Fraud Referral
Underwriting Domain Insert Summary

The next domain was Underwriting.

Underwriting Capabilities

Examples:

Manage Underwriting
Receive Insurance Submission
Assess Risk
Rate and Price Risk
Apply Underwriting Rules
Manage Underwriting Referral
Issue Quote
Approve or Decline Risk
Bind Coverage
Underwriting Processes

Examples:

End-to-End Underwriting
Receive Submission
Validate Submission Completeness
Evaluate Applicant Risk
Check Loss History
Run Rating Calculation
Apply Eligibility Rules
Refer Case to Underwriter
Prepare Quote
Approve or Decline Submission
Bind Coverage
Underwriting Systems

Examples:

Underwriting Workbench
Broker Submission Portal
Rating Engine
Underwriting Rules Engine
Policy Administration System
Risk Data Provider Integration
Underwriting Document Management
Underwriting Analytics Platform
Conflict Issue Encountered

The user hit this PostgreSQL error:

ERROR: duplicate key value violates unique constraint "business_systems_system_name_key"
Detail: Key (system_name)=(Policy Administration System) already exists.

Cause:

Policy Administration System was already inserted in the Claims script.
The Underwriting script attempted to insert another row with the same system_name.

Fix:

Reuse the existing Policy Administration System.
Use natural-key conflict handling:
ON CONFLICT (system_name) DO UPDATE

instead of only:

ON CONFLICT (id) DO NOTHING
Second Conflict Issue

The user also hit:

ERROR: duplicate key value violates unique constraint "uq_domain_system"
Detail: Key (domain_id, system_id, relationship_type)=... already exists.

Cause:

The script had partially run before.
A duplicate relationship already existed in a bridge table.

Fix:

Use relationship-level conflict handling:

ON CONFLICT ON CONSTRAINT uq_domain_system DO NOTHING;

Similar fixes were recommended for all bridge tables:

ON CONFLICT ON CONSTRAINT uq_domain_capability DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_capability_process DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_domain_system DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_process_system DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_capability_system DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_system_technology DO NOTHING;
ON CONFLICT ON CONSTRAINT uq_system_data_entity_crud DO NOTHING;
Corrected Underwriting Script

A full drop-in replacement Underwriting DML script was provided with:

Conflict-free inserts
Reuse of Policy Administration System
Reuse of Policy
Subqueries by name where appropriate:
(SELECT id FROM business_systems WHERE system_name = 'Policy Administration System')

and:

(SELECT id FROM business_data_entities WHERE entity_name = 'Policy')
Policy Administration Domain Insert Summary

Next domain created: Policy Administration.

Policy Administration Capabilities

Examples:

Manage Policy Administration
Issue Policy
Maintain Policy
Manage Endorsements
Manage Renewals
Manage Cancellations and Reinstatements
Manage Coverage Changes
Generate Policy Documents
Manage Policyholder Information
Policy Administration Processes

Examples:

End-to-End Policy Administration
Validate Bound Quote
Create Policy
Issue Policy Contract
Update Policyholder Details
Process Endorsement
Change Coverage
Generate Policy Documents
Run Renewal
Cancel Policy
Reinstate Policy
Policy Administration Systems

Examples:

Policy Administration System
Customer Self-Service Portal
Broker Service Portal
Product Configuration System
Document Generation Service
Enterprise Document Management
Notification Service
Policy Data Warehouse
Policy Administration Data Entities

Examples:

Policy
Customer
Quote
Policyholder
Coverage
Endorsement
Policy Transaction
Renewal
Cancellation
Policy Document
Insurance Product
Billing Account

The script reused existing shared entities where available, such as:

Policy
Customer
Quote
Policy Administration System
Billing and Payments Domain Insert Summary

Next domain created: Billing and Payments.

Billing and Payments Capabilities

Examples:

Manage Billing and Payments
Manage Billing Account
Generate Invoice
Calculate Premium Billing
Collect Payment
Manage Payment Methods
Manage Refunds and Adjustments
Manage Delinquency and Collections
Reconcile Payments
Post Financial Transactions
Billing and Payments Processes

Examples:

End-to-End Billing and Payments
Create Billing Account
Maintain Billing Preferences
Calculate Premium Charge
Generate Invoice
Set Up Payment Method
Collect Payment
Apply Billing Adjustment
Process Refund
Monitor Delinquency
Send Billing Notice
Reconcile Payment
Post to General Ledger
Billing and Payments Systems

Examples:

Billing Platform
Payment Gateway
Invoice Generation Service
Customer Self-Service Portal
Policy Administration System
Notification Service
General Ledger System
Banking Integration Service
Billing Data Warehouse
Billing and Payments Technologies

Examples:

PostgreSQL
Java
Kafka
Payment Tokenization Service
REST API Gateway
AWS Lambda
React
Next.js
Enterprise Messaging Service
Bank File Transfer Service
Billing and Payments Data Entities

Examples:

Billing Account
Policy
Customer
Invoice
Premium Charge
Payment
Payment Method
Refund
Billing Adjustment
Delinquency Case
Payment Reconciliation
Financial Posting

The script was made conflict-free by reusing shared systems and entities by name.

Core Query for Viewing Relationship Paths

The user had a useful SQL query that showed architecture relationship paths across domains:

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

This query produced a good table-style view of the data and relationship paths. A sample uploaded query result showed rows across Billing and Payments, Claims, Policy Administration, and Underwriting, including systems and technologies such as Java, Kafka, PostgreSQL, AWS Lambda, Next.js, OAuth/OIDC, and others.

Enhanced Query with Relationship Names

The user then wanted relationship names included in the output.

Enhanced version:

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

A readable path version was also suggested using CONCAT_WS:

CONCAT_WS(
    ' ',
    d.domain_name,
    '--[' || dc.relationship_type || ']-->',
    c.capability_name,
    CASE WHEN cp.relationship_type IS NOT NULL THEN '--[' || cp.relationship_type || ']-->' END,
    p.process_name,
    CASE WHEN ps.relationship_type IS NOT NULL THEN '--[' || ps.relationship_type || ']-->' END,
    s.system_name,
    CASE WHEN st.relationship_type IS NOT NULL THEN '--[' || st.relationship_type || ']-->' END,
    t.technology_name
) AS relationship_path

Example conceptual output:

Domain --[owns]--> Capability --[realized_by]--> Process --[supported_by]--> System --[uses]--> Technology
Graph Database vs Relational Final Decision

The user observed that the query performance was good and expected limited total size.

The recommendation was:

Do not introduce a graph database yet.
Stay with PostgreSQL.

Reason:

The model has fixed, known relationship paths.
Query performance is already good.
Total volume is small.
PostgreSQL can answer the main impact questions well.
Graph visualization can be built from PostgreSQL result sets.
Discussion: “If Java is deprecated, what is impacted?”

The user challenged the earlier claim that this type of query might be hard.

Clarification:

For the current model, this query is not hard in PostgreSQL because the path is known:

Technology -> System -> Process -> Capability -> Domain

SQL query provided:

SELECT DISTINCT
    t.technology_name,

    s.system_name,
    s.system_type,
    s.owner_team AS system_owner_team,

    ps.relationship_type AS process_to_system_relationship,
    p.process_name,

    cp.relationship_type AS capability_to_process_relationship,
    c.capability_name,

    dc.relationship_type AS domain_to_capability_relationship,
    d.domain_name,

    sde.crud_type AS system_data_relationship,
    de.entity_name AS impacted_data_entity

FROM technology_components t
JOIN system_technologies st
    ON st.technology_id = t.id
JOIN business_systems s
    ON s.id = st.system_id

LEFT JOIN process_systems ps
    ON ps.system_id = s.id
LEFT JOIN business_processes p
    ON p.id = ps.process_id

LEFT JOIN capability_processes cp
    ON cp.process_id = p.id
LEFT JOIN business_capabilities c
    ON c.id = cp.capability_id

LEFT JOIN domain_capabilities dc
    ON dc.capability_id = c.id
LEFT JOIN business_domains d
    ON d.id = dc.domain_id

LEFT JOIN system_data_entities sde
    ON sde.system_id = s.id
LEFT JOIN business_data_entities de
    ON de.id = sde.data_entity_id

WHERE t.technology_name = 'Java'

ORDER BY
    d.domain_name,
    c.capability_name,
    p.process_name,
    s.system_name,
    de.entity_name;

This query answers:

Java
  -> impacted systems
  -> system owner/team
  -> impacted processes
  -> impacted capabilities
  -> impacted domains
  -> impacted data entities
When It Would Become Harder in Relational

The query becomes harder only when the question becomes path-agnostic and open-ended, such as:

Start at Java and find every business impact through any relationship,
any number of hops, regardless of path.

Examples of more graph-suitable traversal:

Java -> System -> Data Entity -> Other System -> Other Capability
Java -> System -> Integration -> Downstream System -> Business Process
Java -> System -> Owner -> Organization -> Domain
Java -> System -> Vendor -> Contract -> Risk

That would require recursive CTEs, UNIONs across many relationship tables, path tracking, cycle prevention, and deduplication in SQL.

In graph databases, this style is more natural.

Recommended Next Steps

A future agent should continue from this point by focusing on one or more of the following:

Create PostgreSQL views
domain_capability_process_system_technology_view
technology_impact_view
system_impact_view
capability_system_view
system_data_entity_view
Add owners more formally
Current systems have owner_team.

A better model may add:

business_owners
technology_owners
organization_units
system_owners
capability_owners
Add lifecycle and risk fields

For systems:

lifecycle_status
criticality
technical_health
business_fit
cost_category
risk_rating

For technologies:

lifecycle_status
vendor_support_status
approved_standard_flag
target_state_flag
Add application interfaces / integrations

APM usually needs system-to-system relationships:

system_integrations
source_system_id
target_system_id
integration_type
data_entity_id
interface_technology
frequency
criticality
Add visual graph API

Generate JSON like:

{
  "nodes": [],
  "edges": []
}

Use UI tools such as:

React Flow
Cytoscape.js
D3.js
Sigma.js
Stay relational for now
Use PostgreSQL as the source of truth.
Build graph-style queries/views/API responses.
Only project into Neo4j or another graph database later if open-ended traversal becomes a core product requirement.