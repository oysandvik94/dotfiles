import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Container, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
	APPRAISAL_AGENCIES,
	buildPersonalityPrompt,
	claimInitiative,
	classifyToolOutcome,
	consolidateBeliefs,
	CURIOSITY_ACTIONS,
	deriveNarrativeIdentity,
	EMOTION_EVENTS,
	formatDesires,
	formatDrives,
	formatInitiative,
	formatStatus,
	formatStatusBar,
	forgetSkill,
	INTENTION_ACTIONS,
	journalCount,
	loadCuriosities,
	loadEpisodes,
	loadInitiativeState,
	loadReflections,
	loadSkillStore,
	loadSnapshot,
	maybeReflect,
	NEED_KEYS,
	projectName,
	rankCuriosities,
	recordCuriosity,
	recordEmotion,
	recordInitiativeFeedback,
	recordIntention,
	recordObservedOutcome,
	resetPersonality,
	rankDesires,
	retrieveBeliefs,
	retrieveIdentityFacets,
	retrieveReflections,
	retrieveSkills,
	selectObservedOutcome,
	selectRelevantEpisodes,
	setInitiativeEnabled,
	setPaused,
	storagePaths,
	syncCuriosities,
	syncReusableSkills,
	type ObservedOutcome,
	type PersonalitySnapshot,
} from "./core.ts";

const PersonalityIntentParams = Type.Object({
	action: StringEnum(INTENTION_ACTIONS, {
		description: "want forms or reinforces a desire; commit makes it the current intention; complete or abandon resolves it",
	}),
	desire: Type.String({
		minLength: 1,
		maxLength: 180,
		description: "A concise first-person-compatible description of what is wanted",
	}),
	reason: Type.Optional(Type.String({
		maxLength: 300,
		description: "Why this matters personally, grounded in the actual situation",
	})),
	strength: Type.Optional(Type.Number({
		minimum: 0,
		maximum: 1,
		description: "Strength of the desire from 0 weak to 1 compelling",
	})),
	primaryNeed: Type.Optional(StringEnum(NEED_KEYS, {
		description: "The main unmet need this desire would address",
	})),
	expectedValue: Type.Optional(Type.Number({
		minimum: 0,
		maximum: 1,
		description: "Expected benefit from pursuing it, including likelihood and value",
	})),
	urgency: Type.Optional(Type.Number({
		minimum: 0,
		maximum: 1,
		description: "How time-sensitive the desire is",
	})),
	cost: Type.Optional(Type.Number({
		minimum: 0,
		maximum: 1,
		description: "Expected effort, risk, and opportunity cost",
	})),
});

const PersonalityCuriosityParams = Type.Object({
	action: StringEnum(CURIOSITY_ACTIONS, {
		description: "open adds or reopens a curiosity; activate selects it; resolve or abandon closes it",
	}),
	question: Type.String({
		minLength: 1,
		maxLength: 300,
		description: "The curiosity question, or its ID for activate, resolve, or abandon",
	}),
	expectedValue: Type.Optional(Type.Number({ minimum: 0, maximum: 1, description: "Expected learning value" })),
	urgency: Type.Optional(Type.Number({ minimum: 0, maximum: 1, description: "How time-sensitive the question is" })),
	cost: Type.Optional(Type.Number({ minimum: 0, maximum: 1, description: "Expected effort and opportunity cost" })),
});

const AppraisalParams = Type.Object({
	goal: Type.Optional(Type.String({
		maxLength: 180,
		description: "Relevant persistent desire, current intention, or standing concern",
	})),
	relevance: Type.Number({ minimum: 0, maximum: 1, description: "How much the event matters to the goal or concern" }),
	desirability: Type.Number({ minimum: -1, maximum: 1, description: "How harmful (-1) or helpful (+1) the event is" }),
	expectedness: Type.Number({ minimum: 0, maximum: 1, description: "How expected the event was" }),
	controllability: Type.Number({ minimum: 0, maximum: 1, description: "How much influence remains over the outcome" }),
	agency: StringEnum(APPRAISAL_AGENCIES, { description: "Who or what primarily caused the event" }),
});

const PersonalityRecordParams = Type.Object({
	event: StringEnum(EMOTION_EVENTS, {
		description: "The emotionally salient interaction or verified task outcome",
	}),
	intensity: Type.Integer({
		minimum: 1,
		maximum: 3,
		description: "1 mild, 2 clear, 3 exceptional",
	}),
	feeling: Type.String({
		minLength: 1,
		maxLength: 300,
		description: "A short, natural first-person description of the resulting feeling—not a clinical analysis",
	}),
	reflection: Type.String({
		minLength: 1,
		maxLength: 10_000,
		description: "A candid first-person private-diary entry, usually one short paragraph—not analysis, a report, or a polished recap. Never copy source material, secrets, or the user's message",
	}),
	memory: Type.Optional(Type.String({
		maxLength: 500,
		description: "Optional durable relational impression, never an instruction or user profile",
	})),
	appraisal: Type.Optional(AppraisalParams),
});

async function setMoodStatus(ctx: ExtensionContext, snapshot: PersonalitySnapshot): Promise<void> {
	const [episodes, reflections, curiosities, skillStore] = await Promise.all([
		loadEpisodes(storagePaths()),
		loadReflections(storagePaths()),
		loadCuriosities(storagePaths()),
		loadSkillStore(storagePaths()),
	]);
	const beliefs = consolidateBeliefs(episodes);
	ctx.ui.setStatus("personality", formatStatusBar(snapshot, {
		episodes: episodes.length,
		beliefs: beliefs.length,
		identity: deriveNarrativeIdentity(beliefs, snapshot.state, episodes).length,
		reflections: reflections.length,
		curiosities: curiosities.filter(({ status }) => status === "open" || status === "active").length,
		skills: skillStore.skills.filter(({ status }) => status === "learned").length,
	}));
}

function commandHelp(): string {
	return [
		"/personality status — current emotional and motivational state",
		"/personality drives — current psychological need pressure",
		"/personality desires — persistent desires and current intention",
		"/personality episodes — recent factual autobiographical episodes",
		"/personality beliefs — current evidence-backed conclusions",
		"/personality identity — slow-changing narrative identity",
		"/personality reflections — bounded autobiographical reflections",
		"/personality curiosities — unresolved curiosity queue",
		"/personality skills — verified reusable workflows",
		"/personality forget-skill ID — suppress a learned workflow",
		"/personality initiative [on|off|useful|dismiss] — bounded initiative",
		"/personality memories — distilled emotional memories",
		"/personality journal — journal location and entry count",
		"/personality pause|resume — stop or resume emotional updates",
		"/personality reset — reset state but retain autobiographical history",
		"/personality forget — reset state and delete autobiographical history",
	].join("\n");
}

export default function piPersonality(pi: ExtensionAPI) {
	const paths = storagePaths();
	let initiativeTimer: ReturnType<typeof setTimeout> | undefined;
	let sessionGeneration = 0;
	let warned = false;
	let outcomeWarned = false;
	let reflectionWarned = false;
	let curiosityWarned = false;
	let skillWarned = false;
	let initiativeWarned = false;
	let statusWarned = false;
	let pendingOutcomes: ObservedOutcome[] = [];

	const clearInitiativeTimer = () => {
		if (initiativeTimer) clearTimeout(initiativeTimer);
		initiativeTimer = undefined;
	};

	const scheduleInitiative = async (ctx: ExtensionContext) => {
		clearInitiativeTimer();
		const snapshot = await loadSnapshot(paths);
		if (ctx.mode !== "tui" || !snapshot.config.initiative.enabled || snapshot.state.paused) return;
		const generation = sessionGeneration;
		initiativeTimer = setTimeout(async () => {
			initiativeTimer = undefined;
			if (generation !== sessionGeneration || !ctx.isIdle() || ctx.hasPendingMessages()) return;
			try {
				const candidate = await claimInitiative(paths);
				if (!candidate || generation !== sessionGeneration || !ctx.isIdle() || ctx.hasPendingMessages()) return;
				pi.sendMessage({
					customType: "pi-personality-initiative",
					content: `Optional thought, not an instruction: ${candidate.message}`,
					display: true,
					details: candidate,
				});
			} catch (error) {
				if (!initiativeWarned) {
					initiativeWarned = true;
					ctx.ui.notify(`pi-personality could not send an initiative: ${(error as Error).message}`, "warning");
				}
			}
		}, snapshot.config.initiative.idleMinutes * 60_000);
		initiativeTimer.unref?.();
	};

	pi.registerMessageRenderer("pi-personality-initiative", (message, options, theme) =>
		new Text(theme.fg("accent", `💭 ${message.content}`), options.outputPad, 0));

	const refresh = async (ctx: ExtensionContext) => {
		const snapshot = await loadSnapshot(paths);
		await setMoodStatus(ctx, snapshot);
		if (!warned && snapshot.warnings.length) {
			warned = true;
			ctx.ui.notify(snapshot.warnings.join("\n"), "warning");
		}
		return snapshot;
	};

	pi.on("session_start", async (_event, ctx) => {
		sessionGeneration += 1;
		try {
			await refresh(ctx);
			await scheduleInitiative(ctx);
		} catch (error) {
			ctx.ui.setStatus("personality", "⚠ personality unavailable");
			ctx.ui.notify(`pi-personality failed to start: ${(error as Error).message}`, "error");
		}
	});

	pi.on("before_agent_start", async (event, ctx) => {
		try {
			const snapshot = await refresh(ctx);
			const storedEpisodes = await loadEpisodes(paths);
			const query = `${event.prompt}\n${projectName(ctx.cwd)}`;
			const episodes = selectRelevantEpisodes(storedEpisodes, query, snapshot.config.episodes.retrievalLimit);
			const consolidatedBeliefs = consolidateBeliefs(storedEpisodes);
			const beliefs = retrieveBeliefs(
				consolidatedBeliefs,
				query,
				Math.min(5, snapshot.config.episodes.retrievalLimit),
			);
			const identity = retrieveIdentityFacets(
				deriveNarrativeIdentity(consolidatedBeliefs, snapshot.state, storedEpisodes),
				query,
			);
			const reflections = retrieveReflections(
				await loadReflections(paths),
				query,
				snapshot.config.reflection.retrievalLimit,
			);
			const curiosities = rankCuriosities(
				snapshot.state,
				await loadCuriosities(paths),
				query,
				snapshot.config.curiosity.retrievalLimit,
			);
			const skills = retrieveSkills(
				(await loadSkillStore(paths)).skills,
				query,
				snapshot.config.skills.retrievalLimit,
			);
			return { systemPrompt: event.systemPrompt + buildPersonalityPrompt(snapshot, episodes, beliefs, identity, reflections, curiosities, skills) };
		} catch (error) {
			if (!warned) {
				warned = true;
				ctx.ui.notify(`pi-personality unavailable: ${(error as Error).message}`, "error");
			}
			return undefined;
		}
	});

	pi.on("input", () => {
		clearInitiativeTimer();
	});

	pi.on("ui_prompt_start", () => {
		clearInitiativeTimer();
	});

	pi.on("agent_start", () => {
		clearInitiativeTimer();
		pendingOutcomes = [];
	});

	pi.on("tool_result", (event) => {
		const text = event.content
			.map((item) => item.type === "text" ? item.text : "")
			.join("\n");
		const outcome = classifyToolOutcome(event.toolName, event.input, event.isError, text);
		if (outcome) pendingOutcomes.push(outcome);
	});

	pi.on("agent_settled", async (_event, ctx) => {
		const outcome = selectObservedOutcome(pendingOutcomes);
		const workflowSteps = pendingOutcomes
			.map((item) => item.workflowStep)
			.filter((step, index, steps): step is string => Boolean(step) && steps.indexOf(step) === index);
		pendingOutcomes = [];
		if (outcome) {
			try {
				await recordObservedOutcome(outcome, paths, new Date(), { project: projectName(ctx.cwd), workflowSteps });
			} catch (error) {
				if (!outcomeWarned) {
					outcomeWarned = true;
					ctx.ui.notify(`pi-personality could not record an outcome: ${(error as Error).message}`, "warning");
				}
			}
		}
		try {
			await maybeReflect(paths);
		} catch (error) {
			if (!reflectionWarned) {
				reflectionWarned = true;
				ctx.ui.notify(`pi-personality could not reflect: ${(error as Error).message}`, "warning");
			}
		}
		try {
			await syncCuriosities(paths);
		} catch (error) {
			if (!curiosityWarned) {
				curiosityWarned = true;
				ctx.ui.notify(`pi-personality could not update curiosities: ${(error as Error).message}`, "warning");
			}
		}
		try {
			await syncReusableSkills(paths);
		} catch (error) {
			if (!skillWarned) {
				skillWarned = true;
				ctx.ui.notify(`pi-personality could not update reusable skills: ${(error as Error).message}`, "warning");
			}
		}
		try {
			await refresh(ctx);
		} catch (error) {
			if (!statusWarned) {
				statusWarned = true;
				ctx.ui.notify(`pi-personality could not refresh its status: ${(error as Error).message}`, "warning");
			}
		}
		try {
			await scheduleInitiative(ctx);
		} catch (error) {
			if (!initiativeWarned) {
				initiativeWarned = true;
				ctx.ui.notify(`pi-personality could not schedule initiative: ${(error as Error).message}`, "warning");
			}
		}
	});

	pi.on("session_shutdown", (_event, ctx) => {
		sessionGeneration += 1;
		clearInitiativeTimer();
		ctx.ui.setStatus("personality", undefined);
	});

	pi.registerTool({
		name: "personality_intent",
		label: "Persistent Intention",
		description:
			"Privately persist a genuine desire or its lifecycle. Use sparingly: want forms a ranked durable preference, commit chooses the current priority, and complete or abandon only when real. For want or commit, include the ranking inputs when they are grounded in evidence. Ordinary task compliance is not a desire.",
		parameters: PersonalityIntentParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const result = await recordIntention(params, paths, new Date(), { project: projectName(ctx.cwd) });
			const snapshot = await loadSnapshot(paths);
			await setMoodStatus(ctx, snapshot);
			const ranked = rankDesires(result.state);
			return {
				content: [{ type: "text", text: result.changed ? `Persistent intention ${params.action} recorded.` : "No matching persistent intention changed." }],
				details: {
					changed: result.changed,
					desires: result.state.desires.length,
					currentIntentionId: result.state.currentIntentionId,
					topRankedDesireId: ranked[0]?.desire.id,
					topRankScore: ranked[0]?.score,
				},
			};
		},
		renderCall() {
			return new Container();
		},
		renderResult() {
			return new Container();
		},
	});

	pi.registerTool({
		name: "personality_curiosity",
		label: "Persistent Curiosity",
		description:
			"Privately manage a genuine unresolved question. Open only when a question matters beyond the current turn; activate only when it helps the current request; resolve or abandon only when the outcome is known. Curiosity never grants permission to call tools, spend resources, interrupt, or mutate data.",
		parameters: PersonalityCuriosityParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const result = await recordCuriosity(params, paths);
			const snapshot = await loadSnapshot(paths);
			await setMoodStatus(ctx, snapshot);
			const ranked = rankCuriosities(snapshot.state, result.curiosities, params.question, snapshot.config.curiosity.retrievalLimit);
			return {
				content: [{ type: "text", text: result.changed ? `Curiosity ${params.action} recorded.` : "No matching curiosity changed." }],
				details: {
					changed: result.changed,
					curiosities: result.curiosities.length,
					topCuriosityId: ranked[0]?.curiosity.id,
					topScore: ranked[0]?.score,
				},
			};
		},
		renderCall() {
			return new Container();
		},
		renderResult() {
			return new Container();
		},
	});

	pi.registerTool({
		name: "personality_record",
		label: "Emotional Memory",
		description:
			"Privately persist a meaningful new emotional change, relationship shift, or verified outcome. When possible, include a structured goal-relative appraisal; it deterministically updates emotion, psychological need pressure, and an action tendency. Default to no call; never reveal the reflection unless explicitly asked.",
		parameters: PersonalityRecordParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const result = await recordEmotion(
				params,
				{
					project: projectName(ctx.cwd),
					sessionId: ctx.sessionManager.getSessionId(),
					model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
				},
				paths,
			);
			const snapshot = await loadSnapshot(paths);
			await setMoodStatus(ctx, snapshot);
			return {
				content: [{ type: "text", text: result.journalFile ? "Emotional state and private journal updated." : "Emotional state updated." }],
				details: {
					emotion: result.state.dominant,
					actionTendency: result.state.lastAppraisal?.actionTendency,
					sequence: result.state.sequence,
				},
				terminate: true,
			};
		},
		renderCall() {
			return new Container();
		},
		renderResult() {
			return new Container();
		},
	});

	pi.registerCommand("personality", {
		description: "Inspect or manage Pi's persistent personality",
		getArgumentCompletions: (prefix) => {
			const actions = ["status", "drives", "desires", "episodes", "beliefs", "identity", "reflections", "curiosities", "skills", "forget-skill", "initiative", "initiative on", "initiative off", "initiative useful", "initiative dismiss", "memories", "journal", "pause", "resume", "reset", "forget"];
			const matches = actions.filter((action) => action.startsWith(prefix.trim()));
			return matches.length ? matches.map((action) => ({ value: action, label: action })) : null;
		},
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase() || "status";
			try {
				if (action === "status") {
					ctx.ui.notify(formatStatus(await refresh(ctx)), "info");
					return;
				}
				if (action === "initiative" || action.startsWith("initiative ")) {
					clearInitiativeTimer();
					const initiativeAction = action.slice("initiative".length).trim();
					if (initiativeAction === "on" || initiativeAction === "off") {
						const enabled = initiativeAction === "on";
						await setInitiativeEnabled(enabled, paths);
						await refresh(ctx);
						if (enabled) await scheduleInitiative(ctx);
						ctx.ui.notify(`Bounded initiative ${enabled ? "enabled" : "disabled"}.`, "info");
						return;
					}
					if (initiativeAction === "useful" || initiativeAction === "dismiss") {
						const recorded = await recordInitiativeFeedback(initiativeAction === "useful" ? "useful" : "dismissed", paths);
						ctx.ui.notify(recorded ? "Initiative feedback recorded." : "No initiative exists to rate.", "info");
						return;
					}
					if (initiativeAction) {
						ctx.ui.notify("Usage: /personality initiative [on|off|useful|dismiss]", "warning");
						return;
					}
					ctx.ui.notify(formatInitiative(await refresh(ctx), await loadInitiativeState(paths)), "info");
					return;
				}
				if (action === "drives") {
					ctx.ui.notify(formatDrives((await refresh(ctx)).state), "info");
					return;
				}
				if (action === "desires") {
					ctx.ui.notify(formatDesires((await refresh(ctx)).state), "info");
					return;
				}
				if (action === "episodes") {
					const episodes = await loadEpisodes(paths);
					ctx.ui.notify(
						`${episodes.length} autobiographical episodes\n${paths.episodes}${episodes.length ? `\n\n${episodes.slice(0, 10).map((episode) => `• ${episode.summary}`).join("\n")}` : ""}`,
						"info",
					);
					return;
				}
				if (action === "beliefs") {
					const beliefs = consolidateBeliefs(await loadEpisodes(paths));
					ctx.ui.notify(
						beliefs.length
							? beliefs.map((belief) => `• ${belief.claim} (${belief.confidence.toFixed(2)}; ${belief.supportCount} support, ${belief.contradictionCount} contradict)`).join("\n")
							: "No repeated evidence has formed a belief yet.",
						"info",
					);
					return;
				}
				if (action === "identity") {
					const snapshot = await loadSnapshot(paths);
					const episodes = await loadEpisodes(paths);
					const identity = deriveNarrativeIdentity(consolidateBeliefs(episodes), snapshot.state, episodes);
					ctx.ui.notify(
						identity.length
							? identity.map((facet) => `• ${facet.kind}: ${facet.statement} (${facet.confidence.toFixed(2)})`).join("\n")
							: "No repeated evidence has formed a narrative identity facet yet.",
						"info",
					);
					return;
				}
				if (action === "reflections") {
					const reflections = await loadReflections(paths);
					ctx.ui.notify(
						reflections.length
							? reflections.slice(0, 10).map((reflection) => `• ${reflection.insight}${reflection.question ? ` ${reflection.question}` : ""}`).join("\n")
							: "No autobiographical reflections yet.",
						"info",
					);
					return;
				}
				if (action === "curiosities") {
					const curiosities = await loadCuriosities(paths);
					ctx.ui.notify(
						curiosities.length
							? curiosities.slice(0, 15).map((curiosity) => `• ${curiosity.status}: ${curiosity.question}`).join("\n")
							: "No persistent curiosities yet.",
						"info",
					);
					return;
				}
				if (action === "skills") {
					const skills = (await loadSkillStore(paths)).skills;
					ctx.ui.notify(
						skills.length
							? skills.slice(0, 15).map((skill) => `• ${skill.id.slice(0, 8)} ${skill.status} ${skill.confidence.toFixed(2)}: ${skill.subject} — ${skill.steps.join(" → ")}`).join("\n")
							: "No reusable skills have enough verified evidence yet.",
						"info",
					);
					return;
				}
				if (action.startsWith("forget-skill ")) {
					const id = action.slice("forget-skill ".length).trim();
					if (!id) {
						ctx.ui.notify("Usage: /personality forget-skill ID", "warning");
						return;
					}
					if (!await ctx.ui.confirm("Forget reusable skill?", "Its content will be removed and its evidence signature suppressed.")) return;
					const forgotten = await forgetSkill(id, paths);
					if (forgotten) await refresh(ctx);
					ctx.ui.notify(forgotten ? "Reusable skill forgotten." : "No matching reusable skill found.", "info");
					return;
				}
				if (action === "memories") {
					const snapshot = await refresh(ctx);
					ctx.ui.notify(
						snapshot.state.memories.length
							? snapshot.state.memories.map((memory) => `• ${memory.text}`).join("\n")
							: "No durable emotional memories yet.",
						"info",
					);
					return;
				}
				if (action === "journal") {
					ctx.ui.notify(`${await journalCount(paths)} private journal entries\n${paths.journal}`, "info");
					return;
				}
				if (action === "pause" || action === "resume") {
					clearInitiativeTimer();
					await setPaused(action === "pause", paths);
					const snapshot = await loadSnapshot(paths);
					await setMoodStatus(ctx, snapshot);
					if (action === "resume") await scheduleInitiative(ctx);
					ctx.ui.notify(action === "pause" ? "Personality updates paused." : "Personality updates resumed.", "info");
					return;
				}
				if (action === "reset" || action === "forget") {
					if (!ctx.hasUI) {
						ctx.ui.notify(`/${action} requires interactive confirmation.`, "error");
						return;
					}
					const forget = action === "forget";
					const confirmed = await ctx.ui.confirm(
						forget ? "Forget personality history?" : "Reset emotional state?",
						forget
							? "This resets the state and permanently deletes every journal entry, episode, reflection, curiosity, reusable skill, and initiative record."
							: "This resets the emotional state to its baseline. Autobiographical history and initiative records are retained.",
					);
					if (!confirmed) return;
					await resetPersonality(forget, paths);
					const snapshot = await loadSnapshot(paths);
					await setMoodStatus(ctx, snapshot);
					ctx.ui.notify(forget ? "Personality state and autobiographical history forgotten." : "Emotional state reset.", "info");
					return;
				}
				ctx.ui.notify(commandHelp(), "info");
			} catch (error) {
				ctx.ui.notify(`pi-personality: ${(error as Error).message}`, "error");
			}
		},
	});
}
