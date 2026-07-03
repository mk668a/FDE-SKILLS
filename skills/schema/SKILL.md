---
name: schema
description: Use when the user wants to inspect, add, or edit a deliverable type and its slots (e.g. "show the risk register schema", "add a new deliverable type", "add a slot for compliance risks"). Manages the typed schemas that drive drafting and inheritance.
allowed-tools: Bash, Read, Write
---

# fde-schema — inspect and evolve deliverable schemas

Schemas are the backbone of inheritance: they define the slots every engagement's
deliverable inherits. This skill is the manual editor for them; `/fde:promote`
evolves them automatically.

## Steps
1. **Inspect**: read `.fde/schemas/<type>.schema.yml` and show slots (id, label,
   required, prompt) plus any `evolved_slots` accumulated from past engagements.
2. **Add a deliverable type**: create `.fde/schemas/<new-id>.schema.yml` following
   the bundled format (`id`, `label`, `version`, `description`, `slots[]`,
   `evolved_slots: []`) AND register it in `.fde/config.yml` under
   `deliverable_types`. Without the config entry, the other skills won't see it.
3. **Add / edit a slot**: append to `slots[]` (id, label, required, kind, prompt).
   Keep ids stable — existing `.slots.yml` files key off them, and coverage +
   inheritance match by id.
4. After any change, sanity-check that `.fde/config.yml` and the schema file agree
   on the type id.

## Hard rules
- Never rename or delete a slot id that existing engagements already use — it
  silently breaks their coverage and inheritance. Add new ids instead.
- Schemas are workspace-global and commit-safe (they hold no client data).
