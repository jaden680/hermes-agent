# Knowledge — 온톨로지 + RAG + 자가학습 (제이든 업무용)

목표: 회사 지식 기반으로 **온콜 답변 초안 / 개발 / 의사결정**을 잘 만드는 것.
범위가 넓으므로 **거대 온톨로지를 미리 짜지 않고**, 씨앗만 심고 실사용으로 키운다.

## 4계층 구조

```
[L1] 실시간 원본 (적재 X, 그때그때 조회)
     · Notion · Jira (MCP)
     · 제이든이 주는 로컬 코드 경로
     · Slack 채널 (MCP, 선택 채널만)        ← 대화/장애/결정의 1차 출처

[L2] 지식 메모리 = 온톨로지 + RAG   ★ hindsight (지식그래프+로컬RAG)
     엔티티 6종만 고정: Service · Owner · Dependency
                        · Runbook · Incident · Decision
     → service-catalog.yaml 로 씨앗을 심고, 실사용 Q&A·Slack 스레드가 누적

[L3] 런북 스킬 (절차)   ~/.hermes/profiles/work/skills/<name>/SKILL.md
     "X 알림 → Y 확인 → 근거 Z" 를 증류. 검색 가능 + 자기개선.

[L4] 자가학습 루프
     온콜 Q&A·개발·Slack → L2 적립 + L3 증류 → 다음에 회수 → 제이든이 큐레이션
```

답변 품질 = **L1 정확도(원본) + L2 회수(RAG/그래프) + L3 절차(런북)**.
자가학습이 L2·L3를 시간이 갈수록 두껍게 만든다.

## 파일

| 파일 | 역할 |
|---|---|
| `service-catalog.yaml` | **씨앗 온톨로지** — 엔티티 6종 구조 + 채워넣을 자리. 1차 source of truth(Git 관리) |
| `memory-setup.md` | **L2 엔진(hindsight) 셋업** — local_embedded, 추가 키 불필요 |
| `capture-distill.md` | **자가학습 운영법** — Q&A·Slack을 어떻게 L2/L3로 적립·증류하나 |
| `runbooks/` | 승격된 런북 스킬 보관(Git). `config.yaml`의 `external_dirs`로 연결 가능 |

## 운영 3원칙 (범위 통제)
1. **엔티티는 6종만.** 새 개념은 6종 중 하나로 매핑되는지 본다. 회사 전체 모델링 금지.
2. **상향식 누적.** 손으로 다 적지 말고, 실제 질문/Slack 스레드에서 자동 적립.
3. **사람이 최종 권위.** 자동 적립분은 제이든이 검토 후 좋은 것만 Git으로 승격, 틀린 건 수정.

## 시작 순서
1. `memory-setup.md` 따라 hindsight(local_embedded) 켜기
2. `service-catalog.yaml` 에 아는 서비스 3~5개만 채우고 1회 인제스트
3. `capture-distill.md` 의 루프대로 온콜/개발하며 자라게 두기
4. 주 1회 큐레이션: 좋은 런북 → `runbooks/` 로 승격 커밋
