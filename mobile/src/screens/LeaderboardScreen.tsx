import { useEffect, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

import { fetchLeaderboard, type LeaderboardResponse } from "../services/swipeiqApi";

const periods = [
  { label: "Jour", value: "daily" },
  { label: "Semaine", value: "weekly" },
  { label: "Global", value: "global" },
] as const;

type PeriodKey = "daily" | "weekly" | "global";

export function LeaderboardScreen({ onBack }: { onBack: () => void }) {
  const [selectedPeriod, setSelectedPeriod] = useState<PeriodKey>("weekly");
  const [data, setData] = useState<LeaderboardResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    setError(null);

    fetchLeaderboard(selectedPeriod)
      .then((response) => {
        if (mounted) {
          setData(response);
        }
      })
      .catch((loadError) => {
        if (mounted) {
          setError(loadError instanceof Error ? loadError.message : "Impossible de charger le classement.");
        }
      })
      .finally(() => {
        if (mounted) {
          setLoading(false);
        }
      });

    return () => {
      mounted = false;
    };
  }, [selectedPeriod]);

  const userEntry = data?.currentUser;
  const entries = data?.entries ?? [];

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>

      <Text style={styles.eyebrow}>Classement</Text>
      <Text style={styles.title}>Top Joueurs</Text>
      <Text style={styles.subtitle}>Compare ta progression par periode et vise la premiere place.</Text>

      <View style={styles.heroCard}>
        <Text style={styles.heroBadge}>★</Text>
        <Text style={styles.heroTitle}>Ta position actuelle</Text>
        {loading ? <ActivityIndicator size="large" color="#7BE6FF" style={styles.heroLoader} /> : null}
        {!loading && userEntry ? (
          <>
            <Text style={styles.heroRank}>#{userEntry.rank}</Text>
            <Text style={styles.heroScore}>{userEntry.score} pts</Text>
            <Text style={styles.heroMeta}>Streak {userEntry.streak} jours</Text>
            <Text style={styles.heroSource}>{data?.generatedFromQuestions ?? 0} questions backend</Text>
          </>
        ) : null}
        {!loading && error ? <Text style={styles.heroError}>{error}</Text> : null}
      </View>

      <View style={styles.periodRow}>
        {periods.map((period) => (
          <Pressable
            key={period.value}
            onPress={() => setSelectedPeriod(period.value)}
            style={[
              styles.periodChip,
              selectedPeriod === period.value ? styles.periodChipActive : null,
            ]}
          >
            <Text style={styles.periodChipText}>{period.label}</Text>
          </Pressable>
        ))}
      </View>

      <View style={styles.listCard}>
        {loading ? (
          <View style={styles.loadingList}>
            <ActivityIndicator size="small" color="#7BE6FF" />
            <Text style={styles.loadingText}>Chargement du classement...</Text>
          </View>
        ) : null}
        {!loading && error ? <Text style={styles.loadingText}>{error}</Text> : null}
        {!loading && !error
          ? entries.map((entry) => (
          <View
            key={`${selectedPeriod}-${entry.rank}-${entry.name}`}
            style={[styles.row, entry.isCurrentUser ? styles.rowHighlight : null]}
          >
            <View style={styles.rankBox}>
              <Text style={styles.rankText}>#{entry.rank}</Text>
            </View>
            <Text style={styles.badge}>{entry.badge}</Text>
            <View style={styles.playerBlock}>
              <Text style={styles.playerName}>{entry.name}</Text>
              <Text style={styles.playerMeta}>Streak {entry.streak}</Text>
            </View>
            <Text style={styles.playerScore}>{entry.score}</Text>
          </View>
            ))
          : null}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#07132E" },
  content: { padding: 18, gap: 14 },
  back: { color: "#7BE6FF", fontWeight: "700", fontSize: 16 },
  eyebrow: {
    color: "#7BE6FF",
    fontSize: 14,
    fontWeight: "900",
    textTransform: "uppercase",
    letterSpacing: 1,
  },
  title: { color: "#fff", fontSize: 34, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 16, lineHeight: 22 },
  heroCard: {
    borderRadius: 28,
    backgroundColor: "#143174",
    borderWidth: 1,
    borderColor: "rgba(123,230,255,0.22)",
    padding: 18,
    alignItems: "center",
  },
  heroBadge: { color: "#FFD54F", fontSize: 34 },
  heroTitle: { color: "#fff", fontSize: 16, fontWeight: "700", marginTop: 6 },
  heroLoader: { marginTop: 12 },
  heroRank: { color: "#fff", fontSize: 52, fontWeight: "900", marginTop: 8 },
  heroScore: { color: "#7BE6FF", fontSize: 28, fontWeight: "900" },
  heroMeta: { color: "rgba(255,255,255,0.72)", fontSize: 15, fontWeight: "700", marginTop: 4 },
  heroSource: { color: "rgba(123,230,255,0.72)", fontSize: 13, fontWeight: "700", marginTop: 8 },
  heroError: { color: "#FFB4B4", fontWeight: "700", marginTop: 12, textAlign: "center" },
  periodRow: { flexDirection: "row", gap: 10 },
  periodChip: {
    flex: 1,
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.08)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.14)",
    paddingVertical: 12,
    alignItems: "center",
  },
  periodChipActive: {
    backgroundColor: "#1EA5FF",
    borderColor: "#7BE6FF",
  },
  periodChipText: { color: "#fff", fontWeight: "800" },
  listCard: {
    borderRadius: 24,
    backgroundColor: "rgba(16,42,96,0.78)",
    padding: 12,
    gap: 10,
  },
  loadingList: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 10,
    paddingVertical: 16,
  },
  loadingText: { color: "rgba(255,255,255,0.72)", fontWeight: "700", textAlign: "center" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.05)",
    paddingHorizontal: 12,
    paddingVertical: 14,
  },
  rowHighlight: {
    backgroundColor: "rgba(30,165,255,0.18)",
    borderWidth: 1,
    borderColor: "rgba(123,230,255,0.34)",
  },
  rankBox: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: "rgba(0,0,0,0.18)",
    alignItems: "center",
    justifyContent: "center",
  },
  rankText: { color: "#fff", fontWeight: "900" },
  badge: { fontSize: 24, marginLeft: 12 },
  playerBlock: { flex: 1, marginLeft: 12 },
  playerName: { color: "#fff", fontSize: 18, fontWeight: "800" },
  playerMeta: { color: "rgba(255,255,255,0.68)", fontWeight: "700", marginTop: 2 },
  playerScore: { color: "#fff", fontSize: 18, fontWeight: "900" },
});
