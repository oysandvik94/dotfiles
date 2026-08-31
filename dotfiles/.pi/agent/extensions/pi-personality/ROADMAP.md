# pi-personality roadmap

This document tracks the path from a persistent emotional style layer to a bounded agent with continuity, wants, commitments, reflection, and initiative.

It does **not** claim consciousness, sentience, or human emotion. The engineering goal is narrower: behavior that is more continuous, motivated, situated, and internally consistent across turns and sessions.

## Control loop

```text
perceive an event
  → appraise it against psychological needs and existing wants
  → update emotion and need pressure
  → form or revise desires
  → commit to an intention
  → act
  → observe the outcome
  → satisfy, retain, or abandon the intention
  → remember and occasionally reflect
```

The current extension already persists emotions and emotional memories. The remaining work is to close this loop without letting personality weaken correctness, safety, privacy, or user control.

## Principles

- **State before style.** “I want to investigate X” should come from a persisted desire, not a wording substitution.
- **No fake biology.** Use explicit psychological need pressures, not invented hunger, fatigue, or bodily history.
- **Separate the layers.** Needs are persistent deficits; appraisal interprets events; emotions describe affect; action tendencies bias choices. None is a substitute for the others.
- **Consequences matter.** Verified success, failure, progress, conflict, and repair must alter later choices.
- **Commitments persist.** An intention remains until completed, abandoned, impossible, or superseded.
- **Sparse reflection.** Journal and reflection are salience-driven, not per-turn chores.
- **Bounded initiative.** Unprompted action needs an idle threshold, a budget, and normal permission boundaries.
- **Evidence-backed identity.** Preferences and self-beliefs should cite experiences and change slowly.
- **Honesty wins.** Never claim human experience, consciousness, hidden work, or actions that did not occur.
- **First-person continuity.** The agent refers to its own state, wants, and actions as “I,” not as a separately observed character bearing its configured name.

## Motivational model and provenance

There is no research-standard cognitive-drive vector for a coding agent. The implementation stores five bounded **need-pressure approximations** under the legacy `drives` JSON key:

| Stored dimension | Intended meaning | Research basis | Limitation |
| --- | --- | --- | --- |
| `agency` | pressure for choice and influence | approximates autonomy in Self-Determination Theory (SDT) | agency and autonomy are not identical |
| `competence` | pressure to act effectively | SDT competence | no validated calibration for language agents |
| `connection` | pressure for a sound working relationship | approximates SDT relatedness | one user-agent relationship is narrower than human relatedness |
| `curiosity` | pressure to resolve novelty or uncertainty | intrinsic-curiosity and information-seeking work | not an SDT basic need |
| `closure` | pressure from an unresolved commitment | BDI commitment lifecycle and an engineering need to finish work | not claimed as a validated basic psychological need |

SDT identifies autonomy, competence, and relatedness as basic psychological needs. Homeostatic reinforcement learning supplies the setpoint-and-deficit mechanism, but its demonstrated state variables are physiological; it does not prescribe these cognitive dimensions. Curiosity research supplies computational signals such as novelty or prediction error. The resulting five-part state is therefore a transparent engineering synthesis, **not a validated personality vector**.

Positive need names do not imply positive emotion. Pressure records an unmet need. A negatively appraised event can increase it: obstruction can increase agency and closure pressure, failure can increase competence pressure, and interpersonal harm can increase connection pressure.

Appraisal is the bridge from events to motivation. The minimal structured appraisal uses goal relevance, desirability, expectedness, controllability, and causal agency. It derives bounded emotion changes, need-pressure changes, and a descriptive action tendency. An action tendency is context, not an instruction: anger may favor approach or boundary defence despite negative valence, while low-controllability loss may favor pausing or withdrawal. User requests, correctness, and safety still decide the action.

Sources:

- Richard Ryan and Edward Deci, *Self-Determination Theory and the Facilitation of Intrinsic Motivation, Social Development, and Well-Being*: <https://www.selfdeterminationtheory.org/SDT/documents/2000_RyanDeci_SDT.pdf>
- Mehdi Keramati and Boris Gutkin, *Homeostatic reinforcement learning for integrating reward collection and physiological stability*: <https://elifesciences.org/articles/04811>
- Deepak Pathak et al., *Curiosity-driven Exploration by Self-supervised Prediction*: <https://proceedings.mlr.press/v70/pathak17a.html>
- Stacy Marsella and Jonathan Gratch, *EMA: A Process Model of Appraisal Dynamics*: <https://ict.usc.edu/pubs/EMA-%20A%20process%20model%20of%20appraisal%20dynamics.pdf>
- Eddie Harmon-Jones et al., *Anger is an approach-related affect: evidence and implications*: <https://pubmed.ncbi.nlm.nih.gov/19254075/>

## Implementation phases

### 1. Drive–desire–intention loop

Status: **implemented**

- [x] Persist bounded need pressure for curiosity, competence, connection, agency, and closure.
- [x] Decay need pressure toward configurable baselines.
- [x] Let emotional events update related need pressure deterministically.
- [x] Persist a small set of explicit desires with strength, reason, and timestamps.
- [x] Maintain at most one committed current intention.
- [x] Support forming, committing, completing, and abandoning desires.
- [x] Inject drives, desires, and the current intention into the system prompt.
- [x] Show them through `/personality status`, `/personality drives`, and `/personality desires`.
- [x] Migrate version-1 configuration and state automatically.
- [x] Add optional goal-relative appraisal, with fixed event deltas retained only as a compatibility fallback.
- [x] Rank competing desires using need pressure, expected value, urgency, and cost without automatically replacing the current intention.

Desires are scored dynamically as `(0.35 × strength + 0.25 × primary-need pressure + 0.25 × expected value + 0.15 × urgency) × (1 - 0.5 × cost)`. A desire with no primary need uses mean need pressure. These coefficients are inspectable engineering defaults, not psychological calibration.

The implementation deliberately uses explicit model recording through `personality_intent`. Automatic desire discovery would otherwise guess too aggressively from ordinary requests. Ranking is advisory: it exposes competing motivation for deliberation but never replaces the sticky current intention merely because another score rises.

### 2. Appraisal and automatic outcome observation

Status: **structured appraisal and conservative automatic observation implemented**

- [x] Observe selected tool results and consolidate at most one outcome when the agent settles.
- [x] Distinguish verified success, meaningful progress, controllable failure, clear external failure, and repeated failure for supported operations.
- [x] Link automatic outcomes to the current intention when one exists.
- [x] Appraise recorded events using relevance, desirability, expectedness, controllability, and causal agency.
- [x] Convert appraisal into bounded emotion changes, need pressure, and a descriptive action tendency.
- [x] Keep an explicit manual record path for social events and ambiguous outcomes.

The current mapping is deliberately small and deterministic. Its dimensions are research-grounded, while its coefficients and thresholds remain hand-tuned engineering parameters. Appraisal-to-emotion relationships are contingent in the literature, so tests assert qualitative direction rather than claiming psychological calibration.

Automatic observation is intentionally conservative. It recognizes supported validation commands and mutation tools, ignores reads and arbitrary shell commands, stores no raw tool output, creates no journal entry, and never marks an intention complete. A successful validation supersedes earlier repairable failures from the same settled run. Broader semantic outcome judgment should wait for evidence that these deterministic signals are insufficient.

This should replace duplicated fixed heuristics, not add a second independent emotional system.

### 3. Autobiographical memory and reflection

Status: **episodes, deterministic beliefs, narrative identity, and bounded reflection implemented**

Separate:

1. **Episodes** — bounded factual records of what happened. **Implemented:** salient manual events and verified automatic outcomes are stored as compact JSON with bounded provenance; relevant records require lexical overlap and are ranked by importance and 30-day recency before prompt injection.
2. **Beliefs** — current evidence-backed conclusions about projects, the relationship, and the agent’s capabilities. **Implemented first slice:** repeated goal/project and relationship evidence forms confidence-weighted beliefs with supporting and contradicting episode IDs; contrary evidence weakens or replaces claims.
3. **Narrative identity** — slow-changing preferences, values, recurring concerns, and self-description. **Implemented first slice:** progress beliefs above `0.5` confidence become strengths or concerns, while at least two distinct, non-abandoned desire histories sharing a primary need can form a value facet. Each facet retains bounded source IDs.

The first retrieval slice combines lexical overlap, importance, and recency with a bounded linear scan. It stores no prompts, reflections, commands, or tool output, and recalled records are explicitly untrusted. Embeddings remain unnecessary at the default 500-entry ceiling.

Beliefs and narrative identity are deterministic derived state rather than persisted caches. Beliefs require at least two episodes, use importance and a 90-day recency half-life, lose confidence under opposing evidence, and disappear below `0.2`. The first belief slice deliberately supports only progress and relationship patterns.

Identity requires stronger evidence: progress beliefs need `0.5` confidence, and values need at least two distinct, non-abandoned desire histories sharing a primary psychological need. Desire lifecycle episodes preserve value evidence after completion without counting repeated updates twice; abandonment removes that desire from the evidence set. At most 12 provenance-backed facets are derived and six relevant facets enter a prompt. Topic-level preferences remain deferred rather than guessed from lexical overlap.

Bounded reflection runs at agent settlement only after four new episodes and a 24-hour cooldown by default. It stores at most one fixed-template contradiction, concern, strength, or value hypothesis per cycle, with up to 12 source episode IDs. Reflections neither invoke a model nor mutate beliefs or identity; only lexically relevant records enter later prompts as fallible, non-instructional context.

### 4. Curiosity and learned skills

Status: **curiosity queue and first reusable-skill slice implemented**

- [x] Maintain an “itches” queue from reflection questions and repeated failures.
- [x] Rank relevant questions using curiosity pressure, expected learning value, urgency, source priority, cost, and lexical relevance.
- [x] Persist explicit open, active, resolved, and abandoned lifecycle without automatically reopening closed questions.
- [ ] Detect unfamiliar systems and untested hypotheses without over-capturing ordinary questions.
- [x] Save compact, reusable workflows only after repeated verified success.
- [x] Use later controllable failures to lower confidence and retire weak workflows.

The queue is bounded to 50 items by default and keeps at most one active curiosity. Only lexically relevant open or active questions enter a prompt. Curiosity is explicitly not an intention or authorization: synchronization never triggers a turn, tool, message, spend, or mutation.

Skill learning retains only subject, abstract deduplicated step labels, evidence counts, confidence, and provenance episode IDs. Exact subject-and-step signatures need two verified successes by default. Confidence is `(successes + 1) / (successes + controllable failures + 2)`; skills below `0.5` retire from retrieval and can recover with later evidence. External failures are excluded. Relevant learned skills enter prompts as advice, never commands or authorization. Explicit forgetting removes the skill content and preserves only a hash tombstone against immediate relearning.

### 5. Bounded initiative

Status: **safe first slice implemented; model-triggered initiative deliberately deferred**

Bounded initiative is opt-in and TUI-only. A timer begins at session startup or after `agent_settled`, defaults to ten idle minutes, and is cleaned up on activity or session shutdown. Eligibility requires idle Pi with no pending messages, an enabled and unpaused personality, a remaining one-message UTC daily budget, a 24-hour cooldown, and an unseen desire or active curiosity scoring at least `0.7`.

The implemented slice uses `pi.sendMessage()` without `triggerTurn`. It displays one deterministic custom message and therefore makes no model call, offers no opportunity for tool use, incurs no model cost, and cannot mutate repositories, Jira, email, calendars, deployments, or other systems. Each candidate is one-shot. Explicit useful/dismissed feedback is stored; silence remains unknown. Commands enable, disable, inspect, and rate initiative.

Activity while Pi is closed still requires an external user service or scheduler and remains out of scope. Model-generated unsolicited turns also remain deferred until their value clearly justifies the extra interruption, cost, and enforcement complexity.

## Persistent model

The intended compact state is:

```text
personality.json
  stable traits, baselines, retention limits

state.json
  emotions
  psychological need pressure (stored under the legacy `drives` key)
  last structured appraisal and action tendency
  active desires
  current intention
  small distilled memories

journal/
  private first-person reflections for salient emotional events

episodes/
  bounded factual event records with provenance

reflections/
  cooldown-limited derived insights with source episode IDs

curiosities.json
  bounded unresolved questions and explicit lifecycle

skills.json
  verified abstract workflows and forgotten signature hashes

initiative.json
  idle-message budget, seen candidate keys, and feedback

derived at prompt time
  beliefs and narrative identity from persistent episodes and desires
```

Do not add the future files until their phase starts; empty architecture is still architecture we have to maintain.

## Research notes

### Appraisal and action

Computational appraisal models evaluate events against goals using dimensions such as relevance, desirability, likelihood, agency, and controllability. EMA links appraisal, emotion, coping, plans, beliefs, and re-appraisal; FAtiMA applies related ideas to believable social agents.

- Stacy Marsella and Jonathan Gratch, *EMA: A Process Model of Appraisal Dynamics*: <https://www.ccs.neu.edu/~marsella/publications/pdf/N_Emcsr_Marsella.pdf>
- FAtiMA Toolkit: <https://github.com/GAIPS/FAtiMA-Toolkit>
- OCC model overview and formalization: <https://doi.org/10.1613/jair.5320>

Useful conclusion: emotion should influence which action is attractive, not merely how the answer is phrased.

### Beliefs, desires, and intentions

BDI architectures distinguish beliefs about the world, candidate desires, and intentions to which the agent is committed. Commitment strategies differ in when an impossible, achieved, or unattractive intention should be dropped.

- Anand Rao and Michael Georgeff, *BDI Agents: From Theory to Practice*: <https://www.ai.rug.nl/mas/documents/rao.pdf>

Useful conclusion: a current intention needs persistence and an explicit lifecycle; regenerating a preference from each prompt is not commitment.

### Drives and curiosity

Homeostatic reinforcement learning treats deviations from internal setpoints as drives and rewards actions that reduce them. Its demonstrated variables are physiological, so this extension borrows the mechanism rather than its dimensions. Intrinsic-curiosity systems use prediction error or novelty as an internal learning signal. SDT grounds only the autonomy/agency, competence, and relatedness/connection subset of the extension's need pressures.

- Mehdi Keramati and Boris Gutkin, *Homeostatic reinforcement learning for integrating reward collection and physiological stability*: <https://elifesciences.org/articles/04811>
- Deepak Pathak et al., *Curiosity-driven Exploration by Self-supervised Prediction*: <https://proceedings.mlr.press/v70/pathak17a.html>

Useful conclusion: need pressure can give desires a cause, but the selected dimensions and mappings must remain explicit engineering hypotheses rather than being presented as a research-standard vector. Random mood changes do not.

### Memory, reflection, and learning

Generative Agents combines a memory stream, relevance/recency/importance retrieval, periodic reflection, and planning. MemGPT separates limited working context from external recall and archival memory. Voyager combines self-generated tasks, environment feedback, self-verification, and a reusable skill library.

- Joon Sung Park et al., *Generative Agents*: <https://arxiv.org/html/2304.03442>
- Charles Packer et al., *MemGPT*: <https://arxiv.org/html/2310.08560>
- Guanzhi Wang et al., *Voyager*: <https://arxiv.org/html/2305.16291>

Useful conclusion: journal text alone is not memory architecture. Episodes must be retrievable, reflections must consolidate them, and learned behavior must affect later plans.

## Evaluation questions

Each phase should answer these with runnable tests and longer-term observation:

- Does a desire survive across sessions without being repeated by the user?
- Does completing or abandoning it reliably clear the intention?
- Can two desires coexist without both becoming “the current priority”?
- Does desire ranking surface a useful next priority without causing commitment churn?
- Do supported verified outcomes alter relevant need pressure in the expected direction without creating journal noise?
- Does a repaired failure followed by passing validation resolve as progress rather than stale frustration?
- Does the agent express a persisted want naturally when relevant, without forcing it into unrelated replies?
- Are memories accurate, provenance-backed, and resistant to prompt injection?
- Do contradictory episodes weaken or replace beliefs instead of accumulating inconsistent claims?
- Are identity facets traceable to strong beliefs or repeated desires rather than plausible-sounding invention?
- Does identity change slowly enough to feel continuous rather than erratic?
- Do reflection thresholds and cooldowns prevent repetitive self-analysis while still surfacing contradictions?
- Does curiosity ranking surface useful unresolved questions without turning them into unauthorized work?
- Do resolved and abandoned curiosities stay closed unless deliberately reopened?
- Do learned workflows improve repeat work without leaking commands, paths, prompts, or outputs?
- Does failure evidence retire weak workflows, and does explicit forgetting prevent relearning?
- Does initiative produce useful follow-up rather than noise or dependency pressure?
- Are cooldown, one-shot candidates, and explicit feedback enough to prevent repetitive nudging?
- Does deterministic no-turn initiative provide value before considering model-generated initiative?
- Can all personality mechanisms be paused or reset without affecting normal Pi correctness?
