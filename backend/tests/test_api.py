from django.test import TestCase
from rest_framework.authtoken.models import Token


class ApiTests(TestCase):
    def authenticate_guest(self):
        response = self.client.post(
            "/api/auth/guest/",
            data={"displayName": "Modou"},
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 201)
        token = response.json()["token"]
        self.client.defaults["HTTP_AUTHORIZATION"] = f"Token {token}"
        return token

    def test_health(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_questions(self):
        response = self.client.get("/api/questions/?limit=1")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIn("items", body)
        self.assertIn("meta", body)
        self.assertLessEqual(len(body["items"]), 1)
        self.assertEqual(body["meta"]["limit"], 1)

    def test_questions_invalid_limit_falls_back_to_default(self):
        response = self.client.get("/api/questions/?limit=abc")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["meta"]["limit"], 20)

    def test_questions_limit_is_clamped(self):
        response = self.client.get("/api/questions/?limit=200")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["meta"]["limit"], 50)

    def test_questions_filter_by_theme(self):
        response = self.client.get("/api/questions/?theme=general")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(all(item["theme"] == "general" for item in body["items"]))

    def test_stats(self):
        response = self.client.get("/api/stats/")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIn("totalQuestions", body)
        self.assertIn("themes", body)
        self.assertIn("levels", body)

    def test_leaderboard(self):
        self.authenticate_guest()
        response = self.client.get("/api/leaderboard/?period=weekly")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["period"], "weekly")
        self.assertIn("entries", body)
        self.assertGreaterEqual(len(body["entries"]), 1)
        self.assertTrue(any(entry["isCurrentUser"] for entry in body["entries"]))

    def test_profile(self):
        self.authenticate_guest()
        response = self.client.get("/api/profile/")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["name"], "Modou")
        self.assertIn("availableThemes", body)
        self.assertIn("dailyGoals", body)
        self.assertTrue(body["isGuest"])

    def test_quiz_result_persists_and_updates_profile(self):
        self.authenticate_guest()
        response = self.client.post(
            "/api/quiz-results/",
            data={
                "mode": "theme",
                "theme": "general",
                "level": "facile",
                "lang": "fr",
                "totalQuestions": 5,
                "correctAnswers": 4,
                "bestStreak": 3,
                "scorePoints": 1000,
            },
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 201)
        body = response.json()
        self.assertTrue(body["saved"])
        self.assertEqual(body["profile"]["xp"], 1000)
        self.assertEqual(body["profile"]["quizzesPlayed"], 1)
        self.assertEqual(body["leaderboard"]["currentUser"]["score"], 1000)

    def test_register_simple_account(self):
        response = self.client.post(
            "/api/auth/register/",
            data={"username": "modou", "password": "secret123", "displayName": "Modou"},
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 201)
        body = response.json()
        self.assertEqual(body["profile"]["username"], "modou")
        self.assertFalse(body["profile"]["isGuest"])

    def test_login_simple_account(self):
        self.client.post(
            "/api/auth/register/",
            data={"username": "modou", "password": "secret123", "displayName": "Modou"},
            content_type="application/json",
        )
        response = self.client.post(
            "/api/auth/login/",
            data={"username": "modou", "password": "secret123"},
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("token", response.json())

    def test_logout_revokes_token(self):
        token = self.authenticate_guest()
        response = self.client.post("/api/auth/logout/")
        self.assertEqual(response.status_code, 200)
        self.assertFalse(Token.objects.filter(key=token).exists())
