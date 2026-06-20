# 자가학습 운영법 — capture → distill → curate

L2(hindsight)/L3(런북)을 **실사용으로 자라게** 하는 루프. 핵심: 자동으로 적립하되
**사람(제이든)이 최종 큐레이션**.

```
capture (적립)  →  distill (증류)  →  curate (승격/수정)
  대화·Slack         런북 스킬           좋은 것만 Git
```

## 1. capture — 어디서 적립되나
- **봇과의 대화**: Slack/CLI에서 제이든과 나눈 대화는 세션 저장소(FTS5)+메모리로
  자동 적립. `memory.nudge_interval` 마다 "기억할 것"을 그래프에 적립.
- **개발 작업**: 코드 읽고 고친 맥락도 메모리에 들어간다.
- **씨앗**: `service-catalog.yaml` 1회 인제스트(memory-setup.md 3절).

## 2. Slack 대화를 학습시키기  ★요청 반영
Slack 채널 대화(사람들끼리)는 온콜/장애/결정의 보고. 단, **전부 넣으면 노이즈
폭발**이라 선택적으로.

### 2-1. 연결 (읽기용 Slack MCP)
온콜 알림 전송용 게이트웨이와 별개로, **채널을 읽어오는 Slack MCP**를 붙인다.
`config.yaml`의 `mcp_servers`에 추가(토큰은 `.env`):
```yaml
  slack:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-slack"]
    env:
      SLACK_BOT_TOKEN: "${SLACK_BOT_TOKEN}"
      SLACK_TEAM_ID: "${SLACK_TEAM_ID}"
      # 읽을 채널만 화이트리스트 (노이즈/프라이버시 통제)
      SLACK_CHANNEL_IDS: "${SLACK_CHANNEL_IDS}"   # 예: #oncall,#incidents,#app-dev
```
> 봇을 **읽힐 채널에만 초대**. `channels:history`, `search:read` 스코프 필요.

### 2-2. 무엇을 넣을까 (선별 규칙)
- ✅ **해결된 장애 스레드**(증상→원인→조치) → `incident` 엔티티
- ✅ **결정 스레드**("이렇게 가기로 함, 왜냐면") → `decision` 엔티티
- ✅ **"이거 어떻게 하지?→이렇게"** 문답 → 후보 `runbook`
- ❌ 잡담·일정조율·중복·미해결 스레드 → 넣지 않음
- ❌ 비밀/PII 포함 메시지 → 제외

### 2-3. 적립 방법 (2가지)
- **온디맨드(권장 시작점)**: 좋은 스레드를 보면 그 자리에서
  ```
  이 Slack 스레드(<링크/채널+ts>)를 읽고 incident 로 요약해서 메모리에 적립해줘:
  증상/원인/조치/관련 서비스/담당. service-catalog 의 incidents 형식으로.
  ```
- **주기 배치(나중)**: cron 으로 지정 채널의 최근 해결 스레드를 훑어 후보를
  뽑아 **내 home(DM)로 "적립 제안" 초안**만 보냄(자동 적립 X). 제이든이 승인한 것만 들어감.
  → 온콜 "초안 검토 후 전송" 원칙과 동일하게, **학습도 사람 승인 게이트**.

> 봇과 직접 나눈 대화는 자동 학습되지만, **사람들끼리의 채널 대화는 위처럼 선별
> 인제스트**가 안전하다.

## 3. distill — 런북 스킬로 증류
반복되는 절차는 대화에 묻어두지 말고 스킬로:
```
방금 한 example-app 5xx 대응 절차를 런북 스킬로 저장해줘.
이름 runbooks/example-app-5xx, 증상/확인순서/근거/에스컬레이션 포함.
```
저장 위치: `~/.hermes/profiles/work/skills/runbooks/<name>/SKILL.md`.
`skills.creation_nudge_interval` 이 복잡 작업 후 자동으로 이걸 유도한다.

## 4. curate — 승격/수정 (주 1회)
- `hermes -p work` 에서 `/skills`·`/memory` 로 훑기.
- **좋은 런북**: `~/.hermes/.../skills/runbooks/<name>` → 이 레포 `personal/knowledge/runbooks/`
  로 복사 후 커밋 → 기기 바뀌어도 생존 + 팀 공유 가능.
- **틀린 사실**: hindsight UI 또는 `/memory` 로 수정/삭제(사람이 최종 권위).
- `service-catalog.yaml` 에 새로 확정된 service/decision 반영 후 재인제스트.

## 요약
Slack·대화·개발 → (선별·승인) → L2 그래프/RAG 적립 → 반복 절차는 L3 런북 →
주 1회 좋은 것만 Git 승격. **자동으로 모으되, 들어갈지는 제이든이 결정.**
