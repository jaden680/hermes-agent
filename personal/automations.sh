#!/usr/bin/env bash
# =============================================================================
# 업무용 자동화 — 온콜/리포트는 모두 Slack 으로 전달.
# 실행 전: hermes 게이트웨이에 Slack 이 붙어 있어야 함.
#   hermes -p work gateway setup     # Slack bot/app 토큰 입력
#   hermes -p work gateway start     # 게이트웨이 기동 (백그라운드 권장)
# 그런 다음 이 스크립트를 실행해 cron/webhook 을 등록.
# ※ 채널/일정/저장소는 본인 환경에 맞게 수정한 뒤 실행하세요.
# =============================================================================
set -euo pipefail
P="hermes -p work"

# ── 1) 아침 브리핑 (평일 09:00) → Slack ──────────────────────────────────────
# 어제~오늘 내 Jira 이슈, 리뷰 대기 PR, 오늘 할일을 한 화면에 요약.
$P cron create "0 9 * * 1-5" \
  "오늘 업무 브리핑을 작성해줘: (1) 나에게 할당된 열린 Jira 이슈, (2) 내 리뷰가 필요한 GitHub PR, (3) Notion의 오늘 할일. 핵심만 불릿으로, 우선순위 순." \
  --name "Morning brief" \
  --skills "github" \
  --deliver slack

# ── 2) 온콜 알림 트리아지 (webhook) → Slack ──────────────────────────────────
# 알림 시스템(Datadog/PagerDuty/Grafana 등)에서 이 webhook 으로 POST.
# 페이로드 필드명({alert.name} 등)은 본인 알림 소스에 맞게 조정.
$P webhook subscribe oncall-triage \
  --prompt "온콜 알림: {alert.name} (심각도 {alert.severity}). 담당 서비스를 찾고, 최근 배포/관련 PR을 확인하고, 영향 범위와 즉시 취할 첫 조치를 제안해줘. 추측은 근거와 함께." \
  --skills "github" \
  --deliver slack

# ── 3) GitHub PR 리뷰 보조 (webhook) → Slack ─────────────────────────────────
# 내 저장소에 PR 이 열리면 요약 + 리스크 포인트를 Slack 으로.
$P webhook subscribe pr-summary \
  --events "pull_request" \
  --prompt "PR #{pull_request.number}: {pull_request.title} (by {pull_request.user.login}). 변경 요약과 리뷰 시 주의할 리스크 3가지를 알려줘." \
  --deliver slack

# ── 4) 주간 히스토리 다이제스트 (월 08:30) → Slack ───────────────────────────
# 지난 주 대화/작업 히스토리를 검색·요약 (자가 세션 검색 활용).
$P cron create "30 8 * * 1" \
  "지난 7일 동안 내가 한 작업을 세션 히스토리에서 검색해 요약해줘. 끝낸 것, 진행 중인 것, 막힌 것으로 분류." \
  --name "Weekly recap" \
  --deliver slack

echo "✅ 자동화 등록 완료. 확인:  hermes -p work cron list  /  hermes -p work webhook list"
