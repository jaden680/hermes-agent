# L2 메모리 엔진 셋업 — hindsight (local_embedded)

지식그래프 + 엔티티 해석 + 로컬 임베딩 RAG. **추가 API 키 불필요**(모델용 키만
있으면 임베딩/리랭킹이 로컬에서 돈다). 데이터는 내 머신에만 남는다.

## 1. 켜기
```bash
hermes -p work memory setup        # 목록에서 "hindsight" 선택
#  ↳ 의존성을 uv 로 자동 설치, 모드/제공자 마법사 진행
#  ↳ "local_embedded" 선택, 추출용 LLM 은 이미 쓰는 모델 키 사용
```
수동으로도 가능:
```bash
hermes -p work config set memory.provider hindsight
# 설정 파일: ~/.hermes/hindsight/config.json  →  "mode": "local_embedded"
```

## 2. 동작 방식
- 로컬 hindsight 데몬(내장 PostgreSQL)이 **첫 사용 시 자동 기동**, 5분 유휴 후 정지.
- 대화/작업에서 사실을 자동 추출해 **엔티티+관계 그래프**로 적립(`memory.nudge_interval`).
- 질문 시 다중전략 검색(벡터+그래프)으로 회수 → 답변 근거로 주입.
- 로그: `~/.hermes/logs/hindsight-embed.log`
- 웹 UI(그래프 확인): `hindsight-embed -p hermes ui start`

## 3. 씨앗 인제스트 (service-catalog.yaml → L2)
카탈로그는 Git source of truth, 한 번 메모리에 흡수시켜 회수 가능하게:
```bash
hermes -p work -m "personal/knowledge/service-catalog.yaml 를 읽고, 각 service/owner/dependency/runbook/incident/decision 를 엔티티로 메모리에 적립해줘. 이미 있으면 갱신만."
```
> 카탈로그를 고칠 때마다 이 한 줄을 다시 돌리면 L2가 동기화된다.

## 4. config.yaml 연계 (이미 반영됨)
```yaml
memory:
  memory_enabled: true
  user_profile_enabled: true
  nudge_interval: 10
```
provider 는 위 setup 으로 hindsight 가 된다(config 에 평문 저장 안 해도 됨).

## 5. 주의
- 회사 비밀(키/토큰/PII)은 L2에 적립하지 말 것 → `.env`·원본 시스템에만.
- 메모리는 보조, **사람이 최종 권위**. 틀린 사실은 UI나 `/memory` 로 수정/삭제.
