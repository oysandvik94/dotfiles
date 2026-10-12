import { strict as assert } from "node:assert";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

const STARTING_CHIPS = 100;
const ANTE = 5;
const BET = 10;
const SAVE_TYPE = "holdem-save";
const SUITS = ["S", "H", "D", "C"] as const;
const RANKS = ["", "", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];

type Suit = (typeof SUITS)[number];
type Street = "preflop" | "flop" | "turn" | "river";
type Card = { rank: number; suit: Suit };
type HandValue = { score: number[]; name: string };
type PipRow = "" | "center" | "sides";

const SUIT_SYMBOLS: Record<Suit, string> = { S: "♠", H: "♥", D: "♦", C: "♣" };
const PIP_ROWS: Record<number, PipRow[]> = {
	2: ["center", "", "", "", "center"],
	3: ["center", "", "center", "", "center"],
	4: ["sides", "", "", "", "sides"],
	5: ["sides", "", "center", "", "sides"],
	6: ["sides", "", "sides", "", "sides"],
	7: ["sides", "center", "sides", "", "sides"],
	8: ["sides", "center", "sides", "center", "sides"],
	9: ["sides", "sides", "center", "sides", "sides"],
	10: ["sides", "sides", "sides", "sides", "sides"],
	14: ["", "", "center", "", ""],
};

function asciiCard(value: Card | null): string[] {
	const border = "+---------+";
	if (!value) return [border, ...Array(7).fill("|# # # # #|"), border];

	const rank = RANKS[value.rank];
	const suit = SUIT_SYMBOLS[value.suit];
	const face = value.rank >= 11 && value.rank <= 13;
	const body = face
		? ["  .---.  ", ` / ${rank} ${rank} \\ `, `(   ${suit}   )`, ` \\ ${rank} ${rank} / `, "  '---'  "]
		: PIP_ROWS[value.rank].map((row) => row === "center" ? `    ${suit}    ` : row === "sides" ? ` ${suit}     ${suit} ` : "         ");
	return [
		border,
		`|${`${rank}${suit}`.padEnd(9)}|`,
		...body.map((row) => `|${row}|`),
		`|${`${suit}${rank}`.padStart(9)}|`,
		border,
	];
}

interface GameState {
	playerChips: number;
	dealerChips: number;
	pot: number;
	deck: Card[];
	player: Card[];
	dealer: Card[];
	board: Card[];
	street: Street;
	pendingBet: number;
	handOver: boolean;
	matchOver: boolean;
	dealerRevealed: boolean;
	hand: number;
	message: string;
}

function shuffledDeck(): Card[] {
	const deck = SUITS.flatMap((suit) =>
		Array.from({ length: 13 }, (_, index) => ({ rank: index + 2, suit })),
	);
	for (let i = deck.length - 1; i > 0; i--) {
		const j = Math.floor(Math.random() * (i + 1));
		[deck[i], deck[j]] = [deck[j], deck[i]];
	}
	return deck;
}

function compareScores(a: number[], b: number[]): number {
	for (let i = 0; i < Math.max(a.length, b.length); i++) {
		if ((a[i] ?? 0) !== (b[i] ?? 0)) return (a[i] ?? 0) - (b[i] ?? 0);
	}
	return 0;
}

function evaluateFive(cards: Card[]): HandValue {
	const ranks = cards.map((card) => card.rank).sort((a, b) => b - a);
	const groups = [...new Set(ranks)].map((rank) => ({
		rank,
		count: ranks.filter((value) => value === rank).length,
	})).sort((a, b) => b.count - a.count || b.rank - a.rank);
	const unique = [...new Set(ranks)];
	if (unique[0] === 14) unique.push(1);
	let straightHigh = 0;
	for (let i = 0; i <= unique.length - 5; i++) {
		if (unique[i] - unique[i + 4] === 4) {
			straightHigh = unique[i];
			break;
		}
	}
	const flush = cards.every((card) => card.suit === cards[0].suit);
	const four = groups.find((group) => group.count === 4);
	const three = groups.find((group) => group.count === 3);
	const pairs = groups.filter((group) => group.count === 2);

	if (flush && straightHigh) return { score: [8, straightHigh], name: "Straight flush" };
	if (four) return { score: [7, four.rank, ...groups.filter((g) => g !== four).map((g) => g.rank)], name: "Four of a kind" };
	if (three && pairs[0]) return { score: [6, three.rank, pairs[0].rank], name: "Full house" };
	if (flush) return { score: [5, ...ranks], name: "Flush" };
	if (straightHigh) return { score: [4, straightHigh], name: "Straight" };
	if (three) return { score: [3, three.rank, ...groups.filter((g) => g !== three).map((g) => g.rank)], name: "Three of a kind" };
	if (pairs.length >= 2) {
		const [high, low] = pairs.map((pair) => pair.rank).sort((a, b) => b - a);
		return { score: [2, high, low, groups.find((group) => group.count === 1)!.rank], name: "Two pair" };
	}
	if (pairs[0]) return { score: [1, pairs[0].rank, ...groups.filter((g) => g !== pairs[0]).map((g) => g.rank)], name: "Pair" };
	return { score: [0, ...ranks], name: "High card" };
}

export function evaluateHand(cards: Card[]): HandValue {
	if (cards.length < 5) throw new Error("A poker hand needs at least five cards");
	let best: HandValue | undefined;
	const choose = (start: number, picked: Card[]): void => {
		if (picked.length === 5) {
			const value = evaluateFive(picked);
			if (!best || compareScores(value.score, best.score) > 0) best = value;
			return;
		}
		for (let i = start; i <= cards.length - (5 - picked.length); i++) choose(i + 1, [...picked, cards[i]]);
	};
	choose(0, []);
	return best!;
}

function card(rank: number, suit: Suit): Card {
	return { rank, suit };
}

function selfTest(): void {
	const straightFlush = evaluateHand([card(14, "S"), card(13, "S"), card(12, "S"), card(11, "S"), card(10, "S"), card(2, "D"), card(3, "C")]);
	const quads = evaluateHand([card(9, "S"), card(9, "H"), card(9, "D"), card(9, "C"), card(14, "S"), card(2, "D"), card(3, "C")]);
	const wheel = evaluateHand([card(14, "S"), card(2, "H"), card(3, "D"), card(4, "C"), card(5, "S")]);
	assert(compareScores(straightFlush.score, quads.score) > 0);
	assert.deepEqual(wheel.score, [4, 5]);
	for (const suit of SUITS) {
		for (let rank = 2; rank <= 14; rank++) {
			const art = asciiCard(card(rank, suit));
			assert.equal(art.length, 9);
			assert(art.every((line) => line.length === 11));
			assert(art.join("\n").includes(SUIT_SYMBOLS[suit]));
		}
	}

	const state = newMatch();
	assert.equal(state.playerChips + state.dealerChips + state.pot, STARTING_CHIPS * 2);
	assert(dealerCallChance(state, 1) > dealerCallChance(state, state.dealerChips));
	assert.equal(presetBet(95, "w"), 10);
	assert.equal(presetBet(95, "s"), 47);
	assert.equal(presetBet(95, "g"), 95);
	finishHand(state, "player", "test");
	assert.equal(state.playerChips + state.dealerChips + state.pot, STARTING_CHIPS * 2);
}

if (process.env.PI_HOLDEM_SELF_TEST === "1") selfTest();

function newMatch(): GameState {
	const state = {
		playerChips: STARTING_CHIPS,
		dealerChips: STARTING_CHIPS,
		pot: 0,
		deck: [],
		player: [],
		dealer: [],
		board: [],
		street: "preflop" as Street,
		pendingBet: 0,
		handOver: false,
		matchOver: false,
		dealerRevealed: false,
		hand: 0,
		message: "",
	};
	startHand(state);
	return state;
}

function startHand(state: GameState): void {
	if (state.playerChips < ANTE || state.dealerChips < ANTE) {
		state.matchOver = true;
		state.handOver = true;
		state.message = state.playerChips > state.dealerChips ? "You won the match!" : "Dealer won the match.";
		return;
	}
	state.hand++;
	state.deck = shuffledDeck();
	state.player = [state.deck.pop()!, state.deck.pop()!];
	state.dealer = [state.deck.pop()!, state.deck.pop()!];
	state.board = [];
	state.street = "preflop";
	state.pendingBet = 0;
	state.handOver = false;
	state.matchOver = false;
	state.dealerRevealed = false;
	state.playerChips -= ANTE;
	state.dealerChips -= ANTE;
	state.pot = ANTE * 2;
	state.message = `Ante ${ANTE}. Your move.`;
}

function dealerStrength(state: GameState): number {
	const cards = [...state.dealer, ...state.board];
	if (cards.length >= 5) {
		const value = evaluateHand(cards).score;
		return value[0] + (value[1] ?? 0) / 100;
	}
	const [a, b] = state.dealer;
	if (a.rank === b.rank) return 1.5 + a.rank / 100;
	return Math.max(a.rank, b.rank) / 20 + (a.suit === b.suit ? 0.15 : 0);
}

function dealerCallChance(state: GameState, wager: number): number {
	const pressure = wager / Math.max(1, state.dealerChips + wager);
	return Math.max(0.08, Math.min(0.98, 0.72 + dealerStrength(state) * 0.12 - pressure));
}

function presetBet(max: number, key: string): number {
	if (key === "w") return Math.min(BET, max);
	if (key === "s") return Math.max(1, Math.floor(max / 2));
	return max;
}

function finishHand(state: GameState, winner: "player" | "dealer" | "tie", message: string, reveal = false): void {
	if (winner === "player") state.playerChips += state.pot;
	else if (winner === "dealer") state.dealerChips += state.pot;
	else {
		const half = Math.floor(state.pot / 2);
		state.playerChips += half;
		state.dealerChips += state.pot - half;
	}
	state.pot = 0;
	state.pendingBet = 0;
	state.handOver = true;
	state.dealerRevealed = reveal;
	state.matchOver = state.playerChips < ANTE || state.dealerChips < ANTE;
	state.message = message + (state.matchOver ? " Match over." : " Press C for the next hand.");
}

function showdown(state: GameState): void {
	while (state.board.length < 5) state.board.push(state.deck.pop()!);
	const player = evaluateHand([...state.player, ...state.board]);
	const dealer = evaluateHand([...state.dealer, ...state.board]);
	const result = compareScores(player.score, dealer.score);
	if (result > 0) finishHand(state, "player", `You win with ${player.name}.`, true);
	else if (result < 0) finishHand(state, "dealer", `Dealer wins with ${dealer.name}.`, true);
	else finishHand(state, "tie", `Split pot: ${player.name}.`, true);
}

function advanceStreet(state: GameState): void {
	if (state.playerChips === 0 || state.dealerChips === 0 || state.street === "river") {
		showdown(state);
		return;
	}
	if (state.street === "preflop") {
		state.board.push(state.deck.pop()!, state.deck.pop()!, state.deck.pop()!);
		state.street = "flop";
	} else if (state.street === "flop") {
		state.board.push(state.deck.pop()!);
		state.street = "turn";
	} else {
		state.board.push(state.deck.pop()!);
		state.street = "river";
	}
	state.message = `${state.street[0].toUpperCase()}${state.street.slice(1)}. Your move.`;
}

class HoldemComponent {
	constructor(
		private state: GameState,
		private tui: { requestRender: () => void },
		private onClose: (state: GameState | null) => void,
		private theme: { fg: (color: "accent" | "success" | "error" | "warning" | "muted" | "dim", text: string) => string; bold: (text: string) => string },
	) {}

	handleInput(data: string): void {
		const key = data.toLowerCase();
		if (key === "q" || matchesKey(data, "escape")) {
			this.onClose(this.state);
			return;
		}
		if (this.state.matchOver && key === "r") {
			this.state = newMatch();
			this.tui.requestRender();
			return;
		}
		if (this.state.handOver) {
			if (key === "c") startHand(this.state);
			this.tui.requestRender();
			return;
		}
		if (key === "f") {
			finishHand(this.state, "dealer", "You fold. Dealer takes the pot.");
		} else if (key === "c") {
			this.checkOrCall();
		} else if (this.state.pendingBet === 0 && (key === "w" || key === "s" || key === "g")) {
			this.bet(presetBet(Math.min(this.state.playerChips, this.state.dealerChips), key));
		}
		this.tui.requestRender();
	}

	private checkOrCall(): void {
		if (this.state.pendingBet > 0) {
			this.state.playerChips -= this.state.pendingBet;
			this.state.pot += this.state.pendingBet;
			this.state.pendingBet = 0;
			advanceStreet(this.state);
			return;
		}
		const wager = Math.min(BET, this.state.playerChips, this.state.dealerChips);
		if (wager > 0 && (dealerStrength(this.state) >= 1 || Math.random() < 0.25)) {
			this.state.dealerChips -= wager;
			this.state.pot += wager;
			this.state.pendingBet = wager;
			this.state.message = `Dealer bets ${wager}. C to call or F to fold.`;
		} else {
			advanceStreet(this.state);
		}
	}

	private bet(wager: number): void {
		this.state.playerChips -= wager;
		this.state.pot += wager;
		if (Math.random() < dealerCallChance(this.state, wager)) {
			this.state.dealerChips -= wager;
			this.state.pot += wager;
			advanceStreet(this.state);
		} else {
			finishHand(this.state, "player", "Dealer folds. You take the pot.");
		}
	}

	invalidate(): void {}

	render(width: number): string[] {
		const t = this.theme;
		const title = t.bold(t.fg("accent", "PI TEXAS HOLD'EM"));
		const border = `+${"-".repeat(Math.max(0, Math.min(70, width - 2)))}+`;
		const lines = [
			border,
			`${title}  Hand ${this.state.hand}  ${t.fg("warning", this.state.street.toUpperCase())}  Pot: ${t.bold(String(this.state.pot))}`,
			`Dealer: ${t.fg("muted", String(this.state.dealerChips))} chips`,
			...this.cards(this.state.dealer, !this.state.dealerRevealed, width),
			"Board:",
			...(this.state.board.length ? this.cards(this.state.board, false, width) : [t.fg("dim", "(no community cards yet)")]),
			`You: ${t.fg("success", String(this.state.playerChips))} chips`,
			...this.cards(this.state.player, false, width),
			"",
			this.state.message,
			this.help(),
			border,
		];
		return lines.map((line) => truncateToWidth(line, Math.max(1, width), ""));
	}

	private cards(cards: Card[], hidden: boolean, width: number): string[] {
		const perRow = Math.max(1, Math.floor((width + 1) / 12));
		const output: string[] = [];
		for (let start = 0; start < cards.length; start += perRow) {
			const chunk = cards.slice(start, start + perRow);
			const rendered = chunk.map((value) => asciiCard(hidden ? null : value));
			for (let row = 0; row < 9; row++) {
				output.push(rendered.map((lines, index) => {
					if (hidden) return this.theme.fg("muted", lines[row]);
					const value = chunk[index];
					const symbol = SUIT_SYMBOLS[value.suit];
					return value.suit === "H" || value.suit === "D"
						? lines[row].replaceAll(symbol, this.theme.fg("error", symbol))
						: lines[row];
				}).join(" "));
			}
		}
		return output;
	}

	private help(): string {
		if (this.state.matchOver) return "R restart match | Q save and close";
		if (this.state.handOver) return "C next hand | Q save and close";
		if (this.state.pendingBet) return "C call | F fold | Q save and close";
		return "C check | W bet 10 | S bet half | G all-in | F fold | Q save and close";
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("holdem", {
		description: "Play ASCII Texas Hold'em while pi works",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("Hold'em requires interactive mode", "error");
				return;
			}
			const saved = [...ctx.sessionManager.getEntries()].reverse().find(
				(entry) => entry.type === "custom" && entry.customType === SAVE_TYPE,
			);
			const state = saved?.type === "custom" && saved.data ? saved.data as GameState : newMatch();
			await ctx.ui.custom<void>((tui, theme, _keybindings, done) =>
				new HoldemComponent(state, tui, (next) => {
					pi.appendEntry(SAVE_TYPE, next);
					done(undefined);
				}, theme),
			);
		},
	});
}
