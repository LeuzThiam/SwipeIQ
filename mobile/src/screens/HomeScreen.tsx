import { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

import {
  fetchLeaderboard,
  fetchProfile,
  type LeaderboardResponse,
  type ProfileResponse,
} from "../services/swipeiqApi";

type Props = {
  onOpenAdventure: () => void;
  onOpenThemeQuiz: () => void;
  onOpenQuickQuiz: () => void;
  onOpenDailyChallenge: () => void;
  onOpenLeaderboard: () => void;
  onOpenProfile: () => void;
};

export function HomeScreen(props: Props) {
  const [profile, setProfile] = useState<ProfileResponse | null>(null);
  const [leaderboard, setLeaderboard] = useState<LeaderboardResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    Promise.all([fetchProfile(), fetchLeaderboard("weekly")])
      .then(([profileResponse, leaderboardResponse]) => {
        if (!mounted) {
          return;
        }
        setProfile(profileResponse);
        setLeaderboard(leaderboardResponse);
      })
      .finally(() => {
        if (mounted) {
          setLoading(false);
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  const xp = profile?.xp ?? 0;
  const level = profile?.level ?? 1;
  const nextLevelXp = level * 1000;
  const previousLevelXp = Math.max(0, (level - 1) * 1000);
  const progressPercent = useMemo(() => {
    if (nextLevelXp <= previousLevelXp) {
      return 0;
    }
    const ratio = ((xp - previousLevelXp) / (nextLevelXp - previousLevelXp)) * 100;
    return Math.max(6, Math.min(100, ratio));
  }, [nextLevelXp, previousLevelXp, xp]);
  const weeklyRank = leaderboard?.currentUser.rank;
  const weeklyScore = leaderboard?.currentUser.score ?? xp;

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.playerHeader}>
        <View style={styles.avatar}>
          {loading ? (
            <ActivityIndicator size="small" color="#fff" />
          ) : (
            <Text style={styles.avatarIcon}>{profile?.name?.slice(0, 1) ?? "M"}</Text>
          )}
        </View>
        <View style={styles.headerText}>
          <Text style={styles.levelText}>Nv. {level}</Text>
          <View style={styles.starPill}>
            <Text style={styles.starText}>★ {weeklyScore}</Text>
          </View>
          <Text style={styles.rankText}>Classement semaine: #{weeklyRank ?? "..."}</Text>
        </View>
      </View>

      <View style={styles.progressPanel}>
        <View style={styles.progressRow}>
          <Text style={styles.progressTitle}>Progression</Text>
          <View style={styles.progressTrack}>
            <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
          </View>
          <Text style={styles.progressScore}>{xp}</Text>
        </View>
        <Text style={styles.progressMessage}>
          Continue ton aventure !{"\n"}Niveau suivant: {level + 1}
        </Text>
      </View>

      <Pressable style={styles.primaryCard} onPress={props.onOpenAdventure}>
        <Text style={styles.primaryIcon}>⌘</Text>
        <Text style={styles.primaryLabel}>AVENTURE</Text>
      </Pressable>

      <View style={styles.row}>
        <ActionCard label={"Choisir\ntheme"} icon="▤" color="#2267D8" onPress={props.onOpenThemeQuiz} />
        <ActionCard label={"Quiz rapide"} icon="⚡" color="#6A37DA" onPress={props.onOpenQuickQuiz} />
      </View>
      <View style={styles.row}>
        <ActionCard label={"Defi du jour"} icon="✓" color="#3FAA4A" onPress={props.onOpenDailyChallenge} />
        <ActionCard label={"Classement"} icon="★" color="#183D99" onPress={props.onOpenLeaderboard} />
      </View>
      <ActionCard label="Profil" icon="◎" color="#2354AB" onPress={props.onOpenProfile} fullWidth />
    </ScrollView>
  );
}

function ActionCard({
  label,
  icon,
  color,
  onPress,
  fullWidth = false,
}: {
  label: string;
  icon: string;
  color: string;
  onPress: () => void;
  fullWidth?: boolean;
}) {
  return (
    <Pressable style={[styles.actionCard, { backgroundColor: color }, fullWidth ? styles.fullWidth : null]} onPress={onPress}>
      <Text style={styles.actionIcon}>{icon}</Text>
      <Text style={styles.actionLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#05164A",
  },
  content: {
    padding: 18,
    gap: 12,
  },
  playerHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
  },
  avatar: {
    width: 84,
    height: 84,
    borderRadius: 42,
    backgroundColor: "#216CE2",
    borderWidth: 2,
    borderColor: "rgba(255,255,255,0.24)",
    alignItems: "center",
    justifyContent: "center",
  },
  avatarIcon: {
    color: "#fff",
    fontSize: 40,
  },
  headerText: {
    flex: 1,
  },
  levelText: {
    color: "#fff",
    fontSize: 28,
    fontWeight: "900",
  },
  starPill: {
    marginTop: 8,
    alignSelf: "flex-start",
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 16,
    backgroundColor: "#2B5BBC",
  },
  starText: {
    color: "#fff",
    fontSize: 24,
    fontWeight: "800",
  },
  rankText: {
    marginTop: 8,
    color: "rgba(255,255,255,0.72)",
    fontWeight: "700",
    fontSize: 14,
  },
  progressPanel: {
    borderRadius: 20,
    backgroundColor: "rgba(18,59,138,0.78)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    padding: 14,
  },
  progressRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  progressTitle: {
    color: "#fff",
    fontSize: 18,
  },
  progressTrack: {
    flex: 1,
    height: 12,
    borderRadius: 30,
    backgroundColor: "#1B2F63",
    overflow: "hidden",
  },
  progressFill: {
    height: "100%",
    backgroundColor: "#FFC107",
  },
  progressScore: {
    color: "#fff",
    fontWeight: "800",
    fontSize: 18,
  },
  progressMessage: {
    marginTop: 12,
    color: "#fff",
    fontWeight: "700",
    fontSize: 19,
    lineHeight: 24,
  },
  primaryCard: {
    height: 220,
    borderRadius: 28,
    backgroundColor: "#E2851D",
    borderWidth: 3,
    borderColor: "#FFE082",
    justifyContent: "center",
    alignItems: "center",
  },
  primaryIcon: {
    color: "#fff",
    fontSize: 54,
  },
  primaryLabel: {
    color: "#fff",
    fontSize: 50,
    fontWeight: "900",
  },
  row: {
    flexDirection: "row",
    gap: 12,
  },
  actionCard: {
    flex: 1,
    minHeight: 126,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: "rgba(255,255,255,0.24)",
    padding: 14,
    justifyContent: "center",
  },
  fullWidth: {
    flex: 0,
    width: "100%",
  },
  actionIcon: {
    color: "#fff",
    fontSize: 36,
    marginBottom: 10,
  },
  actionLabel: {
    color: "#fff",
    fontWeight: "800",
    fontSize: 21,
    lineHeight: 23,
  },
});
