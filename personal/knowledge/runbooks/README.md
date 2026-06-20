# Runbooks (승격 보관소)

`~/.hermes/profiles/work/skills/runbooks/` 에서 자가학습으로 만들어진 런북 스킬 중
**검증된 것만 이리로 복사·커밋**한다(기기 교체에도 생존 + 공유).

`config.yaml` 의 `skills.external_dirs` 로 런타임에서 이 폴더를 읽게 연결할 수 있다.

## 런북 SKILL.md 권장 형식
```markdown
---
name: example-app-5xx
description: example-app 5xx 급증 대응 절차
---
## 증상
- 5xx 비율 급등 / p99 지연 상승
## 확인 순서
1. <대시보드/로그 위치>
2. 의존성(auth-api, postgres-main) 상태
## 흔한 원인 → 조치
- 커넥션풀 고갈 → 풀 상향
## 에스컬레이션
- 30분 내 미해결 시 → 플랫폼팀 @owner
## 근거/이력
- INC-2026-06-15-auth-timeout, Slack 스레드 링크
```
