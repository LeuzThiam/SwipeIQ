import { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

import { fetchQuestions, fetchStats, submitQuizResult, type FeedStats } from "../services/swipeiqApi";
import type { Question } from "../types/question";

const SECONDS_PER_QUESTION = 45;

const choiceColors = ["#1EA5FF", "#34C94A", "#FFA726", "#F44336"];

export function FeedScreen({
  title,
  mode,
  theme,
  level,
  lang,
  onBack,
  onExitHome,
}: {
  title: string;
  mode: "theme" | "quick" | "adventure" | "daily";
  theme?: string;
  level?: string;
  lang?: string;
  onBack: () => void;
  onExitHome: () => void;
}) {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [stats, setStats] = useState<FeedStats | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [remainingSeconds, setRemainingSeconds] = useState(SECONDS_PER_QUESTION);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resultSaved, setResultSaved] = useState(false);
  const [resultSaveError, setResultSaveError] = useState<string | null>(null);
  const [savingResult, setSavingResult] = useState(false);

  async function loadQuestions(isRefresh = false) {
    if (isRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }

    try {
      const [questionsResponse, statsResponse] = await Promise.all([
        fetchQuestions({
          limit: mode === "adventure" ? 7 : mode === "daily" ? 5 : 10,
          theme: mode === "theme" ? theme ?? "culture_g" : mode === "daily" ? "general" : "general",
          level: mode === "adventure" ? "moyen" : mode === "daily" ? "moyen" : level ?? "facile",
          lang: lang ?? "fr",
        }),
        fetchStats(),
      ]);

      setQuestions(questionsResponse.items);
      setStats(statsResponse);
      setCurrentIndex(0);
      setAnswers({});
      setRemainingSeconds(SECONDS_PER_QUESTION);
      setShowResults(false);
      setResultSaved(false);
      setResultSaveError(null);
      setSavingResult(false);
      setError(null);
    } catch (loadError) {
      const message =
        loadError instanceof Error ? loadError.message : "Une erreur inconnue est survenue.";
      setError(message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadQuestions().catch(() => undefined);
  }, []);

  const currentQuestion = questions[currentIndex];
  const selectedChoice = currentQuestion ? answers[currentQuestion.id] : undefined;
  const isLocked = selectedChoice !== undefined;
  const score = questions.reduce((total, question) => {
    return total + (answers[question.id] === question.answer ? 1 : 0);
  }, 0);
  const answeredCount = Object.keys(answers).length;
  const bestStreak = useMemo(() => {
    let best = 0;
    let current = 0;
    for (const question of questions) {
      if (!(question.id in answers)) {
        continue;
      }
      if (answers[question.id] === question.answer) {
        current += 1;
        best = Math.max(best, current);
      } else {
        current = 0;
      }
    }
    return best;
  }, [answers, questions]);
  const currentStreak = useMemo(() => {
    let streak = 0;
    for (let index = 0; index <= currentIndex; index += 1) {
      const question = questions[index];
      if (!question || !(question.id in answers)) {
        break;
      }
      if (answers[question.id] === question.answer) {
        streak += 1;
      } else {
        streak = 0;
      }
    }
    return streak;
  }, [answers, currentIndex, questions]);
  const progressValue = questions.length === 0 ? 0 : (currentIndex + 1) / questions.length;

  useEffect(() => {
    if (!showResults || resultSaved || savingResult || questions.length === 0) {
      return;
    }

    setSavingResult(true);
    setResultSaveError(null);

    submitQuizResult({
      mode,
      theme: currentQuestion?.theme ?? theme ?? null,
      level: level ?? null,
      lang: lang ?? "fr",
      totalQuestions: questions.length,
      correctAnswers: score,
      bestStreak,
      scorePoints: score * 250,
    })
      .then(() => {
        setResultSaved(true);
      })
      .catch((submitError) => {
        setResultSaveError(
          submitError instanceof Error ? submitError.message : "Sauvegarde impossible.",
        );
      })
      .finally(() => {
        setSavingResult(false);
      });
  }, [bestStreak, currentQuestion?.theme, lang, level, mode, questions.length, resultSaved, savingResult, score, showResults, theme]);

  useEffect(() => {
    if (loading || showResults || !currentQuestion || isLocked) {
      return;
    }

    if (remainingSeconds <= 0) {
      goToNextQuestion();
      return;
    }

    const timeoutId = setTimeout(() => {
      setRemainingSeconds((current) => current - 1);
    }, 1000);

    return () => clearTimeout(timeoutId);
  }, [currentQuestion, isLocked, loading, remainingSeconds, showResults]);

  useEffect(() => {
    if (!isLocked || showResults) {
      return;
    }

    const timeoutId = setTimeout(() => {
      goToNextQuestion();
    }, 900);

    return () => clearTimeout(timeoutId);
  }, [currentIndex, isLocked, showResults]);

  function selectChoice(choiceIndex: number) {
    if (!currentQuestion || isLocked) {
      return;
    }

    setAnswers((current) => ({
      ...current,
      [currentQuestion.id]: choiceIndex,
    }));
  }

  function goToNextQuestion() {
    if (questions.length === 0) {
      return;
    }

    if (currentIndex >= questions.length - 1) {
      setShowResults(true);
      return;
    }

    setCurrentIndex((current) => current + 1);
    setRemainingSeconds(SECONDS_PER_QUESTION);
  }

  function skipQuestion() {
    if (!currentQuestion || isLocked) {
      return;
    }

    setAnswers((current) => ({
      ...current,
      [currentQuestion.id]: -1,
    }));
  }

  function restartQuiz() {
    loadQuestions().catch(() => undefined);
  }

  function feedbackForQuestion(question: Question | undefined) {
    if (!question) {
      return "";
    }

    const selected = answers[question.id];
    if (selected === undefined) {
      return "";
    }
    if (selected === question.answer) {
      return `Bonne reponse. ${question.explanation}`;
    }

    const correctChoice = question.choices[question.answer];
    return `Mauvaise reponse. Bonne reponse: ${correctChoice}. ${question.explanation}`;
  }

  if (loading) {
    return (
      <View style={styles.loadingScreen}>
        <View style={styles.loadingIcon}>
          <ActivityIndicator size="large" color="#7BE6FF" />
        </View>
        <Text style={styles.loadingTitle}>GENERATION EN COURS</Text>
        <Text style={styles.loadingText}>
          Le moteur prepare tes questions en fonction du theme selectionne.
        </Text>
        <View style={styles.loadingPill}>
          <Text style={styles.loadingPillText}>Connexion backend Django active</Text>
        </View>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.screen}>
        <View style={styles.errorCard}>
          <Text style={styles.errorIcon}>!</Text>
          <Text style={styles.errorHeading}>OUPS, ERREUR RESEAU</Text>
          <Text style={styles.errorMessage}>{error}</Text>
          <View style={styles.errorActions}>
            <Pressable style={[styles.actionButton, styles.retryButton]} onPress={() => loadQuestions().catch(() => undefined)}>
              <Text style={styles.actionButtonText}>REESSAYER</Text>
            </Pressable>
            <Pressable style={[styles.actionButton, styles.homeButton]} onPress={onExitHome}>
              <Text style={styles.actionButtonText}>ACCUEIL</Text>
            </Pressable>
          </View>
        </View>
      </View>
    );
  }

  if (showResults) {
    const incorrect = answeredCount - score;
    const successRate = questions.length === 0 ? 0 : Math.round((score * 100) / questions.length);
    const displayScore = score * 250;

    return (
      <ScrollView
        style={styles.screen}
        contentContainerStyle={styles.resultsContainer}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadQuestions(true).catch(() => undefined)} />}
      >
        <Text style={styles.resultsTheme}>{(currentQuestion?.theme ?? "quiz").toUpperCase()}</Text>
        <Text style={styles.resultsTitle}>ROUND COMPLETE!</Text>
        <View style={styles.resultsBadge}>
          <Text style={styles.resultsBadgeStar}>☆</Text>
        </View>
        <View style={styles.scoreBanner}>
          <Text style={styles.scoreBannerLabel}>FINAL SCORE: </Text>
          <Text style={styles.scoreBannerValue}>{displayScore}</Text>
        </View>
        <View style={styles.statsPanel}>
          <ResultStat label="Questions repondues" value={answeredCount} />
          <ResultStat label="Bonnes reponses" value={score} />
          <ResultStat label="Mauvaises reponses" value={incorrect} />
          <ResultStat label="Precision" value={`${successRate}%`} />
          <ResultStat label="Meilleure streak" value={bestStreak} />
        </View>
        <View style={styles.saveStatusCard}>
          {savingResult ? <Text style={styles.saveStatusText}>Sauvegarde du resultat...</Text> : null}
          {!savingResult && resultSaved ? (
            <Text style={styles.saveStatusText}>Resultat enregistre dans Django.</Text>
          ) : null}
          {!savingResult && resultSaveError ? (
            <Text style={styles.saveStatusError}>{resultSaveError}</Text>
          ) : null}
        </View>
        <View style={styles.resultsButtons}>
          <Pressable style={[styles.actionButton, styles.retryButton]} onPress={restartQuiz}>
            <Text style={styles.actionButtonText}>NEXT ROUND</Text>
          </Pressable>
          <Pressable style={[styles.actionButton, styles.homeButton]} onPress={onExitHome}>
            <Text style={styles.actionButtonText}>THEME SELECTION</Text>
          </Pressable>
        </View>
        <BottomStubBar />
      </ScrollView>
    );
  }

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.quizContainer}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadQuestions(true).catch(() => undefined)} />}
    >
      <Pressable onPress={onBack} style={styles.backButton}>
        <Text style={styles.backButtonText}>← Retour</Text>
      </Pressable>
      <Text style={styles.headerIcon}>◎</Text>
      <Text style={styles.screenTitle}>{title}</Text>
      <Text style={styles.themeLabel}>{(currentQuestion?.theme ?? "general").toUpperCase()}</Text>
      <Text style={styles.questionCounter}>
        Question {currentIndex + 1} / {questions.length}
      </Text>

      <View style={styles.progressRow}>
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progressValue * 100}%` }]} />
        </View>
        <View style={styles.timerPill}>
          <Text style={styles.timerText}>{formatTime(remainingSeconds)}</Text>
        </View>
      </View>

      <Text style={styles.questionText}>{currentQuestion?.question}</Text>

      <View style={styles.answerGrid}>
        {currentQuestion?.choices.map((choice, index) => {
          const isCorrect = currentQuestion.answer === index;
          const isWrongSelected = selectedChoice === index && selectedChoice !== currentQuestion.answer;
          const borderColor = isLocked && isCorrect ? "#69F0AE" : "rgba(255,255,255,0.55)";
          const extraStyle = isLocked && isWrongSelected ? styles.answerWrong : null;
          const glowStyle = isLocked && isCorrect ? styles.answerCorrect : null;

          return (
            <Pressable
              key={`${currentQuestion.id}-${index}`}
              style={[
                styles.answerCard,
                { backgroundColor: choiceColors[index] ?? "#8751E5", borderColor },
                extraStyle,
                glowStyle,
              ]}
              disabled={isLocked}
              onPress={() => selectChoice(index)}
            >
              <Text style={styles.answerText}>{choice}</Text>
              {isLocked && isCorrect ? <Text style={styles.answerStatus}>✓</Text> : null}
              {isLocked && isWrongSelected ? <Text style={styles.answerStatus}>✕</Text> : null}
            </Pressable>
          );
        })}
      </View>

      <Text style={styles.feedbackText}>{feedbackForQuestion(currentQuestion)}</Text>

      <View style={styles.scoreRow}>
        <View style={styles.pauseCircle}>
          <Text style={styles.pauseIcon}>II</Text>
        </View>
        <Text style={styles.scoreText}>SCORE: {score}</Text>
        <View style={styles.rowSpacer} />
        <Pressable style={[styles.smallButton, styles.skipButton]} onPress={skipQuestion} disabled={isLocked}>
          <Text style={styles.smallButtonText}>SKIP</Text>
        </Pressable>
        {isLocked ? (
          <Pressable style={[styles.smallButton, styles.nextButton]} onPress={goToNextQuestion}>
            <Text style={styles.smallButtonText}>{currentIndex === questions.length - 1 ? "FIN" : "SUIVANT"}</Text>
          </Pressable>
        ) : null}
      </View>

      <View style={styles.topMetaRow}>
        <Text style={styles.metaText}>Score {score}</Text>
        <Text style={styles.metaText}>Streak {currentStreak}</Text>
        <Text style={styles.metaText}>{stats?.totalQuestions ?? questions.length} total</Text>
      </View>

      <BottomStubBar />
    </ScrollView>
  );
}

function ResultStat({ label, value }: { label: string; value: string | number }) {
  return (
    <Text style={styles.resultStat}>
      <Text style={styles.resultBullet}>• </Text>
      {label}: {value}
    </Text>
  );
}

function BottomStubBar() {
  return (
    <View style={styles.bottomBar}>
      <BottomItem label="SETTINGS" icon="◌" />
      <BottomItem label="PROFILE" icon="◍" />
      <BottomItem label="STORE" icon="◈" />
      <BottomItem label="BONUS" icon="✦" />
    </View>
  );
}

function BottomItem({ icon, label }: { icon: string; label: string }) {
  return (
    <View style={styles.bottomItem}>
      <Text style={styles.bottomIcon}>{icon}</Text>
      <Text style={styles.bottomLabel}>{label}</Text>
    </View>
  );
}

function formatTime(totalSeconds: number) {
  const safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  const minutes = Math.floor(safeSeconds / 60);
  const seconds = safeSeconds % 60;
  return `${minutes}:${seconds < 10 ? `0${seconds}` : seconds}`;
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#07132E",
  },
  loadingScreen: {
    flex: 1,
    backgroundColor: "#07132E",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 24,
    gap: 16,
  },
  loadingIcon: {
    width: 90,
    height: 90,
    borderRadius: 45,
    borderWidth: 2,
    borderColor: "#7BE6FF",
    backgroundColor: "rgba(21,214,255,0.13)",
    alignItems: "center",
    justifyContent: "center",
  },
  loadingTitle: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1,
    textAlign: "center",
  },
  loadingText: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 17,
    textAlign: "center",
    lineHeight: 24,
  },
  loadingPill: {
    marginTop: 8,
    paddingHorizontal: 18,
    paddingVertical: 12,
    backgroundColor: "rgba(16,42,96,0.8)",
    borderRadius: 16,
  },
  loadingPillText: {
    color: "#FFFFFF",
    fontWeight: "700",
  },
  quizContainer: {
    paddingTop: 18,
    paddingBottom: 10,
  },
  backButton: {
    paddingHorizontal: 18,
  },
  backButtonText: {
    color: "#7BE6FF",
    fontWeight: "700",
    fontSize: 16,
  },
  headerIcon: {
    color: "#7BE6FF",
    textAlign: "center",
    fontSize: 28,
    marginBottom: 6,
  },
  screenTitle: {
    color: "rgba(255,255,255,0.78)",
    textAlign: "center",
    fontWeight: "700",
    fontSize: 18,
    marginBottom: 6,
  },
  themeLabel: {
    color: "#FFFFFF",
    textAlign: "center",
    fontWeight: "800",
    fontSize: 26,
    letterSpacing: 1,
  },
  questionCounter: {
    color: "rgba(255,255,255,0.7)",
    textAlign: "center",
    fontWeight: "700",
    fontSize: 14,
    marginTop: 6,
  },
  progressRow: {
    marginTop: 18,
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 22,
    gap: 10,
  },
  progressTrack: {
    flex: 1,
    height: 18,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.24)",
    overflow: "hidden",
  },
  progressFill: {
    height: "100%",
    backgroundColor: "#4FC3F7",
  },
  timerPill: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.12)",
  },
  timerText: {
    color: "#FFFFFF",
    fontWeight: "700",
    fontSize: 20,
  },
  questionText: {
    color: "#FFFFFF",
    textAlign: "center",
    fontWeight: "800",
    fontSize: 28,
    lineHeight: 34,
    paddingHorizontal: 24,
    marginTop: 26,
    marginBottom: 18,
  },
  answerGrid: {
    paddingHorizontal: 18,
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
    gap: 12,
  },
  answerCard: {
    width: "48%",
    minHeight: 92,
    borderRadius: 20,
    borderWidth: 2,
    paddingHorizontal: 14,
    paddingVertical: 10,
    justifyContent: "center",
    alignItems: "center",
  },
  answerCorrect: {
    borderWidth: 3,
    shadowColor: "#69F0AE",
    shadowOpacity: 0.5,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 0 },
  },
  answerWrong: {
    opacity: 0.82,
  },
  answerText: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "800",
    textAlign: "center",
  },
  answerStatus: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    marginTop: 8,
  },
  feedbackText: {
    minHeight: 64,
    color: "rgba(255,255,255,0.7)",
    fontSize: 18,
    textAlign: "center",
    paddingHorizontal: 20,
    marginTop: 12,
  },
  scoreRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 18,
    marginTop: 8,
  },
  pauseCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: "rgba(0,229,255,0.2)",
    alignItems: "center",
    justifyContent: "center",
  },
  pauseIcon: {
    color: "#7BE6FF",
    fontWeight: "900",
  },
  scoreText: {
    color: "#FFFFFF",
    fontWeight: "800",
    fontSize: 24,
    marginLeft: 14,
  },
  rowSpacer: {
    flex: 1,
  },
  smallButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 18,
    marginLeft: 8,
  },
  skipButton: {
    backgroundColor: "#E5484D",
  },
  nextButton: {
    backgroundColor: "#1EA5FF",
  },
  smallButtonText: {
    color: "#FFFFFF",
    fontWeight: "800",
  },
  topMetaRow: {
    marginTop: 14,
    flexDirection: "row",
    justifyContent: "space-around",
    paddingHorizontal: 18,
  },
  metaText: {
    color: "rgba(255,255,255,0.82)",
    fontWeight: "700",
  },
  bottomBar: {
    marginTop: 14,
    backgroundColor: "rgba(0,0,0,0.2)",
    paddingVertical: 12,
    paddingHorizontal: 18,
    flexDirection: "row",
    justifyContent: "space-around",
  },
  bottomItem: {
    alignItems: "center",
  },
  bottomIcon: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 18,
  },
  bottomLabel: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 11,
    letterSpacing: 0.4,
    marginTop: 4,
  },
  errorCard: {
    margin: 20,
    marginTop: "50%",
    paddingHorizontal: 20,
    paddingVertical: 22,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.24)",
    backgroundColor: "rgba(16,42,96,0.8)",
  },
  errorIcon: {
    color: "#FF6B6B",
    fontSize: 52,
    textAlign: "center",
    fontWeight: "900",
  },
  errorHeading: {
    color: "#FFFFFF",
    fontSize: 24,
    fontWeight: "900",
    letterSpacing: 0.8,
    textAlign: "center",
    marginTop: 10,
  },
  errorMessage: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 16,
    textAlign: "center",
    marginTop: 10,
  },
  errorActions: {
    flexDirection: "row",
    marginTop: 18,
    gap: 10,
  },
  actionButton: {
    flex: 1,
    borderRadius: 20,
    paddingVertical: 13,
    alignItems: "center",
  },
  retryButton: {
    backgroundColor: "#34C94A",
  },
  homeButton: {
    backgroundColor: "#1EA5FF",
  },
  actionButtonText: {
    color: "#FFFFFF",
    fontWeight: "800",
  },
  resultsContainer: {
    paddingTop: 18,
    paddingBottom: 14,
  },
  resultsTheme: {
    color: "#FFFFFF",
    textAlign: "center",
    fontSize: 32,
    fontWeight: "900",
    letterSpacing: 1,
  },
  resultsTitle: {
    color: "#FFFFFF",
    textAlign: "center",
    fontSize: 42,
    fontWeight: "900",
    marginTop: 20,
  },
  resultsBadge: {
    width: 130,
    height: 130,
    borderRadius: 65,
    marginTop: 16,
    alignSelf: "center",
    backgroundColor: "#102E6A",
    borderWidth: 4,
    borderColor: "#7BE6FF",
    alignItems: "center",
    justifyContent: "center",
  },
  resultsBadgeStar: {
    color: "#FFFFFF",
    fontSize: 72,
  },
  scoreBanner: {
    marginHorizontal: 24,
    marginTop: 18,
    paddingHorizontal: 24,
    paddingVertical: 16,
    borderRadius: 26,
    backgroundColor: "rgba(16,42,96,0.8)",
    flexDirection: "row",
    justifyContent: "center",
  },
  scoreBannerLabel: {
    color: "#FFFFFF",
    fontSize: 24,
    fontWeight: "900",
  },
  scoreBannerValue: {
    color: "#7BE6FF",
    fontSize: 24,
    fontWeight: "900",
  },
  statsPanel: {
    marginHorizontal: 24,
    marginTop: 14,
    paddingHorizontal: 24,
    paddingVertical: 18,
    borderRadius: 24,
    backgroundColor: "rgba(20,47,102,0.72)",
    gap: 8,
  },
  resultStat: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "700",
  },
  resultBullet: {
    color: "#7BE6FF",
    fontSize: 20,
  },
  resultsButtons: {
    flexDirection: "row",
    marginHorizontal: 24,
    marginTop: 16,
    gap: 12,
  },
  saveStatusCard: {
    marginHorizontal: 24,
    marginTop: 14,
    paddingHorizontal: 18,
    paddingVertical: 14,
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.06)",
  },
  saveStatusText: {
    color: "#7BE6FF",
    fontWeight: "800",
    textAlign: "center",
  },
  saveStatusError: {
    color: "#FFB4B4",
    fontWeight: "800",
    textAlign: "center",
  },
});
