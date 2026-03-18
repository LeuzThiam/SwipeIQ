import { Pressable, StyleSheet, Text, View } from "react-native";

type Props = {
  title: string;
  subtitle: string;
  accent: string;
  icon: string;
  onBack: () => void;
};

export function InfoScreen({ title, subtitle, accent, icon, onBack }: Props) {
  return (
    <View style={styles.screen}>
      <Pressable onPress={onBack}>
        <Text style={[styles.back, { color: accent }]}>← Retour</Text>
      </Pressable>
      <View style={styles.content}>
        <Text style={[styles.icon, { color: accent }]}>{icon}</Text>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.subtitle}>{subtitle}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#F9FBFF", padding: 24 },
  back: { fontSize: 16, fontWeight: "700" },
  content: { flex: 1, alignItems: "center", justifyContent: "center" },
  icon: { fontSize: 80, marginBottom: 14 },
  title: { fontSize: 30, fontWeight: "800" },
  subtitle: { marginTop: 8, fontSize: 18, textAlign: "center" },
});
