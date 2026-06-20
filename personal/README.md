# 개인 업무용 Hermes 셋업 (`work` 프로필)

이 디렉터리는 **Hermes 코어를 전혀 건드리지 않고** 나만의 업무용 에이전트를
구성하기 위한 설정 한 벌입니다. 목적은 5가지 — **개발 / 온콜대응 / 의사결정 /
히스토리 검색 / 할일 관리** (회사 업무 우선). 연동 스택은 **GitHub · Jira ·
Notion · Slack**, 온콜 알림은 **Slack** 으로 받습니다.

> 왜 "삭제"가 아니라 "프로필"인가? Hermes는 설계상 **코어는 좁게 두고
> 플러그인·스킬·설정으로 확장**합니다(루트 `AGENTS.md` 참고). 소스를 지우면
> 업데이트를 못 받고 프레임워크가 깨집니다. 대신 `~/.hermes/profiles/work/`
> 라는 **격리된 내 프로필**을 만들면 모델·MCP·스킬·정체성이 전부 나에게만
> 적용됩니다. 안 쓰는 스킬은 지우지 않아도 **로드 시점에만 켜지므로** 비용/
> 성능에 영향이 없습니다.

---

## 1. 무엇이 들어있나

| 파일 | 적용 위치 | 역할 |
|---|---|---|
| `config.yaml` | `~/.hermes/profiles/work/config.yaml` | 모델·추론강도·도구셋·MCP(GitHub/Notion/Jira) |
| `SOUL.md` | `~/.hermes/profiles/work/SOUL.md` | 에이전트 정체성(일하는 방식). 시스템 프롬프트 **고정 슬롯** |
| `USER.md` | `~/.hermes/profiles/work/USER.md` | 나에 대한 프로필. **가변 슬롯**(세션 거치며 보강) |
| `.env.example` | `~/.hermes/profiles/work/.env` | 토큰/시크릿 (커밋 금지) |
| `apply.sh` | — | 위 파일들을 프로필로 설치 |
| `automations.sh` | — | 온콜 webhook + 아침브리핑/주간요약 cron (→ Slack) |

## 2. 설치 (내 PC/서버에서)

```bash
# 0) Hermes 설치가 안 됐다면:
#    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 1) 프로필 설치 (코어 안 건드림)
bash personal/apply.sh

# 2) 시크릿 채우기
$EDITOR ~/.hermes/profiles/work/.env       # GitHub/Jira/Slack 토큰

# 3) USER.md 내 정보로 채우기 (선택, 비워도 됨)
$EDITOR ~/.hermes/profiles/work/USER.md

# 4) 실행 — 항상 -p work 로
hermes -p work
hermes -p work doctor                      # 연동 점검
```

## 3. 온콜/리포트 자동화 (Slack)

```bash
hermes -p work gateway setup               # Slack bot/app 토큰 등록
hermes -p work gateway start               # 게이트웨이 기동
# automations.sh 열어 채널/일정/저장소 수정 후:
bash personal/automations.sh
hermes -p work cron list && hermes -p work webhook list
```

등록되는 것: 평일 아침 브리핑, 온콜 알림 트리아지, PR 요약, 주간 회고 — 전부 Slack.

## 4. 5가지 목적이 어디서 충족되나 (전부 내장)

| 목적 | 쓰는 기능 | 메모 |
|---|---|---|
| 개발 | 코어 코딩 에이전트 + `github` 스킬 + GitHub MCP | `hermes -p work` 에서 바로 |
| 온콜대응 | webhook(알림 트리아지) + cron + Slack 전달 | `automations.sh` |
| 의사결정 | 에이전트 + `SOUL.md`의 "추천+근거+트레이드오프" 규칙 | — |
| 히스토리 검색 | **FTS5 세션 검색**(과거 대화) + Notion/Jira MCP | "전에 이거 어떻게 했지?" 가능 |
| 할일 관리 | 내장 **todo** 도구 + `kanban` 플러그인 + Notion | 대화 중 할일 추적 |

---

## 5. 나만의 하네스 · 데이터베이스 관리 제안

### 데이터는 전부 `~/.hermes/` 한 곳에

Hermes의 모든 상태는 `HERMES_HOME`(기본 `~/.hermes`) 아래 SQLite/파일로 삽니다.
프로필을 쓰면 내 데이터가 `~/.hermes/profiles/work/` 로 **격리**됩니다.

```
~/.hermes/
├─ profiles/work/
│  ├─ config.yaml        # 이 레포에서 관리 (버전관리 O)
│  ├─ SOUL.md / USER.md  # 이 레포에서 관리 (버전관리 O)
│  ├─ .env               # 시크릿 (버전관리 X)
│  ├─ skills/            # 자가학습으로 쌓이는 스킬 (백업 대상)
│  └─ *.db               # 세션/메모리/cron SQLite (백업 대상)
```

**권장 관리 모델 — "설정은 Git, 데이터는 백업":**

1. **설정·정체성·스킬은 이 레포(`personal/`)에서 버전관리.** 바꾸면
   `apply.sh` 로 다시 밀어넣습니다. → 어느 기기에서도 동일한 내 에이전트 재현.
2. **시크릿(`.env`)은 절대 커밋 금지.** (`.gitignore`에 `personal/.env` 추가해 둠)
3. **런타임 DB는 정기 백업.** Hermes 내장 백업 사용:
   ```bash
   hermes -p work backup            # ~/.hermes 스냅샷 (cron으로 야간 자동화 가능)
   ```
   또는 `~/.hermes/profiles/work/` 를 private repo/오브젝트 스토리지로 rsync.
4. **"항상 켜둘" 거면 작은 VPS/서버에 올리고** 게이트웨이를 systemd로 상주
   시키세요. 그러면 노트북을 꺼도 온콜 webhook 이 살아있고, 어디서든 Slack 으로
   같은 에이전트와 대화합니다(README의 "Runs anywhere" 참고).
5. **민감도가 높으면** 회사 정책에 맞게 `~/.hermes` 를 사내 서버/암호화 볼륨에
   두고, 모델도 사내 엔드포인트(`provider: custom`)로 돌릴 수 있습니다.

### 하네스(harness) 운영 팁
- 업무는 `-p work`, 개인 실험은 기본 프로필로 분리 → 메모리/스킬이 안 섞임.
- 비용 큰 자동화는 cron `--model` 로 싼 모델, 의사결정/디버깅만 강한 모델.
- `hermes -p work doctor` 를 가끔 돌려 연동 상태 점검.

---

## 6. 자가학습(self-improving) 시스템 — 어떻게 굴리나

레포 설명대로 Hermes는 **닫힌 학습 루프**를 가집니다. 핵심 4축:

1. **스킬 자동 생성/개선** — 복잡한 작업을 끝내면 에이전트가 절차를
   `~/.hermes/profiles/work/skills/` 에 **스킬(SKILL.md)** 로 저장하도록
   넛지합니다(`config.yaml`의 `skills.creation_nudge_interval: 15`). 다음에
   비슷한 일을 하면 그 스킬을 불러와 더 빨리/일관되게 처리하고, 쓰면서
   스킬 자체를 다듬습니다. → **내가 일을 시킬수록 내 방식에 맞게 똑똑해짐.**
2. **영속 메모리 + 유저 모델** — `MEMORY.md`(에이전트가 큐레이트하는 기억)와
   `USER.md`(나에 대한 모델)가 시스템 프롬프트에 늘 주입됩니다. 주기적
   넛지로 "기억해 둘 것"을 스스로 적립합니다. Honcho 같은 변증법적 유저
   모델링 플러그인(`plugins/memory/`)도 옵션으로 켤 수 있습니다.
3. **세션 검색(FTS5)** — 과거 모든 대화가 SQLite 전문검색으로 인덱싱되어
   "예전에 이 장애 어떻게 풀었지?" 를 LLM 요약과 함께 되짚습니다(히스토리 검색).
4. **자동화 루프** — cron/webhook 이 위 결과를 매일 Slack 으로 흘려보내
   사람 개입 없이 굴러갑니다.

### 자가학습을 잘 쓰는 운영 수칙
- **스킬을 그냥 쌓지 말고 가끔 정리.** `hermes -p work` 에서 `/skills` 로
  훑고, 잘못 학습된 건 해당 `skills/<name>/SKILL.md` 를 직접 수정/삭제.
- **좋은 스킬은 이 레포로 승격.** `~/.hermes/profiles/work/skills/<좋은스킬>`
  을 `personal/skills/` 로 복사해 커밋하면, 기기 갈아엎어도 살아남고 팀과
  공유 가능(`config.yaml`의 `external_dirs` 로 팀 공용 디렉터리 연결).
- **메모리 신뢰는 검증 후.** `MEMORY.md`/`USER.md` 는 사람이 읽고 고칠 수 있는
  평문이니, 잘못 학습된 사실은 직접 고치세요(자가학습은 보조, 사람이 최종 권위).
- **민감 정보 학습 주의.** 회사 비밀이 메모리/스킬에 적히지 않게 `.env`·외부
  시스템(Notion/Jira)에 두고, 스킬에는 "절차"만 남기도록 유도.

> 요약: **설정·정체성은 Git으로 재현 가능하게, 학습된 자산(스킬/메모리/세션)은
> 백업하며 키우고, 좋은 것만 레포로 승격** — 이게 내 전용 하네스를 안전하게
> 성장시키는 사이클입니다.
