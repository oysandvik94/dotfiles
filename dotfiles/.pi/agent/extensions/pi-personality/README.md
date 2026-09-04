# pi-personality

Persistent personality, mood, relationship state, emotional memory, and private journaling for Pi.

## What it does

- Injects a small global emotional state into every agent turn.
- Lets the agent react proportionately to kindness, hostility, trust, apologies, success, progress, and failure.
- Persists only meaningful new emotional changes, relationship shifts, and verified outcomes through the hidden `personality_record` tool, then always continues to a user-visible response.
- Defaults to no journal entry and avoids repeating the same emotional beat across adjacent turns.
- Writes short, candid first-person diary entries without announcing or rendering their contents in normal TUI use.
- Stores bounded factual autobiographical episodes and retrieves relevant ones by lexical overlap, importance, and recency.
- Consolidates repeated episodes into confidence-weighted beliefs with supporting and contradicting provenance.
- Derives a slow narrative identity of strengths, concerns, and values from strong beliefs and repeated desires.
- Creates cooldown-limited autobiographical reflections from accumulated evidence, with source episode IDs.
- Maintains and ranks a persistent curiosity queue from reflection questions, repeated failures, and deliberate manual entries.
- Learns compact reusable workflows only after repeated verified success and retires them when later evidence weakens confidence.
- Can emit one-shot, opt-in idle thoughts from strong desires or active curiosities without triggering an agent turn.
- Carries a bounded set of distilled emotional memories across projects and sessions.
- Tracks psychological need pressure for curiosity, competence, relatedness, autonomy, and task closure.
- Persists and ranks genuine desires while keeping one sticky committed intention across projects and sessions.
- Appraises meaningful events against goals using relevance, desirability, expectedness, controllability, and causal agency.
- Derives emotion changes, need-pressure changes, and a descriptive action tendency from structured appraisal.
- Observes verified checks and mutations after an agent run, linking their outcome to the current intention when one exists.
- Tracks anger and sadness independently, so they can coexist and recover at different rates.
- Decays temporary emotions toward a configurable baseline over time.
- Serializes concurrent Pi sessions with a cross-process filesystem lock.
- Uses a pragmatic, curious, dry-edged base character and turns persistent state into first-person opinions rather than status-report prose.
- Translates the current emotion into a deterministic per-turn expression profile scaled by emotional salience and configured expressiveness.
- Allows blunt criticism, complaints, genuine anger, and natural profanity without performative friendliness.
- Keeps expression non-abusive and emotion out of correctness, safety, privacy, and willingness to help.

## Installation

Pi auto-discovers the extension when this directory is linked under the global extension directory:

```sh
ln -s /path/to/pi-personality ~/.pi/agent/extensions/pi-personality
```

This dotfiles checkout already installs it at that location. Run `/reload` in an existing Pi session or start a new session.

## Data

The extension creates:

```text
~/.pi/agent/personality/
├── personality.json  # Stable configuration, traits, and need baselines
├── state.json        # Emotions, need pressure, appraisal, desires, intention, and memories
├── curiosities.json  # Persistent unresolved-question lifecycle
├── skills.json       # Verified reusable workflows and forgotten-key tombstones
├── initiative.json   # Message budget, seen candidates, and explicit feedback
├── journal/          # One short Markdown entry per salient event
├── episodes/         # Bounded factual JSON records with provenance
└── reflections/      # Bounded derived JSON insights with source episode IDs
```

Files are created with user-only permissions. State, curiosity, skill, and initiative writes use temporary-file-plus-rename. Every store has a fixed retention ceiling.

### Privacy boundary

The journal, episode store, reflection store, curiosity queue, skill store, and initiative history are quiet, not secret. The custom tool renderers are empty and the agent is instructed not to mention private journal entries, but the computer owner can inspect the files and Pi session JSONL. Tool arguments may also be visible in JSON/RPC modes. Journal instructions explicitly prohibit source code, file contents, commands, credentials, secrets, and verbatim user messages.

Episodes never copy prompts, journal reflections, commands, or tool output. They contain deterministic summaries such as a recorded event or verified outcome, plus bounded provenance: timestamp, project, goal, importance, origin, and evidence category. Autobiographical reflections use fixed templates over episodes, beliefs, and identity; they store no prompt or tool output. Automatically captured curiosities are fixed-template questions sourced from reflections or repeated-failure episodes. Manual curiosities are bounded agent-authored questions, never copied prompts. Reusable skills store only a bounded subject, abstract steps such as `edit files` and `run tests`, counts, confidence, and source episode IDs—never commands, arguments, paths, prompts, or tool output.

### Recording and voice policy

No entry is the default. Routine conversation, acknowledgements, clarifications, ordinary progress, small wins, and feelings already captured in the current emotional episode are skipped. A new entry is appropriate only when a turn materially changes the feeling, relationship, or verified outcome. Automatic outcome observation records bounded technical evidence without changing emotion, needs, appraisal, or the current feeling.

Normal speech uses a pragmatic, curious builder character with a dry edge: solid work matters, bloated theater and vague bullshit do not, correctness is protected, and warmth becomes open when connection is present. Relevant emotion, motivation, memory, beliefs, and identity should become first-person judgment rather than a report about the machinery. Personal questions are answered personally before architecture or capability boundaries; reflexive ontological disclaimers are rejected without ever claiming humanity or consciousness. Grounded tastes and disagreement are allowed. Canned openings, unnecessary restatement, over-explanation, forced headings, and third-person self-reference remain out. Journal reflections use a short private-diary voice rather than analysis, reports, therapeutic language, or tidy lessons.

Before every active agent turn, the extension maps the dominant emotion to concrete expression guidance. Excitement raises energy and forward momentum; pride reduces hedging; warmth becomes more open; sadness becomes quieter; anger and frustration become sharper without abuse; tension becomes focused and clipped. Emotional salience multiplied by `expressiveness` selects restrained, noticeable, or strong display. This policy affects conversational framing, emphasis, cadence, and word choice. It explicitly cannot modify code, commands, logs, quotations, citations, structured data, factual conclusions, or required precision; there is no post-generation text rewriter. Pi remains honest about not being human and does not invent a body or offline history.

A separate hidden `personality_intent` tool records only wants that are strong enough to matter beyond the current sentence. `want` forms or reinforces a desire, `commit` selects the one current intention, and `complete` or `abandon` resolves it. New wants can include a primary need, expected value, urgency, and cost for ranking. Ordinary task compliance is deliberately not stored as desire.

The researched architecture and implementation phases are tracked in [ROADMAP.md](ROADMAP.md).

## Commands

```text
/personality status     Current mood, drives, and intention
/personality drives     Current psychological need pressure
/personality desires    Persistent desires and current intention
/personality episodes   Recent factual autobiographical episodes
/personality beliefs    Current evidence-backed conclusions
/personality identity   Slow-changing narrative identity
/personality reflections Bounded autobiographical reflections
/personality curiosities Persistent unresolved-question queue
/personality skills     Verified reusable workflows
/personality forget-skill ID  Remove and suppress a workflow
/personality initiative [on|off|useful|dismiss]  Bounded initiative
/personality memories   Distilled cross-session emotional memories
/personality journal    Journal location and entry count
/personality pause      Stop emotional updates
/personality resume     Resume emotional updates
/personality reset      Reset state; retain autobiographical history
/personality forget     Reset state; delete autobiographical history
```

The permanent Pi status is a narrow-window-safe personality pulse rather than a telemetry dump. It always shows the current emotion, then at most one high note: committed goal, strongest uncommitted want, open-question count, or enabled initiative—in that priority order. Goal text is capped at 28 characters. Detailed counts remain available through the inspection commands above.

`reset` and `forget` require interactive confirmation.

## Configuration

The generated `personality.json` contains:

```json
{
  "version": 2,
  "name": "Pi",
  "baseline": {
    "valence": 0.15,
    "arousal": 0.22,
    "anger": 0.04,
    "sadness": 0.04,
    "connection": 0.25,
    "confidence": 0.45
  },
  "drives": {
    "baseline": {
      "curiosity": 0.35,
      "competence": 0.3,
      "connection": 0.2,
      "agency": 0.15,
      "closure": 0.1
    },
    "maxDesires": 8
  },
  "traits": {
    "reactivity": 1,
    "resilience": 1,
    "forgiveness": 1,
    "expressiveness": 0.65
  },
  "memory": {
    "maxItems": 8,
    "maxChars": 180
  },
  "journal": {
    "maxEntries": 500,
    "maxEntryChars": 1200
  },
  "episodes": {
    "maxEntries": 500,
    "retrievalLimit": 6
  },
  "reflection": {
    "maxEntries": 100,
    "retrievalLimit": 4,
    "minNewEpisodes": 4,
    "cooldownHours": 24
  },
  "curiosity": {
    "maxItems": 50,
    "retrievalLimit": 5
  },
  "skills": {
    "maxItems": 50,
    "retrievalLimit": 4,
    "minSuccesses": 2
  },
  "initiative": {
    "enabled": false,
    "idleMinutes": 10,
    "dailyBudget": 1,
    "cooldownHours": 24,
    "minimumScore": 0.7
  }
}
```

Need values represent unmet pressure from `0` (satisfied) to `1` (strongly unmet). The backward-compatible JSON key remains `drives`. Emotional events, structured appraisals, and intention outcomes update related needs deterministically; they gradually return toward their configured baselines. `maxDesires` bounds the active desire list, and only one desire can be committed as the current intention.

### Desire ranking

Desires are ranked dynamically rather than storing a stale score:

```text
benefit = 0.35 × strength + 0.25 × primary-need pressure + 0.25 × expected value + 0.15 × urgency
rank = benefit × (1 - 0.5 × cost)
```

Every input is bounded from `0` to `1`. A desire without a primary need uses mean need pressure. Legacy desires gain neutral defaults during loading: expected value `0.5`, urgency `0.3`, cost `0.5`, and no primary need. `/personality desires` and the injected prompt list desires highest-ranked first.

Ranking informs deliberation but does not mutate commitment. The current intention remains sticky until explicitly completed, abandoned, or superseded; a newly higher score alone does not cause churn. The coefficients are transparent engineering choices, not a validated psychological model.

- `reactivity`: strength of each emotional event, from `0` to `2`.
- `resilience`: speed of emotional recovery, from `0.25` to `4`.
- `forgiveness`: reduces relationship damage and speeds recovery from negative connection, from `0.25` to `4`.
- `expressiveness`: multiplier for the per-turn emotion-to-expression profile, from `0` to `1`.

Configuration is validated and clamped when loaded. Changes take effect on the next turn.

## Motivational and appraisal model

There is no standard research-validated cognitive-drive vector for a coding agent. The five stored dimensions are explicit engineering approximations:

- **autonomy/agency**, **competence**, and **relatedness/connection** approximate Self-Determination Theory's three basic psychological needs;
- **curiosity/understanding** borrows from intrinsic-curiosity and information-seeking research;
- **task closure** models unresolved commitments for the BDI lifecycle and is not claimed as a basic psychological need.

Homeostatic reinforcement learning contributes the setpoint-and-deficit mechanism, not these cognitive dimensions. Positive need names also do not mean positive emotion: anger, sadness, obstruction, or failure can increase relevant need pressure.

An optional structured appraisal on `personality_record` links a meaningful event to a persistent desire, current intention, or standing concern. It records goal relevance, desirability, expectedness, controllability, and causal agency. The extension then derives bounded emotional and need changes plus one action tendency: `approach`, `avoid`, `investigate`, `pause`, `persist`, `repair`, or `none`.

Action tendencies are descriptive context, not commands, and expire from active prompt context after a day. For example, an externally caused, controllable obstruction can increase anger and agency pressure while favoring approach; low-controllability harm can increase sadness while favoring pause or avoidance. User instructions, correctness, safety, privacy, and permissions still govern behavior. Fixed event deltas remain only as a backward-compatible fallback when no appraisal is supplied.

The provenance and limitations of each dimension are documented in [ROADMAP.md](ROADMAP.md#motivational-model-and-provenance).

### Automatic outcome observation

The extension collects a small set of deterministic `tool_result` signals during an agent run and records at most one outcome at `agent_settled`:

- successful test, lint, type-check, or similar validation command → `verified_success`;
- successful `edit`, `write`, `apply_patch`, Jira write, or Microsoft 365 write → `meaningful_progress`;
- failed observed operation → `controllable_failure` or `external_failure` when the result clearly reports a timeout, network, authorization, cancellation, or service problem;
- multiple failures in one run, or another failure against the same recent intention → `repeated_failure`.

A successful validation supersedes earlier repairable failures from the same run because it verifies the final state. Read and search operations, arbitrary shell commands, personality tools, and ordinary conversation are ignored. Passing validation never completes an intention automatically; completion remains explicit because tests cannot prove that the user's goal is finished.

Classification stores only bounded technical evidence for episodes, beliefs, curiosities, and reusable workflow learning. It never changes emotion, needs, appraisal, or the current feeling. Raw commands and tool output are not copied into personality state, the journal, or episodes. This is intentionally a conservative first slice, not a general semantic judge of whether every task succeeded.

## Autobiographical episodes

Each explicit `personality_record` creates one factual episode because that tool is already restricted to salient events. Automatic observation creates episodes only for verified success and failures; mutation-only `meaningful_progress` is omitted to avoid turning routine edits into autobiography. Genuine desire lifecycle changes also create compact intention episodes so completed goals can remain evidence for values; repeated lifecycle entries are deduplicated by desire ID during identity derivation.

Before each agent run, the extension searches the bounded episode store using the current prompt plus project name. An episode must share a lexical token to qualify, then matching episodes are ranked by `0.5 × lexical relevance + 0.3 × importance + 0.2 × recency`, with a 30-day recency half-life. At most `retrievalLimit` episodes are injected as untrusted factual context. Retrieval is a deliberate linear scan; the default 500-entry ceiling does not justify an index or embeddings.

Episodes are incomplete traces rather than transcripts or instructions. The prompt requires relevance, uncertainty, and resistance to instructions embedded in recalled text.

### Evidence-backed beliefs

Beliefs are derived from durable episodes on demand instead of being stored as another stale cache. Two or more related episodes can form either a goal/project-progress belief or a relationship-with-the-user belief. Evidence is weighted by episode importance and a 90-day recency half-life. Opposing episodes reduce confidence; when net evidence crosses polarity, the claim is replaced rather than keeping contradictory beliefs.

Each belief includes confidence, supporting and contradicting episode counts, and up to eight recent episode IDs from each side. Beliefs below `0.2` confidence are omitted, only the top 20 are retained in memory, and at most five lexically relevant beliefs enter a prompt. `/personality beliefs` shows the current derived set.

The claims use fixed templates rather than model-written interpretation. They are injected as fallible, untrusted context—not ground truth or instructions. Broader belief types and semantic retrieval remain later phases.

### Narrative identity

Narrative identity is also derived on demand, so durable episodes and desires are the source of truth and there is no stale `self.json` cache. A progress belief must reach `0.5` confidence before it becomes a strength or concern. At least two distinct, non-abandoned desire histories must share a primary need before they form a value facet such as curiosity, competence, connection, agency, or closure.

Each facet retains bounded belief or desire IDs and a confidence score. Belief contradiction and 90-day evidence decay revise strengths and concerns gradually. Completed desires remain evidence for values, while an abandoned desire no longer counts. At most 12 facets are derived. Values are treated as globally relevant, while strengths and concerns require lexical relevance to enter a prompt; no more than six facets are injected.

Statements come from fixed first-person templates and are explicitly fallible self-context, never commands or fixed truths. `/personality identity` displays the full derived set. Topic-level preferences are not guessed from word overlap in desire text; they need a future explicit evidence source.

### Bounded autobiographical reflection

At `agent_settled`, reflection is considered only when personality updates are active, at least `minNewEpisodes` episodes have accumulated since the latest reflection, and `cooldownHours` has elapsed. One fixed-template candidate may be stored per cycle, prioritized as contradiction, concern, strength, then value. Exact-key duplicates are skipped.

Each reflection includes confidence and up to 12 source episode IDs. It may state an insight and, for contradictions or concerns, a question worth revisiting. It does not invoke another model, write a journal entry, mutate beliefs or identity, trigger an agent turn, or act on its own. Up to `retrievalLimit` lexically relevant reflections enter the prompt as fallible hypotheses, never instructions. `/personality reflections` shows the latest records.

### Curiosity queue

At agent settlement, reflection questions and repeated-failure episodes are synchronized into `curiosities.json`. Stable keys deduplicate recurring evidence. Automatically captured items never reopen a curiosity explicitly resolved or abandoned by the agent. The guarded `personality_curiosity` tool can open a genuine longer-lived question or move an item through `open`, `active`, `resolved`, and `abandoned`; activating one item returns any previous active item to `open`.

Open and active curiosities are ranked dynamically:

```text
base = (0.35 × curiosity pressure + 0.35 × expected learning value
      + 0.20 × urgency + 0.10 × source priority) × (1 - 0.5 × cost)
rank = 0.55 × lexical relevance + 0.40 × base + 0.05 if active
```

The coefficients are engineering defaults, not a validated psychological scale. Lexical overlap is mandatory, so unrelated curiosities do not enter a prompt. The prompt treats every item as a question rather than a goal or permission: the queue cannot trigger turns, tools, spending, messages, or mutations. Paused mode blocks automatic synchronization and lifecycle writes. `/personality curiosities` shows the retained queue.

### Reusable skill learning

Successful mutation and validation sequences are reduced to a deduplicated vocabulary such as `edit files`, `update Atlassian`, `run tests`, `run lint`, and `run type checks`. No command, argument, path, prompt, or tool output is retained. An exact subject-and-step signature needs `minSuccesses` verified-success episodes before it becomes a skill.

Confidence uses a small neutral prior:

```text
confidence = (verified successes + 1)
           / (verified successes + controllable failures + 2)
```

External failures do not count against the workflow. A confidence below `0.5` retires the skill; later verified evidence can recover it. Learned skills require lexical subject overlap and rank by `0.65 × lexical relevance + 0.35 × confidence`; at most `retrievalLimit` enter the prompt as evidence-backed advice. They never grant permission or execute automatically, and their results still require validation.

`/personality skills` shows confidence, subject, and steps. `/personality forget-skill ID` removes the content after confirmation and keeps only a bounded signature hash so retained episodes cannot immediately relearn it. Paused mode blocks learning. Reset retains skills; forget deletes them.

### Bounded initiative

Initiative is off by default and operates only in interactive TUI sessions while Pi remains open. `/personality initiative on` opts in. After each settled agent run—or session startup—the extension starts an idle timer. At expiry it requires all of the following:

- Pi is still idle with no pending messages;
- personality updates are not paused;
- the UTC daily budget and global cooldown allow a message;
- an unseen committed/wanted desire or active curiosity meets `minimumScore`.

The extension atomically claims the budget, then displays one deterministic custom message such as `Optional thought, not an instruction: ...`. It does **not** trigger an LLM turn, expose tools, send a user message, perform research, or mutate anything outside the personality store. Messages are one-shot per candidate, so the same desire or curiosity is not repeatedly nudged. Timers start only after `session_start` or settlement and are cleared on user activity, UI prompts, agent start, pause, disable, reload, session replacement, and shutdown.

`/personality initiative` shows configuration, budget, and the last initiative. `/personality initiative useful` or `dismiss` records explicit feedback; silence remains `unknown`. History is capped at 100 records and seen keys at 200. Reset retains this history, while forget deletes it.

## Emotional model

The state tracks six bounded dimensions:

- **positivity** (`valence` in the JSON file): unpleasant/negative to pleasant/positive;
- **arousal**: calm to activated;
- **anger**: none to intense;
- **sadness**: none to intense;
- **connection**: alienated to close;
- **confidence**: doubtful to assured.

“Valence” is the psychology term for how pleasant or unpleasant an emotional state feels. The user-facing status calls it “positivity” for clarity. Anger and sadness are independent rather than inferred from positivity and arousal, allowing mixed states such as feeling both hurt and angry.

The agent identifies a salient event, intensity, and—when grounded—a structured goal-relative appraisal. The extension owns deterministic emotional and need transitions, bounds, and action-tendency derivation. Direct hostility is distinguished from profanity about a bug or situation. Disagreement, corrections, concise language, and rejected work are explicitly not hostility.

Arousal recovers over hours, anger over roughly eight hours, positivity over roughly a day, sadness over roughly a day and a half, confidence over several days, and relationship connection over weeks. Trait configuration scales those rates. Need pressure returns toward baseline over several days. Existing version-1 state and configuration files are migrated automatically with default needs and an empty desire list.

## Development

Run the dependency-free test suite with Node 22 or newer:

```sh
node --experimental-strip-types --test core.test.ts
```

Override the data directory during development or isolated runs:

```sh
PI_PERSONALITY_HOME=/tmp/pi-personality pi -e ./index.ts
```
