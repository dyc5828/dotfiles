---
name: naming-pronounceable-acronyms
description: Create pronounceable, purpose-descriptive acronym names for AI agents, robots, assistants, protocols, plugins, frameworks, systems, and other technical constructs with a defined role or mission. Use when the user asks to name, rename, or evaluate one of these things; wants a spoken name whose letters expand into its purpose; asks for a pronounceable acronym or backronym; or wants a name like SUMA (Session Understanding and Memory Agent), GENKO, or ZERO. The spoken form may be a coined non-dictionary name; natural pronunciation is mandatory, but spelling an existing word is not. Do not use for ordinary product or company naming when the user does not want an acronym-style expansion.
---

# Naming Pronounceable Acronyms

Create names that work simultaneously as spoken names and concise purpose definitions. Treat pronunciation as a hard requirement, not a preference. Allow coined names such as GENKO and SUMA; do not require the initials to spell an existing dictionary word.

## Process

1. Distill the thing into three parts: what it acts on, what it does, and what kind of construct it is.
2. Identify useful expansion words from the role description. Favor precise nouns and verbs over impressive-sounding filler.
3. Generate candidate spoken forms and expansions together. The spoken form may be invented. Iterate in both directions: adjust the name to improve the phrase and adjust the phrase to improve the name.
4. Verify every initial in order. Do not omit, reorder, or invent letters.
5. Read each name aloud mentally. Reject anything that is not naturally pronounceable at first glance.
6. Rank the candidates by role fit, naturalness of expansion, memorability, and ease of speech.

## Hard Requirements

- Produce a name-like sequence with an obvious pronunciation, normally 4–7 letters and 2–3 syllables.
- Permit coined, non-dictionary forms. Do not require the name to have an independent lexical meaning.
- Make the expansion accurately describe the thing's role or purpose.
- Keep the expansion reasonably grammatical and natural.
- Ensure the initials exactly spell the name.
- Make the name comfortable to say in direct address: “Ask SUMA” or “GENKO found it.”
- Avoid plain initialisms such as `SRMA`, even when their expansions are accurate.
- Avoid expansions padded with vague words solely to satisfy letters.
- Avoid awkward consonant clusters, ambiguous pronunciation, and names that require spelling instructions.
- Check for distracting meanings, unfortunate sound-alikes, and misleading role implications.

Words such as Agent, Assistant, Automaton, Operator, Oracle, Engine, System, Intelligence, Network, Robot, Protocol, Framework, and Interface may anchor the construct type, but use them only when they fit the actual role.

## Output

Unless the user asks for a different format, provide 6–10 candidates. For each, include:

- the uppercase spoken name;
- its exact expansion;
- a short explanation of the role fit;
- a pronunciation hint only when it adds value.

Then identify the strongest 2–3 options and explain the tradeoff between them. Prefer a smaller set of strong, defensible names over many strained expansions.

If the user supplies a candidate, evaluate its pronunciation, expansion naturalness, role accuracy, memorability, and unintended associations. Repair the expansion or suggest nearby alternatives when useful.

## Reference Pattern

- `SUMA` — Session Understanding and Memory Agent
- `GENKO` — Gemini External Network Knowledge Oracle

SUMA and GENKO are valid because they sound like names and are easy to say, not because they are existing English words. Use them only to understand the pattern. Do not reuse their wording unless it matches the new entity.
