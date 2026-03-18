import { StatusBar } from "expo-status-bar";
import { useEffect, useState } from "react";
import { BackHandler, SafeAreaView, StyleSheet } from "react-native";

import { AdventureScreen } from "./src/screens/AdventureScreen";
import { AuthScreen } from "./src/screens/AuthScreen";
import { DailyChallengeScreen } from "./src/screens/DailyChallengeScreen";
import { FeedScreen } from "./src/screens/FeedScreen";
import { HomeScreen } from "./src/screens/HomeScreen";
import { InfoScreen } from "./src/screens/InfoScreen";
import { LeaderboardScreen } from "./src/screens/LeaderboardScreen";
import { ProfileScreen } from "./src/screens/ProfileScreen";
import { QuickQuizIntroScreen } from "./src/screens/QuickQuizIntroScreen";
import { ThemeSelectionScreen } from "./src/screens/ThemeSelectionScreen";
import { logoutCurrentSession, setAuthToken, type AuthSession } from "./src/services/swipeiqApi";

type Route =
  | { name: "home" }
  | { name: "adventure" }
  | { name: "daily-challenge" }
  | { name: "quick-intro" }
  | { name: "leaderboard" }
  | { name: "profile" }
  | { name: "theme-selection" }
  | {
      name: "quiz";
      title: string;
      mode: "theme" | "quick" | "adventure" | "daily";
      theme?: string;
      level?: string;
      lang?: string;
    }
  | { name: "info"; title: string; subtitle: string; accent: string; icon: string };

export default function App() {
  const [session, setSession] = useState<AuthSession | null>(null);
  const [history, setHistory] = useState<Route[]>([{ name: "home" }]);
  const route = history[history.length - 1];

  function pushRoute(nextRoute: Route) {
    setHistory((current) => [...current, nextRoute]);
  }

  function goBack() {
    setHistory((current) => {
      if (current.length <= 1) {
        return current;
      }
      return current.slice(0, -1);
    });
  }

  function goHome() {
    setHistory([{ name: "home" }]);
  }

  function handleAuthenticated(nextSession: AuthSession) {
    setAuthToken(nextSession.token);
    setSession(nextSession);
    setHistory([{ name: "home" }]);
  }

  async function handleLogout() {
    await logoutCurrentSession();
    setAuthToken(null);
    setSession(null);
    setHistory([{ name: "home" }]);
  }

  useEffect(() => {
    const subscription = BackHandler.addEventListener("hardwareBackPress", () => {
      if (history.length > 1) {
        goBack();
        return true;
      }
      return false;
    });

    return () => subscription.remove();
  }, [history.length]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      {!session ? <AuthScreen onAuthenticated={handleAuthenticated} /> : null}
      {session && route.name === "home" ? (
        <HomeScreen
          onOpenAdventure={() => pushRoute({ name: "adventure" })}
          onOpenThemeQuiz={() => pushRoute({ name: "theme-selection" })}
          onOpenQuickQuiz={() => pushRoute({ name: "quick-intro" })}
          onOpenDailyChallenge={() => pushRoute({ name: "daily-challenge" })}
          onOpenLeaderboard={() => pushRoute({ name: "leaderboard" })}
          onOpenProfile={() => pushRoute({ name: "profile" })}
        />
      ) : null}
      {session && route.name === "theme-selection" ? (
        <ThemeSelectionScreen
          onBack={goBack}
          onStartQuiz={(params) =>
            pushRoute({
              name: "quiz",
              title: params.title,
              mode: "theme",
              theme: params.theme,
              level: params.level,
              lang: params.lang,
            })
          }
        />
      ) : null}
      {session && route.name === "adventure" ? (
        <AdventureScreen
          onBack={goBack}
          onStartLevel={(title) => pushRoute({ name: "quiz", title, mode: "adventure" })}
        />
      ) : null}
      {session && route.name === "quick-intro" ? (
        <QuickQuizIntroScreen
          onBack={goBack}
          onStart={() => pushRoute({ name: "quiz", title: "Quiz rapide", mode: "quick" })}
        />
      ) : null}
      {session && route.name === "daily-challenge" ? (
        <DailyChallengeScreen
          onBack={goBack}
          onStart={() => pushRoute({ name: "quiz", title: "Defi du jour", mode: "daily" })}
        />
      ) : null}
      {session && route.name === "quiz" ? (
        <FeedScreen
          title={route.title}
          mode={route.mode}
          theme={route.theme}
          level={route.level}
          lang={route.lang}
          onBack={goBack}
          onExitHome={goHome}
        />
      ) : null}
      {session && route.name === "leaderboard" ? <LeaderboardScreen onBack={goBack} /> : null}
      {session && route.name === "profile" ? <ProfileScreen onBack={goBack} onLogout={handleLogout} /> : null}
      {session && route.name === "info" ? (
        <InfoScreen
          title={route.title}
          subtitle={route.subtitle}
          accent={route.accent}
          icon={route.icon}
          onBack={goBack}
        />
      ) : null}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#07132E",
  },
});
