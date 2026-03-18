import { Platform } from "react-native";

const localhost = Platform.OS === "android" ? "127.0.0.1" : "localhost";

const normalizeBaseUrl = (value: string) => value.trim().replace(/\/+$/, "");

export const djangoApiBaseUrl = normalizeBaseUrl(
  process.env.EXPO_PUBLIC_API_URL ?? `http://${localhost}:8000/api`,
);

export const n8nBaseUrl = normalizeBaseUrl(
  process.env.EXPO_PUBLIC_N8N_BASE_URL ?? `http://${localhost}:5678`,
);

export const n8nQuestionsUrl = process.env.EXPO_PUBLIC_QUESTIONS_URL
  ? normalizeBaseUrl(process.env.EXPO_PUBLIC_QUESTIONS_URL)
  : `${n8nBaseUrl}/webhook/questions`;
