import { useEffect, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

import { fetchProfile, type ProfileResponse } from "../services/swipeiqApi";

export function ProfileScreen({ onBack, onLogout }: { onBack: () => void; onLogout: () => Promise<void> | void }) {
  const [profile, setProfile] = useState<ProfileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    fetchProfile()
      .then((data) => {
        if (mounted) {
          setProfile(data);
        }
      })
      .catch((loadError) => {
        if (mounted) {
          setError(loadError instanceof Error ? loadError.message : "Impossible de charger le profil.");
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
  }, []);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>
      <Pressable onPress={() => onLogout()} style={styles.logoutButton}>
        <Text style={styles.logoutText}>Se deconnecter</Text>
      </Pressable>

      <View style={styles.headerCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{profile?.name?.slice(0, 1) ?? "M"}</Text>
        </View>
        <View style={styles.headerInfo}>
          <Text style={styles.name}>{profile?.name ?? "Modou"}</Text>
          <Text style={styles.level}>Niveau {profile?.level ?? "..."}</Text>
          <Text style={styles.subtitle}>Joueur actif • React Native x Django</Text>
        </View>
      </View>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <View style={styles.statsGrid}>
        <ProfileStatCard label="XP totale" value={profile?.xp ?? "..."} accent="#2CC6FF" />
        <ProfileStatCard label="Serie max" value={profile?.bestStreak ?? "..."} accent="#34C94A" />
        <ProfileStatCard label="Quiz joues" value={profile?.quizzesPlayed ?? "..."} accent="#F7A900" />
        <ProfileStatCard label="Themes decouverts" value={profile?.discoveredThemes ?? "..."} accent="#E4513A" />
      </View>

      <View style={styles.sectionCard}>
        <Text style={styles.sectionTitle}>Badges</Text>
        <View style={styles.badgesRow}>
          {(profile?.badges ?? []).map((badge) => (
            <View key={badge.label} style={styles.badgeCard}>
              <Text style={styles.badgeIcon}>{badge.icon}</Text>
              <Text style={styles.badgeLabel}>{badge.label}</Text>
            </View>
          ))}
        </View>
      </View>

      <View style={styles.sectionCard}>
        <Text style={styles.sectionTitle}>Themes disponibles</Text>
        {loading ? (
          <View style={styles.loadingRow}>
            <ActivityIndicator size="small" color="#7BE6FF" />
            <Text style={styles.loadingText}>Chargement du profil...</Text>
          </View>
        ) : (
          <View style={styles.tagWrap}>
            {(profile?.availableThemes ?? []).map((theme) => (
              <View key={theme} style={styles.tag}>
                <Text style={styles.tagText}>{theme}</Text>
              </View>
            ))}
          </View>
        )}
      </View>

      <View style={styles.sectionCard}>
        <Text style={styles.sectionTitle}>Objectifs du jour</Text>
        {(profile?.dailyGoals ?? []).map((goal) => (
          <ObjectiveItem key={goal.label} label={goal.label} status={goal.status} />
        ))}
      </View>
    </ScrollView>
  );
}

function ProfileStatCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: string | number;
  accent: string;
}) {
  return (
    <View style={[styles.statCard, { borderColor: `${accent}66` }]}>
      <Text style={[styles.statValue, { color: accent }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function ObjectiveItem({ label, status }: { label: string; status: string }) {
  return (
    <View style={styles.objectiveRow}>
      <Text style={styles.objectiveLabel}>{label}</Text>
      <View style={styles.objectivePill}>
        <Text style={styles.objectiveStatus}>{status}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#07132E" },
  content: { padding: 18, gap: 14 },
  back: { color: "#7BE6FF", fontWeight: "700", fontSize: 16 },
  logoutButton: { alignSelf: "flex-end" },
  logoutText: { color: "#FFB4B4", fontWeight: "800" },
  headerCard: {
    flexDirection: "row",
    alignItems: "center",
    borderRadius: 28,
    backgroundColor: "#102E6A",
    padding: 18,
    borderWidth: 1,
    borderColor: "rgba(123,230,255,0.22)",
  },
  avatar: {
    width: 84,
    height: 84,
    borderRadius: 42,
    backgroundColor: "#1EA5FF",
    alignItems: "center",
    justifyContent: "center",
  },
  avatarText: { color: "#fff", fontSize: 34, fontWeight: "900" },
  headerInfo: { flex: 1, marginLeft: 14 },
  name: { color: "#fff", fontSize: 28, fontWeight: "900" },
  level: { color: "#7BE6FF", fontSize: 18, fontWeight: "800", marginTop: 2 },
  subtitle: { color: "rgba(255,255,255,0.68)", marginTop: 6, fontWeight: "700" },
  errorText: { color: "#FFB4B4", fontWeight: "700" },
  statsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    justifyContent: "space-between",
  },
  statCard: {
    width: "48%",
    borderRadius: 22,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderWidth: 1,
    padding: 16,
  },
  statValue: { fontSize: 28, fontWeight: "900" },
  statLabel: { color: "rgba(255,255,255,0.72)", marginTop: 6, fontWeight: "700" },
  sectionCard: {
    borderRadius: 24,
    backgroundColor: "rgba(16,42,96,0.78)",
    padding: 16,
    gap: 12,
  },
  sectionTitle: { color: "#fff", fontSize: 20, fontWeight: "900" },
  badgesRow: { flexDirection: "row", gap: 10 },
  badgeCard: {
    flex: 1,
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.06)",
    paddingVertical: 16,
    alignItems: "center",
    gap: 8,
  },
  badgeIcon: { fontSize: 28 },
  badgeLabel: { color: "#fff", fontWeight: "800", fontSize: 13 },
  loadingRow: { flexDirection: "row", alignItems: "center", gap: 10 },
  loadingText: { color: "rgba(255,255,255,0.72)", fontWeight: "700" },
  tagWrap: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  tag: {
    borderRadius: 999,
    backgroundColor: "rgba(30,165,255,0.16)",
    borderWidth: 1,
    borderColor: "rgba(123,230,255,0.22)",
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  tagText: { color: "#fff", fontWeight: "700" },
  objectiveRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderRadius: 16,
    backgroundColor: "rgba(255,255,255,0.04)",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  objectiveLabel: { color: "#fff", fontWeight: "700", flex: 1, paddingRight: 10 },
  objectivePill: {
    borderRadius: 999,
    backgroundColor: "rgba(52,201,74,0.18)",
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  objectiveStatus: { color: "#8DF7A0", fontWeight: "800", fontSize: 12 },
});
