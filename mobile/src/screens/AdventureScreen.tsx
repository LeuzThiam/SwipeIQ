import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

type Props = {
  onBack: () => void;
  onStartLevel: (title: string) => void;
};

const levels = Array.from({ length: 10 }, (_, index) => ({
  id: index + 1,
  title: `Niveau ${index + 1}`,
  theme: ["Culture generale", "Sciences", "Histoire", "Technologie"][index % 4],
  difficulty: index < 3 ? "FACILE" : index < 7 ? "MOYEN" : "DIFFICILE",
  questions: index < 3 ? 5 : index < 7 ? 7 : 9,
  unlocked: index < 4,
}));

export function AdventureScreen({ onBack, onStartLevel }: Props) {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>
      <Text style={styles.title}>Aventure</Text>
      <Text style={styles.subtitle}>Carte des niveaux et progression.</Text>

      <View style={styles.panel}>
        <Text style={styles.panelTitle}>Progression aventure</Text>
        <View style={styles.track}>
          <View style={styles.fill} />
        </View>
        <Text style={styles.panelMeta}>4/10 niveaux • 9 etoiles • 1240 points</Text>
      </View>

      {levels.map((level) => (
        <Pressable
          key={level.id}
          style={[styles.levelCard, !level.unlocked ? styles.locked : null]}
          onPress={() => level.unlocked && onStartLevel(level.title)}
          disabled={!level.unlocked}
        >
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{level.id}</Text>
          </View>
          <View style={styles.body}>
            <Text style={styles.levelTitle}>{level.title}</Text>
            <Text style={styles.levelMeta}>
              {level.theme} • {level.difficulty} • {level.questions} questions
            </Text>
          </View>
          <Text style={styles.cta}>{level.unlocked ? "▶" : "🔒"}</Text>
        </Pressable>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#071B4D" },
  content: { padding: 16, gap: 10 },
  back: { color: "#7BE6FF", fontWeight: "700", fontSize: 16 },
  title: { color: "#fff", fontSize: 32, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 16, marginBottom: 8 },
  panel: {
    borderRadius: 16,
    padding: 14,
    backgroundColor: "rgba(20,47,102,0.72)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.24)",
  },
  panelTitle: { color: "#fff", fontWeight: "800", fontSize: 16 },
  track: { marginTop: 10, height: 10, borderRadius: 20, backgroundColor: "rgba(255,255,255,0.12)", overflow: "hidden" },
  fill: { width: "40%", height: "100%", backgroundColor: "#34C94A" },
  panelMeta: { marginTop: 10, color: "#7BE6FF", fontWeight: "700" },
  levelCard: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderRadius: 16,
    padding: 14,
    backgroundColor: "rgba(22,53,110,0.8)",
  },
  locked: { opacity: 0.5 },
  badge: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "rgba(0,255,255,0.15)",
    alignItems: "center",
    justifyContent: "center",
  },
  badgeText: { color: "#7BE6FF", fontWeight: "900", fontSize: 18 },
  body: { flex: 1 },
  levelTitle: { color: "#fff", fontWeight: "800", fontSize: 19 },
  levelMeta: { color: "rgba(255,255,255,0.72)", marginTop: 2 },
  cta: { color: "#7BE6FF", fontSize: 22 },
});
