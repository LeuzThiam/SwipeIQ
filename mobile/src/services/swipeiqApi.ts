import { djangoApiBaseUrl, n8nQuestionsUrl } from "../config/api";
import type { Question } from "../types/question";

let authToken: string | null = null;

type QuestionsResponse = {
  items: Question[];
  meta: {
    count: number;
    limit: number;
    theme: string | null;
    level: string | null;
  };
};

export type FeedStats = {
  totalQuestions: number;
  themes: string[];
  levels: string[];
};

export type LeaderboardEntry = {
  rank: number;
  name: string;
  score: number;
  streak: number;
  badge: string;
  isCurrentUser: boolean;
};

export type LeaderboardResponse = {
  period: string;
  generatedFromQuestions: number;
  currentUser: LeaderboardEntry;
  entries: LeaderboardEntry[];
};

export type ProfileBadge = {
  icon: string;
  label: string;
};

export type DailyGoal = {
  label: string;
  status: string;
};

export type ProfileResponse = {
  name: string;
  username: string;
  isGuest: boolean;
  level: number;
  xp: number;
  bestStreak: number;
  quizzesPlayed: number;
  discoveredThemes: number;
  availableThemes: string[];
  badges: ProfileBadge[];
  dailyGoals: DailyGoal[];
};

export type AuthSession = {
  token: string;
  profile: ProfileResponse;
};

export type QuizResultPayload = {
  mode: "theme" | "quick" | "adventure" | "daily";
  theme?: string | null;
  level?: string | null;
  lang?: string | null;
  totalQuestions: number;
  correctAnswers: number;
  bestStreak: number;
  scorePoints: number;
};

type FetchQuestionsOptions = {
  limit?: number;
  theme?: string | null;
  level?: string | null;
  lang?: string | null;
};

export function setAuthToken(token: string | null) {
  authToken = token;
}

function buildHeaders(contentType = false): Record<string, string> {
  const headers: Record<string, string> = {};
  if (contentType) {
    headers["Content-Type"] = "application/json";
  }
  if (authToken) {
    headers.Authorization = `Token ${authToken}`;
  }
  return headers;
}

export async function fetchQuestions({
  limit = 10,
  theme = "general",
  level = "facile",
  lang = "fr",
}: FetchQuestionsOptions = {}): Promise<QuestionsResponse> {
  try {
    return await fetchQuestionsFromN8n({ limit, theme, level, lang });
  } catch {
    return fetchQuestionsFromDjango(limit);
  }
}

async function fetchQuestionsFromN8n({
  limit,
  theme,
  level,
  lang,
}: Required<FetchQuestionsOptions>): Promise<QuestionsResponse> {
  const response = await fetch(n8nQuestionsUrl, {
    method: "POST",
    headers: buildHeaders(true),
    body: JSON.stringify({
      theme,
      level,
      lang,
    }),
  });

  if (!response.ok) {
    throw new Error("Impossible de recuperer les questions depuis n8n.");
  }

  const payload = await response.json();
  const rawItems = extractQuestionsArray(payload);
  const items = rawItems.slice(0, limit).map(normalizeQuestion);

  return {
    items,
    meta: {
      count: items.length,
      limit,
      theme,
      level,
    },
  };
}

async function fetchQuestionsFromDjango(limit: number): Promise<QuestionsResponse> {
  const response = await fetch(`${djangoApiBaseUrl}/questions/?limit=${limit}`);
  if (!response.ok) {
    throw new Error("Impossible de recuperer les questions.");
  }

  return (await response.json()) as QuestionsResponse;
}

export async function fetchStats(): Promise<FeedStats> {
  try {
    const response = await fetch(`${djangoApiBaseUrl}/stats/`, { headers: buildHeaders() });
    if (!response.ok) {
      throw new Error("Stats Django indisponibles.");
    }

    return (await response.json()) as FeedStats;
  } catch {
    return {
      totalQuestions: 10,
      themes: [
        "culture_g",
        "sciences",
        "business",
        "langues",
        "sport",
        "arts_pop",
        "tech",
      ],
      levels: ["facile", "moyen", "difficile"],
    };
  }
}

export async function fetchLeaderboard(period = "weekly"): Promise<LeaderboardResponse> {
  const response = await fetch(`${djangoApiBaseUrl}/leaderboard/?period=${encodeURIComponent(period)}`, {
    headers: buildHeaders(),
  });
  if (!response.ok) {
    throw new Error("Classement indisponible.");
  }

  return (await response.json()) as LeaderboardResponse;
}

export async function fetchProfile(): Promise<ProfileResponse> {
  const response = await fetch(`${djangoApiBaseUrl}/profile/`, { headers: buildHeaders() });
  if (!response.ok) {
    throw new Error("Profil indisponible.");
  }

  return (await response.json()) as ProfileResponse;
}

export async function submitQuizResult(payload: QuizResultPayload) {
  const response = await fetch(`${djangoApiBaseUrl}/quiz-results/`, {
    method: "POST",
    headers: buildHeaders(true),
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error("Impossible d'enregistrer le resultat.");
  }

  return response.json();
}

export async function continueAsGuest(displayName: string): Promise<AuthSession> {
  const response = await fetch(`${djangoApiBaseUrl}/auth/guest/`, {
    method: "POST",
    headers: buildHeaders(true),
    body: JSON.stringify({ displayName }),
  });
  if (!response.ok) {
    throw new Error("Impossible de demarrer en invite.");
  }
  return (await response.json()) as AuthSession;
}

export async function registerSimpleAccount(
  username: string,
  password: string,
  displayName: string,
): Promise<AuthSession> {
  const response = await fetch(`${djangoApiBaseUrl}/auth/register/`, {
    method: "POST",
    headers: buildHeaders(true),
    body: JSON.stringify({ username, password, displayName }),
  });
  if (!response.ok) {
    throw new Error("Creation du compte impossible.");
  }
  return (await response.json()) as AuthSession;
}

export async function loginSimpleAccount(username: string, password: string): Promise<AuthSession> {
  const response = await fetch(`${djangoApiBaseUrl}/auth/login/`, {
    method: "POST",
    headers: buildHeaders(true),
    body: JSON.stringify({ username, password }),
  });
  if (!response.ok) {
    throw new Error("Connexion impossible.");
  }
  return (await response.json()) as AuthSession;
}

export async function logoutCurrentSession() {
  if (!authToken) {
    return;
  }
  await fetch(`${djangoApiBaseUrl}/auth/logout/`, {
    method: "POST",
    headers: buildHeaders(true),
  });
}

function extractQuestionsArray(payload: unknown): unknown[] {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (payload && typeof payload === "object") {
    const record = payload as Record<string, unknown>;
    if (typeof record.question === "string") {
      return [record];
    }
    if (Array.isArray(record.questions)) {
      return record.questions;
    }
    if (record.data && typeof record.data === "object") {
      const data = record.data as Record<string, unknown>;
      if (typeof data.question === "string") {
        return [data];
      }
      if (Array.isArray(data.questions)) {
        return data.questions;
      }
    }
  }

  throw new Error("Format JSON n8n invalide.");
}

function normalizeQuestion(raw: unknown, index: number): Question {
  if (!raw || typeof raw !== "object") {
    throw new Error(`Question distante invalide a l'index ${index}.`);
  }

  const record = raw as Record<string, unknown>;
  const choicesRaw = Array.isArray(record.choices)
    ? record.choices
    : Array.isArray(record.answers)
      ? record.answers
      : null;

  if (!choicesRaw || choicesRaw.length !== 4) {
    throw new Error("Question distante invalide: choices/answers manquant.");
  }

  const choices = choicesRaw.map((choice) => {
    if (choice && typeof choice === "object" && "text" in choice) {
      const text = (choice as { text?: unknown }).text;
      if (typeof text === "string" && text.trim()) {
        return text.trim();
      }
    }

    return String(choice);
  });

  const answer = parseAnswerIndex(
    record.answer ?? record.correctIndex ?? record.answerId,
  );
  if (answer === null || answer < 0 || answer > 3) {
    throw new Error("Question distante invalide: answer/correctIndex.");
  }

  const questionText = typeof record.question === "string" ? record.question.trim() : "";
  if (!questionText) {
    throw new Error("Question distante invalide: question vide.");
  }

  return {
    id: typeof record.id === "string" ? record.id : `n8n-${index + 1}`,
    theme:
      typeof record.theme === "string"
        ? record.theme
        : typeof record.category === "string"
          ? record.category
          : "general",
    level:
      typeof record.level === "string"
        ? record.level
        : typeof record.difficulty === "string"
          ? record.difficulty
          : "facile",
    question: questionText,
    choices,
    answer,
    explanation:
      typeof record.explanation === "string"
        ? record.explanation
        : "Question importee depuis n8n.",
  };
}

function parseAnswerIndex(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }

  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim().toUpperCase();
  if (!normalized) {
    return null;
  }

  const numeric = Number.parseInt(normalized, 10);
  if (!Number.isNaN(numeric)) {
    return numeric;
  }

  switch (normalized) {
    case "A":
      return 0;
    case "B":
      return 1;
    case "C":
      return 2;
    case "D":
      return 3;
    default:
      return null;
  }
}
