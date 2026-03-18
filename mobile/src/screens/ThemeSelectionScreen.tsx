import { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

const themes = [
  { label: "Culture generale", value: "culture_g", color: "#F7A900", icon: "💡" },
  { label: "Sciences", value: "sciences", color: "#49B95B", icon: "🧪" },
  { label: "Histoire", value: "histoire", color: "#C57A39", icon: "📚" },
  { label: "Geographie", value: "geographie", color: "#2CAFD2", icon: "🌍" },
  { label: "Sport", value: "sport", color: "#56B04C", icon: "⚽" },
  { label: "Cinema & series", value: "arts_pop", color: "#E4513A", icon: "🎬" },
  { label: "Technologie", value: "tech", color: "#2290D9", icon: "🤖" },
  { label: "Musique", value: "musique", color: "#8751E5", icon: "🎵" },
];

const levels = [
  { label: "Facile", value: "facile" },
  { label: "Moyen", value: "moyen" },
  { label: "Difficile", value: "difficile" },
];

const languages = [
  { label: "Francais", value: "fr" },
  { label: "Anglais", value: "en" },
];

type Props = {
  onBack: () => void;
  onStartQuiz: (params: { theme: string; level: string; lang: string; title: string }) => void;
};

export function ThemeSelectionScreen({ onBack, onStartQuiz }: Props) {
  const [selectedTheme, setSelectedTheme] = useState(themes[0]);
  const [selectedLevel, setSelectedLevel] = useState(levels[0].value);
  const [selectedLang, setSelectedLang] = useState(languages[0].value);

  function startThemeQuiz(theme = selectedTheme) {
    onStartQuiz({
      theme: theme.value,
      level: selectedLevel,
      lang: selectedLang,
      title: theme.label,
    });
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>

      <Text style={styles.title}>Choisir un theme</Text>
      <Text style={styles.subtitle}>Selectionne une categorie et lance ton quiz.</Text>

      <View style={styles.filterPanel}>
        <Text style={styles.filterTitle}>Parametres</Text>
        <View style={styles.filterSection}>
          <Text style={styles.filterLabel}>Niveau</Text>
          <View style={styles.chips}>
            {levels.map((level) => (
              <Pressable
                key={level.value}
                onPress={() => setSelectedLevel(level.value)}
                style={[styles.chip, level.value === selectedLevel ? styles.chipActive : null]}
              >
                <Text style={styles.chipText}>{level.label}</Text>
              </Pressable>
            ))}
          </View>
        </View>
        <View style={styles.filterSection}>
          <Text style={styles.filterLabel}>Langue</Text>
          <View style={styles.chips}>
            {languages.map((language) => (
              <Pressable
                key={language.value}
                onPress={() => setSelectedLang(language.value)}
                style={[styles.chip, language.value === selectedLang ? styles.chipActive : null]}
              >
                <Text style={styles.chipText}>{language.label}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      </View>

      <View style={styles.selectionCard}>
        <Text style={styles.selectionEyebrow}>Selection actuelle</Text>
        <View style={[styles.selectionThemeBadge, { backgroundColor: selectedTheme.color }]}>
          <Text style={styles.selectionThemeIcon}>{selectedTheme.icon}</Text>
          <Text style={styles.selectionThemeText}>{selectedTheme.label}</Text>
        </View>
        <Text style={styles.selectionSummary}>
          Niveau {selectedLevel} • Langue {selectedLang.toUpperCase()}
        </Text>
        <Pressable style={styles.launchButton} onPress={() => startThemeQuiz()}>
          <Text style={styles.launchButtonText}>LANCER CE THEME</Text>
        </Pressable>
      </View>

      <View style={styles.grid}>
        {themes.map((theme) => (
          <Pressable
            key={theme.value}
            style={[
              styles.themeCard,
              { backgroundColor: theme.color },
              theme.value === selectedTheme.value ? styles.themeCardActive : null,
            ]}
            onPress={() => setSelectedTheme(theme)}
          >
            <Text style={styles.themeIcon}>{theme.icon}</Text>
            <Text style={styles.themeLabel}>{theme.label}</Text>
            {theme.value === selectedTheme.value ? <Text style={styles.themeSelected}>Selectionne</Text> : null}
          </Pressable>
        ))}
      </View>

      <Pressable
        style={styles.randomCard}
        onPress={() => {
          const randomTheme = themes[Math.floor(Math.random() * themes.length)];
          startThemeQuiz(randomTheme);
        }}
      >
        <Text style={styles.randomIcon}>🎲</Text>
        <Text style={styles.randomLabel}>Aleatoire</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#07132E" },
  content: { padding: 16, gap: 14 },
  back: { color: "#7BE6FF", fontWeight: "700", fontSize: 16 },
  title: { color: "#fff", fontSize: 32, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 16 },
  filterPanel: {
    borderRadius: 20,
    backgroundColor: "rgba(20,47,102,0.72)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    padding: 16,
    gap: 12,
  },
  filterTitle: { color: "#fff", fontSize: 18, fontWeight: "800" },
  filterSection: { gap: 8 },
  filterLabel: { color: "rgba(255,255,255,0.8)", fontWeight: "700" },
  chips: { flexDirection: "row", gap: 8, flexWrap: "wrap" },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: "rgba(255,255,255,0.08)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
  },
  chipActive: {
    backgroundColor: "#1EA5FF",
    borderColor: "#7BE6FF",
  },
  chipText: { color: "#fff", fontWeight: "700" },
  selectionCard: {
    borderRadius: 24,
    backgroundColor: "rgba(8,24,66,0.92)",
    borderWidth: 1,
    borderColor: "rgba(123,230,255,0.22)",
    padding: 16,
    gap: 12,
  },
  selectionEyebrow: {
    color: "#7BE6FF",
    fontSize: 13,
    fontWeight: "800",
    letterSpacing: 1,
    textTransform: "uppercase",
  },
  selectionThemeBadge: {
    minHeight: 64,
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  selectionThemeIcon: { fontSize: 28 },
  selectionThemeText: { color: "#fff", fontSize: 24, fontWeight: "900", flex: 1 },
  selectionSummary: { color: "rgba(255,255,255,0.78)", fontSize: 15, fontWeight: "700" },
  launchButton: {
    borderRadius: 18,
    backgroundColor: "#1EA5FF",
    paddingVertical: 14,
    alignItems: "center",
  },
  launchButtonText: { color: "#fff", fontSize: 16, fontWeight: "900", letterSpacing: 0.6 },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    justifyContent: "space-between",
  },
  themeCard: {
    width: "48%",
    minHeight: 110,
    borderRadius: 24,
    padding: 14,
    borderWidth: 2,
    borderColor: "rgba(255,255,255,0.35)",
    justifyContent: "center",
  },
  themeCardActive: {
    borderColor: "#FFFFFF",
    borderWidth: 3,
  },
  themeIcon: { fontSize: 28, marginBottom: 10 },
  themeLabel: { color: "#fff", fontSize: 19, fontWeight: "800", lineHeight: 22 },
  themeSelected: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
    marginTop: 8,
    textTransform: "uppercase",
  },
  randomCard: {
    borderRadius: 28,
    backgroundColor: "#1E3E8C",
    borderWidth: 2,
    borderColor: "rgba(255,255,255,0.24)",
    paddingVertical: 18,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    gap: 10,
  },
  randomIcon: { fontSize: 28 },
  randomLabel: { color: "#fff", fontSize: 28, fontWeight: "900" },
});
