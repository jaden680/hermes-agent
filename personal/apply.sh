#!/usr/bin/env bash
# =============================================================================
# 업무용 "work" 프로필을 ~/.hermes 에 설치한다.
# 코어 소스는 건드리지 않는다 — 이 스크립트는 설정/정체성 파일만 복사한다.
# 사용법:  bash personal/apply.sh
# =============================================================================
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PROFILE_DIR="$HERMES_HOME/profiles/work"
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "→ 프로필 디렉터리 생성: $PROFILE_DIR"
mkdir -p "$PROFILE_DIR/skills"

# 덮어쓰기 전 백업
backup() { [ -f "$1" ] && cp "$1" "$1.bak.$(date +%s)" && echo "  (백업: $1.bak.*)"; true; }

for f in config.yaml SOUL.md USER.md; do
  backup "$PROFILE_DIR/$f"
  cp "$SRC/$f" "$PROFILE_DIR/$f"
  echo "  복사: $f"
done

# .env 는 시크릿이라 예시만 깔고, 없을 때만.
if [ ! -f "$PROFILE_DIR/.env" ]; then
  cp "$SRC/.env.example" "$PROFILE_DIR/.env"
  echo "  복사: .env  ← 실제 토큰을 채우세요: $PROFILE_DIR/.env"
else
  echo "  유지: 기존 .env (예시는 $SRC/.env.example 참고)"
fi

cat <<EOF

✅ 설치 완료. 다음 순서로 마무리하세요:

  1) 시크릿 채우기:   \$EDITOR $PROFILE_DIR/.env
  2) USER.md 내 정보로 채우기 (선택):  \$EDITOR $PROFILE_DIR/USER.md
  3) 프로필로 실행:   hermes -p work
  4) 도구 점검:       hermes -p work doctor
  5) 온콜/리포트 자동화:  bash $SRC/automations.sh   (먼저 파일 열어 채널/일정 확인)

EOF
