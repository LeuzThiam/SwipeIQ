import { Pressable, StyleSheet, Text, View } from "react-native";

type Props = {
  onBack: () => void;
  onStart: () => void;
};

export function QuickQuizIntroScreen({ onBack, onStart }: Props) {
  return (
    <View style={styles.screen}>
      <Pressable onPress={onBack}>
        <Text style={styles.back}>← Retour</Text>
      </Pressable>
      <Text style={styles.icon}>⚡</Text>
      <Text style={styles.title}>Quiz rapide</Text>
      <Text style={styles.subtitle}>10 questions aleatoires{"\n"}Teste tes connaissances rapidement !</Text>
      <View style={styles.info}>
        <Text style={styles.row}>Questions : <Text style={styles.value}>10</Text></Text>
        <Text style={styles.row}>Themes : <Text style={styles.value}>aleatoires</Text></Text>
        <Text style={styles.row}>Duree : <Text style={styles.value}>environ 2 minutes</Text></Text>
      </View>
      <Text style={styles.dice}>🎲</Text>
      <Pressable style={styles.button} onPress={onStart}>
        <Text style={styles.buttonText}>COMMENCER</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#071B4D", padding: 20 },
  back: { color: "#7BE6FF", fontWeight: "700", fontSize: 16 },
  icon: { color: "#FFC107", fontSize: 76, textAlign: "center", marginTop: 18 },
  title: { color: "#fff", fontSize: 38, fontWeight: "900", textAlign: "center", marginTop: 12 },
  subtitle: { color: "rgba(255,255,255,0.7)", fontSize: 18, lineHeight: 24, textAlign: "center", marginTop: 10 },
  info: {
    marginTop: 26,
    borderRadius: 18,
    padding: 16,
    backgroundColor: "rgba(20,47,102,0.72)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.24)",
  },
  row: { color: "#fff", fontWeight: "700", fontSize: 16, marginBottom: 6 },
  value: { color: "#7BE6FF", fontWeight: "400" },
  dice: { textAlign: "center", fontSize: 58, marginTop: "auto", marginBottom: 22 },
  button: { borderRadius: 16, backgroundColor: "#FF8A00", paddingVertical: 16, alignItems: "center" },
  buttonText: { color: "#fff", fontSize: 22, fontWeight: "900" },
});
