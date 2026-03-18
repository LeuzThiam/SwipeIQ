import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

type Props = {
  onBack: () => void;
  onStart: () => void;
};

export function DailyChallengeScreen({ onBack, onStart }: Props) {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>

      <View style={styles.hero}>
        <Text style={styles.heroIcon}>✓</Text>
        <Text style={styles.heroTitle}>Defi du jour</Text>
        <Text style={styles.heroSubtitle}>
          Une session quotidienne courte avec score, objectif et recompenses.
        </Text>
      </View>

      <View style={styles.missionCard}>
        <Text style={styles.sectionTitle}>Mission</Text>
        <Text style={styles.missionText}>Reponds correctement a au moins 4 questions sur 5 avant la fin du chrono.</Text>
        <View style={styles.tagRow}>
          <Tag label="5 questions" color="#46BA53" />
          <Tag label="45 sec / question" color="#1EA5FF" />
          <Tag label="+250 pts bonus" color="#FFC107" />
        </View>
      </View>

      <View style={styles.statsCard}>
        <Text style={styles.sectionTitle}>Serie quotidienne</Text>
        <View style={styles.statRow}>
          <StatBox label="Streak" value="3 jours" accent="#FF8A00" />
          <StatBox label="Best" value="4/5" accent="#34C94A" />
          <StatBox label="Rang" value="#12" accent="#7BE6FF" />
        </View>
      </View>

      <View style={styles.rewardCard}>
        <Text style={styles.sectionTitle}>Recompenses</Text>
        <Text style={styles.rewardText}>Complete le defi pour debloquer un bonus journalier et faire progresser ton classement.</Text>
        <View style={styles.rewardList}>
          <Text style={styles.rewardItem}>• +250 points de score</Text>
          <Text style={styles.rewardItem}>• +25 coins</Text>
          <Text style={styles.rewardItem}>• 1 coffre bonus si score parfait</Text>
        </View>
      </View>

      <Pressable style={styles.playButton} onPress={onStart}>
        <Text style={styles.playButtonText}>LANCER LE DEFI</Text>
      </Pressable>
    </ScrollView>
  );
}

function Tag({ label, color }: { label: string; color: string }) {
  return (
    <View style={[styles.tag, { borderColor: color }]}>
      <Text style={[styles.tagText, { color }]}>{label}</Text>
    </View>
  );
}

function StatBox({
  label,
  value,
  accent,
}: {
  label: string;
  value: string;
  accent: string;
}) {
  return (
    <View style={styles.statBox}>
      <Text style={[styles.statValue, { color: accent }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#071B4D",
  },
  content: {
    padding: 18,
    gap: 14,
  },
  back: {
    color: "#7BE6FF",
    fontWeight: "700",
    fontSize: 16,
  },
  hero: {
    alignItems: "center",
    paddingTop: 8,
    paddingBottom: 8,
  },
  heroIcon: {
    fontSize: 56,
    color: "#46BA53",
  },
  heroTitle: {
    marginTop: 8,
    color: "#FFFFFF",
    fontSize: 34,
    fontWeight: "900",
  },
  heroSubtitle: {
    marginTop: 8,
    color: "rgba(255,255,255,0.74)",
    textAlign: "center",
    fontSize: 17,
    lineHeight: 24,
  },
  missionCard: {
    borderRadius: 24,
    backgroundColor: "rgba(20,47,102,0.8)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    padding: 18,
  },
  sectionTitle: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "800",
  },
  missionText: {
    marginTop: 10,
    color: "rgba(255,255,255,0.78)",
    fontSize: 16,
    lineHeight: 23,
  },
  tagRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginTop: 14,
  },
  tag: {
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: "rgba(0,0,0,0.16)",
  },
  tagText: {
    fontWeight: "700",
    fontSize: 12,
  },
  statsCard: {
    borderRadius: 24,
    backgroundColor: "rgba(20,47,102,0.8)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    padding: 18,
  },
  statRow: {
    flexDirection: "row",
    gap: 10,
    marginTop: 14,
  },
  statBox: {
    flex: 1,
    borderRadius: 18,
    backgroundColor: "rgba(0,0,0,0.18)",
    paddingVertical: 16,
    alignItems: "center",
  },
  statValue: {
    fontSize: 20,
    fontWeight: "900",
  },
  statLabel: {
    marginTop: 6,
    color: "rgba(255,255,255,0.72)",
    fontSize: 12,
    textTransform: "uppercase",
  },
  rewardCard: {
    borderRadius: 24,
    backgroundColor: "rgba(20,47,102,0.8)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    padding: 18,
  },
  rewardText: {
    marginTop: 10,
    color: "rgba(255,255,255,0.78)",
    fontSize: 16,
    lineHeight: 23,
  },
  rewardList: {
    marginTop: 12,
    gap: 6,
  },
  rewardItem: {
    color: "#FFFFFF",
    fontWeight: "700",
  },
  playButton: {
    marginTop: 6,
    borderRadius: 20,
    backgroundColor: "#46BA53",
    paddingVertical: 18,
    alignItems: "center",
  },
  playButtonText: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
});
