# 작업 지시서 — 제이든 전용 업무 에이전트 로컬 구축

> 이 문서 하나로 로컬에서 전체 컨셉을 구축한다. **사람이 따라 해도 되고, 로컬
> 에이전트(Claude Code 등)에게 넘겨 단계 실행시켜도 된다.**
> 표기: 🤖=에이전트/사람 누구나 실행 · 🔑=토큰 입력(사람) · 🌐=브라우저 OAuth(사람)
> 원칙: **비밀은 절대 커밋 X · 외부로 나가는 동작은 사람 승인 후**.

---

## 0. 목표 (이 에이전트가 하는 일)
회사 업무용 개인 에이전트. 5가지: **개발 / 온콜대응 / 의사결정 / 히스토리 검색 /
할일 관리**. 지식은 **온톨로지 + RAG + 자가학습**으로 시간이 갈수록 두꺼워진다.

- 연동: **GitHub · Jira · Notion · Slack**
- 코드 접근: 회사 레포에 원격 직접연결 X → **작업할 때 로컬 경로를 준다**
- 온콜: 자동 발송 X → **에이전트가 답변 초안 → 제이든이 점검 후 직접 전송**
- 구조 상세: `personal/knowledge/README.md` (L1 원본 / L2 hindsight 그래프+RAG /
  L3 런북 스킬 / L4 자가학습 루프)

## 사전 준비물 (🔑 미리 발급)
- 모델 키 1개: `ANTHROPIC_API_KEY` 또는 `OPENROUTER_API_KEY` 또는 Nous Portal 로그인
- `GITHUB_TOKEN` (repo, read:org)
- Jira: `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`
- Slack 앱: `SLACK_BOT_TOKEN`(xoxb), `SLACK_APP_TOKEN`(xapp), 팀ID, 읽을 채널ID
- Notion: 대부분 OAuth(브라우저)라 키 불필요

---

## 1. 코드 가져오기 🤖
이 설정이 들어있는 브랜치를 로컬에 받는다.
```bash
git clone <이 레포 URL> hermes-agent
cd hermes-agent
git checkout claude/personal-agent-setup-25rd15
```

### (선택) 내 private 레포로 분리 🤖
개인 프로젝트로 떼어내려면 — 포크는 바로 private 전환이 안 되니 새 레포로 미러:
```bash
# GitHub 웹에서 빈 private 레포 생성: jaden680/hermes-personal
git clone --bare <이 레포 URL> tmp.git
cd tmp.git && git push --mirror https://github.com/jaden680/hermes-personal.git && cd ..
# 작업본 remote 교체
git remote set-url origin https://github.com/jaden680/hermes-personal.git
# 업스트림 업데이트가 필요하면:
git remote add upstream https://github.com/NousResearch/hermes-agent.git
```
> `personal/` 설정만 가벼운 별도 레포로 두고 싶으면, 그 디렉터리만 새 repo로 옮겨도 된다.

## 2. Hermes 설치 🤖
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.bashrc        # 또는 ~/.zshrc
hermes --version
```

## 3. work 프로필 설치 🤖
코어는 안 건드리고 내 프로필만 `~/.hermes/profiles/work/` 로 깐다.
```bash
bash personal/apply.sh
```
**확인:** `~/.hermes/profiles/work/{config.yaml,SOUL.md,USER.md,.env}` 존재.

## 4. 시크릿 채우기 🔑
```bash
$EDITOR ~/.hermes/profiles/work/.env     # 사전 준비물의 토큰들 입력
```
**확인:** GitHub/Jira/Slack/모델 키가 채워짐. (이 파일은 git에 안 올라감)

## 5. 모델/제공자 🌐🔑
```bash
hermes -p work model            # 제공자·모델 선택 (또는 Nous: hermes -p work login)
```
**확인:** `hermes -p work -m "1+1?"` 가 정상 응답.

## 6. L2 메모리(hindsight) 켜기 🤖🔑
온톨로지+RAG 엔진. `local_embedded` = 추가 키 불필요(모델 키 사용), 데이터 로컬.
```bash
hermes -p work memory setup     # "hindsight" → "local_embedded" 선택
```
상세: `personal/knowledge/memory-setup.md`.
**확인:** `hermes -p work config get memory.provider` → `hindsight`.

## 7. MCP 연동 확인 🌐
`config.yaml`에 GitHub/Notion/Jira MCP가 이미 정의됨. Notion은 최초 1회 OAuth.
```bash
hermes -p work doctor           # 연동/도구 상태 점검
```
Slack을 **읽기 소스**로도 쓰려면(대화 학습용) `personal/knowledge/capture-distill.md`
2-1절의 `slack` MCP 블록을 `config.yaml`에 추가하고 `.env`에 채널ID 입력.
**확인:** doctor 에 github/notion/jira(및 slack) 가 OK.

## 8. 씨앗 온톨로지 입력 🤖
```bash
$EDITOR personal/knowledge/service-catalog.yaml   # 아는 서비스 3~5개만 채움
# L2로 1회 인제스트:
hermes -p work -m "personal/knowledge/service-catalog.yaml 를 읽고 각 엔티티를 메모리에 적립/갱신해줘."
```
**확인:** `hermes -p work -m "example-app 담당자/의존성 알려줘"` 가 카탈로그대로 답함.

## 9. Slack 게이트웨이 (온콜 초안 모드) 🔑
```bash
hermes -p work gateway setup    # Slack bot/app 토큰 등록
hermes -p work gateway start    # 상주 (서버면 systemd 권장)
```
**확인:** Slack에서 봇에게 DM/스레드로 질문 → **답변 초안**이 옴(자동 채널 발송 X).

## 10. 자동화 등록 (나에게만 가는 요약) 🤖
```bash
# 채널/일정 확인 후:
bash personal/automations.sh
hermes -p work cron list
```
**확인:** 아침 브리핑/주간 회고 cron 2건 등록(내 home/DM 대상).

---

## 11. 운영 루프 (자가학습) — 평소 사용법
`personal/knowledge/capture-distill.md` 대로:
- **capture**: 봇과의 대화·개발 맥락은 자동 적립. Slack 채널 대화는 **선별 인제스트
  (사람 승인 게이트)**.
- **distill**: 반복 절차는 "런북 스킬로 저장해줘"로 L3 증류.
- **curate(주 1회)**: `/skills`·`/memory` 훑고, **좋은 런북 → `personal/knowledge/runbooks/`
  로 복사·커밋**, 틀린 사실은 수정. 새 결정은 `service-catalog.yaml`에 반영 후 재인제스트.

## 12. 완료 체크리스트 ✅
- [ ] `hermes -p work` 정상 대화
- [ ] `doctor` 에서 GitHub/Jira/Notion(+Slack) OK
- [ ] `memory.provider = hindsight`, 카탈로그 회수 동작
- [ ] Slack에서 봇이 **초안**으로 답하고 자동 발송 안 함
- [ ] cron 2건 등록, 비밀(.env)은 커밋 안 됨

## 가드레일 (꼭)
- `.env`·비밀·PII는 메모리/스킬/Git에 넣지 않는다(원본 시스템·`.env`에만).
- 온콜/외부 메시지는 **에이전트가 초안까지만**, 전송은 제이든.
- 자동 적립분은 **사람이 검토 후** 좋은 것만 Git 승격(사람이 최종 권위).
- 회사 코드는 **제이든이 준 로컬 경로**로만 접근.
```
참고 파일:
  personal/README.md                  ← 셋업·DB관리·자가학습 개요
  personal/knowledge/README.md        ← 4계층 구조
  personal/knowledge/memory-setup.md  ← hindsight 셋업
  personal/knowledge/capture-distill.md ← 자가학습/Slack 학습
  personal/knowledge/service-catalog.yaml ← 씨앗 온톨로지
```
