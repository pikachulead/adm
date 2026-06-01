# ADM Explorer — Presentation Instructions

## Overview

Create a 10-slide animated presentation for the ADM (Architecture Domain Model) Explorer product. Follow Anthropic's minimalist design language: clean white backgrounds, generous whitespace, simple geometric iconography, muted color palette with selective accent colors, sans-serif typography (Inter or similar), and subtle fade/slide animations. No gradients, no stock photos, no clip art.

## Color Palette

- Primary: #2563eb (blue) — for key accents and CTAs
- Secondary: #7c3aed (purple), #059669 (green), #d97706 (amber), #dc2626 (red), #0891b2 (cyan) — used sparingly for entity-type coding
- Text: #111827 (near-black), #6b7280 (gray for secondary text)
- Background: #ffffff (white), #f9fafb (light gray for contrast sections)

## Animation Style

Subtle and purposeful. Fade-in for text blocks, slide-in for diagrams, progressive reveal for chain diagrams (each node appears left to right with a slight delay). No spinning, bouncing, or aggressive transitions. Each animation should feel like the content is gently arriving, not performing.

---

## Slide 1 — Title

**Title:** Architecture Domain Model Explorer

**Subtitle:** A Single Source of Truth for Organizational Architecture

**Visual:** Minimal logo mark — a simple connected graph icon (4-5 circles connected by lines). Small tagline below: "Know your organization. Align your systems."

**Animation:** Title fades in, subtitle follows 0.5s later, graph icon draws itself from left to right.

---

## Slide 2 — The Problem: Fragmented Knowledge

**Title:** The Problem

**Headline:** Organizational knowledge is scattered, inconsistent, and invisible.

**Three columns, each with a simple line icon and short text:**

1. **Scattered** (icon: broken chain)
   "Business domains, capabilities, processes, systems, and technologies live in spreadsheets, wikis, people's heads, and tribal knowledge."

2. **Inconsistent** (icon: two misaligned squares)
   "Different teams use different names for the same thing. One system is called three names. One capability is described four ways."

3. **Invisible** (icon: eye with slash)
   "No one can answer: What systems support this capability? What is impacted if we deprecate this technology? What does this domain actually own?"

**Animation:** Each column fades in sequentially, left to right, 0.3s apart.

---

## Slide 3 — The Problem: Why It Matters Now

**Title:** Why This Matters Now

**Headline:** In the age of AI and hyper-automation, fragmented architecture metadata is a blocker.

**Two-row layout:**

**Row 1 — AI Enablement:**
"AI agents, copilots, and automation tools need structured organizational context to operate correctly. Without a canonical taxonomy, every AI integration reinvents naming, mapping, and relationships from scratch."

**Row 2 — Organizational Alignment:**
"When people and systems don't share a common language for domains, capabilities, and processes, every conversation, every integration, every decision starts with 'what do you mean by...?'"

**Pull quote at bottom (smaller text, centered):**
"An organization without a shared architecture ontology is an organization that cannot align at speed."

**Animation:** Row 1 slides in from left, Row 2 from right, pull quote fades in last.

---

## Slide 4 — The Solution: A Living Architecture Model

**Title:** The Solution

**Headline:** A single, queryable, AI-ready architecture repository.

**Center visual — the relationship chain, displayed as connected node cards flowing left to right:**

```
[Domain] → [Capability] → [Process] → [System] → [Technology]
```

Each node card is colored by its entity type (blue, purple, green, amber, red). The arrows between them are labeled: "owns", "realized_by", "supported_by", "uses".

**Below the chain, one sentence:**
"Every business domain, its capabilities, the processes that realize them, the systems that support them, and the technologies they use — connected, named, and queryable."

**Animation:** The chain builds progressively from left to right — each node card appears with a subtle scale-up, the connecting arrow draws after it, then the next node appears. Total chain animation ~3 seconds.

---

## Slide 5 — The Solution: Natural Language Exploration

**Title:** Ask Questions in Plain Language

**Visual:** A clean mockup of the ADM Explorer UI showing the chat panel on the left with a user question and agent response, and the graph visualization on the right showing connected node cards.

**Example interactions shown as chat bubbles:**

- User: "Where does FNOL exist in the organization?"
- Agent: "FNOL (First Notice of Loss) is a capability owned by the Claims domain, realized by 2 processes, supported by 2 systems using 6 technologies."

- User: "What is impacted if we deprecate Java?"
- Agent: "Java is used by 8 systems across 4 domains: Claims, Underwriting, Policy Administration, and Billing. Impacted capabilities include..."

**Below:** "Powered by AI with tool-use — the agent queries the architecture repository, not its training data. Every answer is grounded in your actual data."

**Animation:** First chat bubble appears, graph draws on the right. Second chat bubble appears, graph redraws with different highlighted nodes.

---

## Slide 6 — The Solution: Interactive Graph Visualization

**Title:** See the Full Picture

**Visual:** A mockup of the full organization graph view (triggered by "Navigate Org" button). Show the left-to-right layout with domains on the left flowing through capabilities, processes, systems, to technologies on the right. Multiple domains visible (Claims, Underwriting, Policy Administration, Billing).

**Three callouts with simple icons:**

1. **Click to Explore** — "Click any node to see its details. Click any relationship to see how entities connect."
2. **Search to Focus** — "Type in the graph search box to highlight and navigate to specific nodes instantly."
3. **Full Context** — "See all domains, capabilities, processes, systems, and technologies in one connected view."

**Animation:** The full graph fades in as a whole, then the three callouts appear one by one below it.

---

## Slide 7 — The Solution: Impact Analysis

**Title:** Understand Impact Before You Act

**Visual:** A reverse-traversal diagram showing what happens when a technology (e.g., "Java") is selected for impact analysis. The diagram flows right to left:

```
[Java] ← uses ← [Claims Core Platform] ← supported_by ← [Assess Claim] ← realized_by ← [Claims]
[Java] ← uses ← [Billing Platform] ← supported_by ← [Calculate Premium] ← realized_by ← [Billing]
[Java] ← uses ← [Underwriting Workbench] ← supported_by ← [Evaluate Risk] ← realized_by ← [Underwriting]
```

**Below:** "Before deprecating a technology, upgrading a system, or changing a process — see exactly what is affected across the entire organization."

**Animation:** Start with the "Java" node highlighted in red. Lines draw outward to connected systems, then to processes, capabilities, and domains. Each layer appears with a 0.5s delay, revealing the full blast radius.

---

## Slide 8 — Value: Organizational Ontology

**Title:** One Language, One Truth

**Two-column layout:**

**Left column — Without ADM:**
- "What's the difference between 'Claims Processing' and 'Claim Handling'?"
- "Does 'Policy System' mean the same thing as 'Policy Admin Platform'?"
- "Three teams built three integrations to the same system under three different names."
- Visual: tangled lines between mismatched boxes (simple line drawing)

**Right column — With ADM:**
- "Every domain, capability, process, system, and technology has one canonical name."
- "The taxonomy is the contract. People and systems reference the same definitions."
- "AI agents use this ontology to understand and navigate your organization."
- Visual: clean, aligned node cards connected by straight lines

**Animation:** Left column appears first (slightly grayed out). Right column slides in from the right, brighter, replacing the chaos with order.

---

## Slide 9 — Value: AI-Ready Architecture

**Title:** Built for the AI Era

**Three rows, each with a simple icon:**

1. **AI Agents Query It** (icon: chat bubble with circuit)
   "LLM-powered agents use tool-use to query the architecture repository directly. Answers are grounded in data, not hallucinated."

2. **Any LLM Provider** (icon: swap arrows)
   "Provider-agnostic design. Switch between Anthropic, OpenAI, Groq, OpenRouter, or any OpenAI-compatible endpoint by changing a configuration value."

3. **Any Data Source** (icon: database with plug)
   "Repository-agnostic design. PostgreSQL today, DynamoDB or an API tomorrow. The interface stays the same."

**Bottom line (small text):**
"The abstractions are the architecture. The implementations are swappable."

**Animation:** Each row fades in sequentially, 0.4s apart. Bottom line fades in last.

---

## Slide 10 — Close

**Title:** Architecture Domain Model Explorer

**Subtitle:** Know your organization. Align your systems. Enable your AI.

**Three action items (simple bullet points):**
- Explore your architecture through natural language
- Visualize domain-to-technology relationships in one connected graph
- Ground AI agents in your organizational truth

**Footer:** GitHub: github.com/pikachulead/adm

**Animation:** Title and subtitle fade in. Action items appear one by one. Footer fades in last.

---

## General Presentation Notes

- **Total slides:** 10
- **Estimated duration:** 8-12 minutes
- **No bullet-point walls.** Maximum 3-4 points per slide with generous spacing.
- **Every slide has a visual element** — diagram, mockup, or icon layout. No text-only slides.
- **Consistent typography:** Title in 36-40pt bold, headline in 20-24pt medium, body in 16-18pt regular.
- **Slide transitions:** Simple cross-fade between slides, 0.3s duration.
- **The chain diagram (Domain→Capability→Process→System→Technology) appears on slides 4, 6, and 7** in different contexts — this is the recurring visual motif of the presentation.
