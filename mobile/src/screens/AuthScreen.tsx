import { useMemo, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";

import {
  continueAsGuest,
  loginSimpleAccount,
  registerSimpleAccount,
  type AuthSession,
} from "../services/swipeiqApi";

type AuthMode = "guest" | "register" | "login";

const modeContent: Record<
  AuthMode,
  { title: string; kicker: string; description: string; accent: string; button: string; icon: string }
> = {
  guest: {
    title: "Entrer instantanement",
    kicker: "Mode invite",
    description: "Une seule info, et tu commences la partie sans friction.",
    accent: "#38D667",
    button: "JOUER MAINTENANT",
    icon: "⚡",
  },
  register: {
    title: "Creer ton profil",
    kicker: "Compte simple",
    description: "Sauvegarde ta progression, ton rang et tes scores d'une session a l'autre.",
    accent: "#2CB7FF",
    button: "CREER MON COMPTE",
    icon: "◎",
  },
  login: {
    title: "Reprendre ta progression",
    kicker: "Connexion",
    description: "Reconnecte-toi et retrouve ton niveau, ton profil et ton classement.",
    accent: "#F7A900",
    button: "SE CONNECTER",
    icon: "★",
  },
};

export function AuthScreen({ onAuthenticated }: { onAuthenticated: (session: AuthSession) => void }) {
  const [mode, setMode] = useState<AuthMode>("guest");
  const [displayName, setDisplayName] = useState("Joueur");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const activeMode = modeContent[mode];
  const canSubmit = useMemo(() => {
    if (mode === "guest") {
      return displayName.trim().length >= 2;
    }
    if (mode === "register") {
      return displayName.trim().length >= 2 && username.trim().length >= 3 && password.length >= 4;
    }
    return username.trim().length >= 3 && password.length >= 4;
  }, [displayName, mode, password, username]);

  async function submit() {
    if (!canSubmit) {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      if (mode === "guest") {
        onAuthenticated(await continueAsGuest(displayName.trim()));
        return;
      }

      if (mode === "register") {
        onAuthenticated(await registerSimpleAccount(username.trim(), password, displayName.trim()));
        return;
      }

      onAuthenticated(await loginSimpleAccount(username.trim(), password));
    } catch (authError) {
      setError(authError instanceof Error ? authError.message : "Authentification impossible.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
      <View style={styles.hero}>
        <View style={styles.heroGlowA} />
        <View style={styles.heroGlowB} />
        <Text style={styles.brand}>SwipeIQ</Text>
        <View style={styles.heroBadge}>
          <Text style={styles.heroBadgeText}>LIVE QUIZ ARENA</Text>
        </View>
        <Text style={styles.title}>Entre dans le jeu</Text>
        <Text style={styles.subtitle}>
          Choisis un acces rapide pour jouer maintenant, ou un compte simple pour garder ton evolution.
        </Text>
      </View>

      <View style={styles.selectorCard}>
        <Text style={styles.selectorTitle}>Choisir ton entree</Text>
        <View style={styles.modeGrid}>
          {(["guest", "register", "login"] as const).map((modeKey) => (
            <ModeCard
              key={modeKey}
              label={modeContent[modeKey].kicker}
              icon={modeContent[modeKey].icon}
              accent={modeContent[modeKey].accent}
              active={mode === modeKey}
              onPress={() => setMode(modeKey)}
            />
          ))}
        </View>
      </View>

      <View style={[styles.formCard, { borderColor: `${activeMode.accent}66` }]}>
        <View style={styles.formHeader}>
          <View style={[styles.formIconWrap, { backgroundColor: `${activeMode.accent}22` }]}>
            <Text style={styles.formIcon}>{activeMode.icon}</Text>
          </View>
          <View style={styles.formHeaderText}>
            <Text style={[styles.formKicker, { color: activeMode.accent }]}>{activeMode.kicker}</Text>
            <Text style={styles.formTitle}>{activeMode.title}</Text>
            <Text style={styles.formDescription}>{activeMode.description}</Text>
          </View>
        </View>

        {mode !== "login" ? (
          <Field
            label="Pseudo visible"
            value={displayName}
            onChangeText={setDisplayName}
            placeholder="Ton pseudo de joueur"
          />
        ) : null}

        {mode !== "guest" ? (
          <>
            <Field
              label="Nom d'utilisateur"
              value={username}
              onChangeText={setUsername}
              placeholder="utilisateur"
              autoCapitalize="none"
            />
            <Field
              label="Mot de passe"
              value={password}
              onChangeText={setPassword}
              placeholder="mot de passe"
              secureTextEntry
            />
          </>
        ) : null}

        <Pressable
          style={[
            styles.primaryButton,
            { backgroundColor: activeMode.accent },
            !canSubmit || loading ? styles.primaryButtonDisabled : null,
          ]}
          onPress={() => submit().catch(() => undefined)}
          disabled={!canSubmit || loading}
        >
          {loading ? (
            <ActivityIndicator size="small" color="#07132E" />
          ) : (
            <Text style={styles.primaryButtonText}>{activeMode.button}</Text>
          )}
        </Pressable>

        {error ? <Text style={styles.error}>{error}</Text> : null}

        <View style={styles.footerHint}>
          <Text style={styles.footerHintTitle}>SSO ensuite</Text>
          <Text style={styles.footerHintText}>
            Google et Apple pourront se brancher proprement plus tard. Ici, je garde un flow de jeu mobile simple et solide.
          </Text>
        </View>
      </View>
    </ScrollView>
  );
}

function ModeCard({
  label,
  icon,
  accent,
  active,
  onPress,
}: {
  label: string;
  icon: string;
  accent: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      style={[
        styles.modeCard,
        active ? { borderColor: accent, backgroundColor: `${accent}22` } : null,
      ]}
      onPress={onPress}
    >
      <Text style={styles.modeCardIcon}>{icon}</Text>
      <Text style={styles.modeCardLabel}>{label}</Text>
    </Pressable>
  );
}

function Field({
  label,
  value,
  onChangeText,
  placeholder,
  secureTextEntry,
  autoCapitalize,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  secureTextEntry?: boolean;
  autoCapitalize?: "none" | "sentences" | "words" | "characters";
}) {
  return (
    <View style={styles.fieldBlock}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        style={styles.input}
        placeholder={placeholder}
        placeholderTextColor="rgba(255,255,255,0.35)"
        secureTextEntry={secureTextEntry}
        autoCapitalize={autoCapitalize}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#061137",
  },
  content: {
    paddingHorizontal: 18,
    paddingTop: 24,
    paddingBottom: 28,
    gap: 18,
  },
  hero: {
    borderRadius: 32,
    backgroundColor: "#0B1F5C",
    padding: 20,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
  },
  heroGlowA: {
    position: "absolute",
    top: -20,
    right: -10,
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: "rgba(44,183,255,0.18)",
  },
  heroGlowB: {
    position: "absolute",
    bottom: -36,
    left: -24,
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: "rgba(247,169,0,0.12)",
  },
  brand: {
    color: "#67D7FF",
    fontSize: 15,
    fontWeight: "900",
    textTransform: "uppercase",
    letterSpacing: 1.3,
  },
  heroBadge: {
    alignSelf: "flex-start",
    marginTop: 14,
    borderRadius: 999,
    backgroundColor: "rgba(255,255,255,0.1)",
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  heroBadgeText: {
    color: "#FFFFFF",
    fontWeight: "800",
    fontSize: 12,
    letterSpacing: 0.8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 38,
    fontWeight: "900",
    lineHeight: 42,
    marginTop: 16,
    maxWidth: 260,
  },
  subtitle: {
    color: "rgba(255,255,255,0.74)",
    fontSize: 16,
    lineHeight: 23,
    marginTop: 12,
    maxWidth: 300,
  },
  selectorCard: {
    borderRadius: 26,
    backgroundColor: "rgba(255,255,255,0.04)",
    padding: 14,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
  },
  selectorTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 12,
  },
  modeGrid: {
    flexDirection: "row",
    gap: 10,
  },
  modeCard: {
    flex: 1,
    minHeight: 92,
    borderRadius: 22,
    backgroundColor: "rgba(255,255,255,0.03)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
    padding: 12,
    justifyContent: "space-between",
  },
  modeCardIcon: {
    color: "#FFFFFF",
    fontSize: 24,
  },
  modeCardLabel: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "800",
    lineHeight: 18,
  },
  formCard: {
    borderRadius: 30,
    backgroundColor: "#132B6F",
    padding: 18,
    borderWidth: 1,
  },
  formHeader: {
    flexDirection: "row",
    gap: 14,
    marginBottom: 14,
  },
  formIconWrap: {
    width: 58,
    height: 58,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  formIcon: {
    color: "#FFFFFF",
    fontSize: 28,
  },
  formHeaderText: {
    flex: 1,
  },
  formKicker: {
    fontSize: 13,
    fontWeight: "900",
    textTransform: "uppercase",
    letterSpacing: 0.9,
  },
  formTitle: {
    color: "#FFFFFF",
    fontSize: 26,
    fontWeight: "900",
    marginTop: 4,
  },
  formDescription: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 15,
    lineHeight: 21,
    marginTop: 6,
  },
  fieldBlock: {
    marginTop: 10,
  },
  fieldLabel: {
    color: "rgba(255,255,255,0.86)",
    fontWeight: "800",
    marginBottom: 8,
  },
  input: {
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.1)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    color: "#FFFFFF",
    paddingHorizontal: 14,
    paddingVertical: 14,
    fontSize: 15,
  },
  primaryButton: {
    marginTop: 16,
    borderRadius: 20,
    paddingVertical: 16,
    alignItems: "center",
  },
  primaryButtonDisabled: {
    opacity: 0.45,
  },
  primaryButtonText: {
    color: "#07132E",
    fontWeight: "900",
    fontSize: 15,
    letterSpacing: 0.8,
  },
  error: {
    color: "#FFB4B4",
    fontWeight: "800",
    marginTop: 12,
    textAlign: "center",
  },
  footerHint: {
    marginTop: 16,
    borderRadius: 20,
    backgroundColor: "rgba(0,0,0,0.16)",
    padding: 14,
  },
  footerHintTitle: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "900",
  },
  footerHintText: {
    color: "rgba(255,255,255,0.7)",
    lineHeight: 21,
    marginTop: 6,
  },
});
