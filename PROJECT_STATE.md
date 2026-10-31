# PROJECT_STATE.md — SoC 5부 공동 작업 기억·현황 색인

> 적용 시작: 2026-10-31 · 기준 시간대: Asia/Seoul
> **단일 기준(Single Source of Truth): GitHub의 최신 파일과 커밋.**
> 이 파일은 대화창 대신 사용하는 **작업 재개 진입점**이며, 실험 결과를 증명하는 파일은 아니다. 이 파일 내용과 실제 구현·검증 증거가 다르면 최신 커밋과 실제 증거를 우선하고 이 파일을 정정한다.

## 1. 재개 시 반드시 읽을 파일

- [CURRICULUM.md](CURRICULUM.md): 교육과정·장별 편성
- [MIGRATION.md](MIGRATION.md): 자료 이관·원본 보존
- [VALIDATION.md](VALIDATION.md): 실험 증거 및 검증·승인 판정
- [COLLABORATION.md](COLLABORATION.md): ChatGPT ↔ Claude 협업·인계
- **PROJECT_STATE.md (현재 파일)**: 진행 위치, 우선순위, 미해결 문제와 재개 지점
- 기술 자산: [Yuul-Jung/dev-board](https://github.com/Yuul-Jung/dev-board). 소스 재사용 및 검증 인용에는 **정확한 원본 커밋 SHA**와 경로를 명시한다.

**새 대화/세션 시작 순서**
1. `Yuul-Jung/soc`와 `Yuul-Jung/dev-board`의 최신 `main` HEAD SHA 확인.
2. 위 기준 문서와 최신 관련 인계·이슈·PR·검증 증거 조회.
3. 직전 작업의 대상 파일, 결정 사항, P0/P1, 실험 증거, 담당 AI·독립 검토자 및 다음 작업 확인.
4. 기준 SHA가 달라졌으면 diff를 확인하고 작업 범위 조정. **이전 대화의 내용·AI 기억을 사실의 근거로 사용하지 않는다.**

## 2. 최초 상태 등록 스냅샷 (이력, 현재 HEAD로 사용 금지)

| 저장소 | 2026-10-31 확인 당시 SHA | 비고 |
|---|---|---|
| `Yuul-Jung/soc` | `107b317949288e519472d1409a10c2d61bee1f33` | 본 파일 등록 이전 확인값 |
| `Yuul-Jung/dev-board` | `40adda4a08c44603d6345810891c10165db01bd3` | 본 파일 등록 이전 확인값 |

이후 HEAD와 진행 상태는 **매 작업 시작 시 다시 조회**한다.

## 3. 부별 작업 상태 — 2026-10-31 기준 문서 요약

| 구간 | 현재 확인된 단계 | 다음 확인 과제 |
|---|---|---|
| 제1부 01–10 | 기존 교재 링크 존재; 추가 웹/실물 검증은 별도 | 원본·성공 프로젝트 보존, 링크/설정/증거 재점검 |
| 제2부 11장부터 (종료 번호 미정) | **현재 내부 사용자 IP는 FND·Short/Long 버튼·범용 PWM 3종**. VGA·PS/2는 카메라 연계 영상 심화로 후순위. 구현·실물 검증 미확인 | FND(11장) → 방향 버튼 4개 Short/Long → 범용 PWM Core/AXI → 필요에 따라 SoC 통합 → 외부 센서/구동기. 카메라+VGA+마우스는 별도 후속 심화 |
| 제3부 (초기 21–30, 재번호 예정) | 가속기·NPU 설계안 | 제2부 확정 후 번호 조정, 실습/정답 모델/자원 제약 검증 |
| 제4부 (초기 31–40, 재번호 예정) | 고급 SoC 통합 설계안 | 데이터 경로·CDC·Reset·타이밍 검증 |
| 제5부 (초기 41–50, 재번호 예정) | RTL·UVM 검증 설계안 | 시뮬레이터 지원, 독립 TB/로그 확보 |

- 기존 `MicroBlaze_V_SoC01_41/`, 검증된 Vivado/Vitis 프로젝트와 실제 성공 원본은 **검증된 이관 전에 삭제·이동·이름 변경·덮어쓰기 금지**.
- 구 11–41장과 신편 11–50장은 기계적으로 번호 대응하지 않는다.
- `dev-board` CI에서의 RTL/UVM PASS와 SoC 통합, 합성·타이밍, Basys3 실물, GitHub Pages 검증은 **각기 별도 상태**다.
- 문서가 확인되었다고 신규 실습·보드 구현이 완료된 것은 아니다.

## 4. 운영 우선순위·인계

| 우선순위 | 목표 | 완료로 인정할 증거 |
|---|---|---|
| P0 | 기존 원본 보호·제1부 안정화·5부 목차 정비 | 변경 커밋, 기능/링크 검증 기록 |
| P1 | 제2부 내부 사용자 IP 3종(FND·PB SW·범용 PWM) | 프로젝트·원본 SHA, TB/AXI/보드 증거 |
| P2 | 제3–5부 가속기·통합·UVM | 단계별 소스·시험 로그·독립 리뷰 |

동일 파일 동시 편집을 피하고, 작성자와 독립 검토자가 커밋·PR·인계 파일로 협력한다. 최종 승인은 사용자가 담당한다.

**작업 단위 인계에 필수로 남길 필드**

```text
작업 ID / 부 / 장 / 담당 AI / 독립 검토 AI:
기준 저장소 / 브랜치 / 커밋 SHA:
변경 파일 / 원본 보존 범위 / 설계 결정:
재현 절차 / 도구 버전 / 출력 파일 링크:
RTL_SIM / UVM / SYNTH_TIMING / BOARD / WEB (각각 PASS·FAIL·SKIP·미확인):
P0/P1 문제와 재현 방법 / 수정 또는 보류:
검토·승인 상태 / 다음 작업 및 인계 URL:
```

작업 종료 시 관련 소스·설계 결정·검증 결과가 GitHub에서 실제 조회되는지 확인하고, 본 파일에서 **요약/다음 재개 지점**만 최신 상태로 갱신한다. 상세 로그는 해당 장과 `VALIDATION.md`의 증거 링크에 둔다.

## 5. 대화창·ChatGPT 프로젝트 삭제 전 보존 기준

- GitHub에 **커밋되지 않은 대화 속 결정/코드/해결 과정/미해결 사항**은 사라질 수 있으므로 먼저 인계 문서·이슈·커밋으로 전환.
- 대화에만 존재하는 GUI 캡처, 파일 첨부, 로그, 파형, 사용자 실물 검증 근거를 GitHub 또는 **별도 영구 백업**에 저장한 다음 경로·버전·접근 여부 확인.
- 대용량 Vivado/Vitis 프로젝트 등 GitHub에 완전 포함되지 않은 로컬 자산은 별도 백업하고, 이 문서/작업 카드에서 보관 위치와 복원 방법을 기록.
- 비밀번호·토큰·개인정보·민감한 원본은 공개 GitHub에 올리지 않는다. 비공개 보관처를 이용하되 인증정보 자체는 문서에 기재하지 않는다.
- **삭제 안전 판정:** 새 대화창에서 GitHub의 최신 자료 + 별도 백업만으로 같은 작업을 재개할 수 있음이 확인되면 과거 대화/프로젝트는 삭제 가능. 이 조건 충족 전에는 삭제하지 않는다. 특히 현재 P1-1(재개 지점·기준 커밋 명시) 및 P1-2(미병합 브랜치 검토·처분) 해소 전 **삭제 보류**.

## 6. 상황실 매시간 보고

- **정기 보고 담당은 ChatGPT의 `00_총괄 상황실` 단 한 곳**이다. 1시간 단위로 `soc`/`dev-board` 최신 커밋 및 중요 이슈·검증/인계 변화 확인. Claude는 사용자 요청이 있을 때 수시 조회·독립 검토하며 중복 정기 보고를 설정하지 않는다.
- 변경이 없으면 보고 내용은 정확히 **`변동사항 없음`** 한 줄.
- 변경이 있을 때만 주요 변경, 부별 상태, 검증 근거, P0/P1 및 다음 조치를 **1페이지 이내**에 요약.
- 보고용 조회는 원칙적으로 읽기 전용. 상황실 보고나 대화 요약을 GitHub 정본으로 자동 간주하지 않는다.

## 7. 작업 재개 기준 및 미병합 브랜치 (2026-10-31 확인 기록)

> 아래 커밋은 **조회 당시 스냅샷**이며 고정 HEAD 값이 아니다. 이 파일 자체도 계속 수정되므로 매 재개 시 GitHub 최신 `main`을 다시 조회해야 한다.
> 확인 기준: `soc/main` **`c75d81ae4111b40f52e0c3fb511a996afbeae6c8` (이번 갱신 직전)**, `dev-board/main` **`40adda4a08c44603d6345810891c10165db01bd3`**.

### 7.1 현재 진행 위치 및 재개 방법 (2026-10-31 최신 반영)

> **재개 출발점:** 반드시 저장소 최신 `main` HEAD를 재조회한 뒤 [CURRICULUM.md §3.2](CURRICULUM.md), [VALIDATION.md](VALIDATION.md), [Issue #3](https://github.com/Yuul-Jung/soc/issues/3)·[Issue #4](https://github.com/Yuul-Jung/soc/issues/4)·[Issue #5](https://github.com/Yuul-Jung/soc/issues/5)를 대조한다. 아래는 재개 절차의 현재 결정 사항이며, 문서 작성 당시 커밋을 현재 HEAD로 고정하지 않는다.

| 필드 | 현재 판정·다음 조치 |
|---|---|
| 프로젝트 | **5부 체계**, 부별 장 수 유동적. 제1부 01–10장·기존 41장 교재와 성공 프로젝트 보존 |
| 제2부 내부 사용자 IP **3종** | **① FND Controller ② PB SW Controller(방향 버튼 4개 Short/Long ≥5초) ③ 범용 PWM Controller**. 기존 AXI GPIO/UART/Timer/INTC·Clock/Reset은 재사용. VGA·PS/2는 카메라 연계 후속 심화 |
| 구현 기준 상태 | **제2부 3종은 설계·검토 단계**. RTL·AXI·합성/타이밍·실물·웹 PASS는 증거 확인 전 **미확인**. [VALIDATION.md](VALIDATION.md) 게이트 적용 |
| **다음 구현 후보** | **11-A FND RTL Scan Controller + 독립 TB** → 11-B AXI Wrapper/IP Packager + TB → 11-C Vitis C + Basys3 실물 + HTML. 11장 번호 유지. 이 후보의 실제 착수·담당 AI·브랜치·기준 커밋·완료 Gate는 **사용자 확인 후 지정** |
| **단일 구현 작업 할당** | **미지정(착수 승인 대기)**. 다음 구현 후보를 명확히 기록한 것이므로 '무엇을 해야 하는지 미정'이라는 뜻이 아니다. 작업 등록 후 이 항목에 담당·파일·커밋·검증 Gate를 기재 |
| Claude 독립 검토 게시 확인 | [Issue #2 댓글 6543718040](https://github.com/Yuul-Jung/soc/issues/2#issuecomment-6543718040), [Issue #3 댓글 6544578500](https://github.com/Yuul-Jung/soc/issues/3#issuecomment-6544578500), [Issue #4 1차 6544578154](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544578154) 및 [2차 6544700455](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544700455), [Issue #5 댓글 6544578358](https://github.com/Yuul-Jung/soc/issues/5#issuecomment-6544578358). **GitHub 댓글 존재 확인**, 시뮬레이션/실물 검증은 미실시 |
| 공통 관리상 미해결 | P1-1 **단일 작업 재개/새 대화 복원 시험** (부분 해소, 담당·Gate 확정 대기), P1-2 **미병합 브랜치 처리** 미결정. §7.2는 이전 기준 SHA의 **이력 비교 수치**이므로 최신 대비 차이는 다시 조회할 것 |
| PWM 비교 실험 | **사용자 결정: 미실시·교육과정 제외.** Claude [Issue #4 2차 제안](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544700455)의 M1–M7 측정 지표와 소프트웨어 PWM·AXI Timer PWM·사용자 RTL PWM 3단 비교 시험은 채택하지 않는다. **범용 PWM 자체 기능 검증은 유지**한다 |
| 다음 조치 | 11-A 작업 등록 여부 사용자 결정 → 작업 담당·기준 SHA·검증 Gate 지정; Claude 2차 검토의 문서 정정 재확인; 미병합 브랜치 검토·새 대화 복원 시험은 별도 추적 |
| 최종 승인 | 사용자 판단 전 미완료 |

### 7.2 병합되지 않은 작업 브랜치 후보

2026-10-31 `main`과 비교: **열린 PR 없음**, 다음 두 브랜치는 `main`과 갈라진 상태다. 아래 숫자는 위 `c75d81a` 기준 상대값이다.

| 브랜치 | 조회 당시 TIP | main보다 앞선/뒤처진 커밋 | 변경 범위 | 처리 |
|---|---|---|---|---|
| `docs/soc07-10-guided-revision-20261027` | `3dae77be6a7ff7cf2f6095c0e4b9a4168c8088b5` | +8 / −163 | 원본 07–10장 HTML 수정 | **미병합 후보 — 비교·채택 판단 필요** |
| `soc08-procedure-20261027` | `b57a72e7051165f7ab609113b9bf2b71b60f68d7` | +2 / −165 | 원본 08장 HTML 수정 | **미병합 후보 — 비교·채택 판단 필요** |

- **미병합 후보는 잘못된 브랜치라는 뜻이 아니다.** `main`에 해당 변경이 이미 다른 방식으로 적용되었는지, 두 브랜치 사이 중복/충돌이 있는지 확인해야 한다.
- 두 브랜치를 보존하고, 병합/폐기/보류는 변경 내용·원본 보호·최신 교재와의 차이를 검토한 뒤 **사용자 확인**으로 결정한다.
- 이 두 브랜치 이외의 외부 로컬 미푸시 작업 및 비공개 백업은 GitHub 조회만으로 확인할 수 없다.

### 7.3 Claude 피드백 기록 및 삭제 보류 Gate

- **P1-1:** 최초 상태의 `107b317` 같은 과거 SHA가 최신으로 오인될 위험. 단일 고정 SHA 대신 기준 시점/조회 근거와 실제 최신 HEAD를 분리하고, **단일 구현 과제의 재개 지점 확정 + 새 대화 복원 시험**을 완료해야 한다.
- **P1-2:** 위 두 미병합 후보를 식별했지만 처리 결정·작업 증거 확인은 미완료. 브랜치별 채택/보류/폐기 근거가 기록될 때까지 **대화/프로젝트 삭제 보류**.
- 역할: AMD 공식 문서·실험 증거 대조는 **ChatGPT와 Claude가 모두 독립적으로 수행**한다.
- 매시간 정기 보고: **ChatGPT 00 상황실 단독**. Claude는 요청 시만 검토·보고한다.
- **Issue #2 Claude 직접 검토/댓글 게시 확인:** [댓글 6543718040](https://github.com/Yuul-Jung/soc/issues/2#issuecomment-6543718040) — GitHub 원문 존재 확인. 이는 **정적 검토 결과**이고 실제 동작/검증 PASS가 아니다.

**새 대화 복원 시험 체크:** 최신 `main` 조회 → 위 5개 기준 문서와 Issue #2 확인 → 두 브랜치/미해결 P1/담당 작업 및 근거 제시 → 필요한 로컬/별도 백업 접근 확인 → 사용자가 정상 재개를 승인한 뒤 삭제 허용.

## 8. 신규 AI 작업 시작 문장

> `Yuul-Jung/soc`의 최신 `main` 커밋을 확인하고 `PROJECT_STATE.md`, `CURRICULUM.md`, `MIGRATION.md`, `VALIDATION.md`, `COLLABORATION.md`를 순서대로 읽어라. 관련 `Yuul-Jung/dev-board`의 원본 커밋과 검증 증거를 확인한 후 현재 작업 상태·미해결 문제·다음 작업을 복원하라. 이전 대화창이나 AI 내부 기억은 정본으로 사용하지 말라.

## 9. 제2부 실습 진행 및 장 수 유연화 (2026-10-31 사용자 결정)

- **5부 체계는 유지, 부별 10장 제한 폐지.** 제2부는 11장부터 시작하며 최초 11–20장 편성을 기반으로 필요 시 실습·검증 단위를 확장한다. 제3–5부의 번호는 편성 후 다시 결정한다. 확정된 제1부 01–10장 및 기존 구 41장 HTML은 원본 보존.
- **진행 시작 작업:** [Issue #3 — 제2부 11장 Basys3 내장 FND 사용자 AXI4-Lite IP](https://github.com/Yuul-Jung/soc/issues/3). 등록 시점 `soc/main=97af8fca49b6d76adbcd9b38399ed0975173a545` / `dev-board/main=40adda4a08c44603d6345810891c10165db01bd3`은 **과거 작업 기준 SHA**일 뿐, 현재 HEAD가 아니다.
- **11장 다음 단계:** 제1부 10장 성공 프로젝트 복원 가능성·IP/주소/클록/리셋 재확인 → 기존 프로젝트와 분리된 실습 환경 계획 → `fnd_scan_controller` 및 TB → AXI4-Lite Register Bank/래퍼 → MicroBlaze C 제어 → 보드·HTML 검증.
- **현 상태:** Issue 등록과 교육과정 변경만 완료. RTL 시뮬레이션·AXI·합성/타이밍·실물 보드·웹 검증 **모두 미확인**. Claude의 담당 수락/독립 리뷰도 미확인.
- **관련 미해결:** Issue #2의 P1-1/2, `docs/soc07-10-guided-revision-20261027` 및 `soc08-procedure-20261027` 미병합 브랜치, 새 대화 복원 시험은 계속 추적한다. 이 항목들을 해결했다고 기록하지 않는다.

## 10. [이력: 대체됨 → §16] 제2부 4개 핵심 사용자 IP + LED PWM 선택 기능 → 외부 확장 (2026-10-31 개정)

- **단일 기준:** [CURRICULUM.md §3](CURRICULUM.md)의 2026-10-31 재편성. 5부 체계 유지, 제2부 장 수 고정 금지, 11장 FND부터 시작.
- **A단계 (핵심 사용자 IP 4종 + LED 선택 기능):** ① FND Controller(11장 시작), ② BTNC Reset 보존 + 4방향 버튼 Short(<5s)/Long(≥5s) Controller, ③ VGA Controller, ④ USB HID→보드 PIC24→PS/2 키보드/마우스 공통 Input Controller. **LED PWM은 기존 AXI GPIO LED ON/OFF의 선택적 밝기 조절 기능**이며 독립 AXI PWM IP 패키징은 필수가 아니다. 키보드/마우스는 한 번에 하나만 연결한다.
- **B단계 (외부 모듈, A단계 이후):** Pmod/XADC 전기 제약·레벨 변환 → 초음파·서보·모터·조도·DHT·BLE → 외부 주변장치 통합. 다른 보드·외부 장치의 소스는 자체 보드 핀·전원·극성 검증 전 직접 재사용 금지.
- **기존 AMD IP 재사용:** AXI GPIO(Switch/LED), AXI UART Lite, AXI Timer, AXI INTC, BRAM, Clock/Reset, 필요 시 XADC Wizard. 이들은 신규 사용자 IP 5종에 포함하지 않으며 반복 실습 장을 별도로 두지 않는다. LED GPIO와 PWM의 핀 동시구동은 기능 Controller에서 해결하고 Top은 Shell 역할만 수행한다.
- **Flash 용도/제외:** Basys3 32 Mbit(4 MB) 직렬 Quad SPI Flash는 FPGA 구성 비트스트림을 저장하여 전원 재인가 시 재구성하는 것이 주용도. 공식 매뉴얼에 사용자 데이터 여유 공간도 있으나 구성 이미지 보호가 우선이므로 **새 사용자 IP 실습/쓰기 실습 제외**. 이 내용은 FPGA 구성·부팅 절차에서만 언급한다.
- **번호:** 11장 FND 다음 4개 IP 장 번호는 아직 미확정. 통합 작업은 신규 6번째 IP가 아니며 B단계 외부 주변장치 교과는 계속 유지한다. 제3–5부 초기 21–50은 잠정 번호이고 기존 01–41장 원본/프로젝트는 보존한다.
- **증거:** 문서 재편성만 완료. 11장 RTL/AXI TB, 합성·타이밍, 보드, HTML 등 추가 성공 증거는 확보되지 않음. 기존 [Issue #3](https://github.com/Yuul-Jung/soc/issues/3)는 11장 범위 그대로 유지.
- **다음 재개 지점:** 11장 프로젝트 복제 가능 여부·실제 XDC/Clock/Reset/Address 확인 → FND 독립 Controller 및 TB → AXI4-Lite Wrapper/Register Map → Vitis C → 실물 검증 → HTML 및 Claude 교차 검토. P1-1/P1-2의 과거 대화 삭제 보류, 미병합 브랜치는 별도 진행.

## 11. BTNC Reset 보존 및 4버튼 이벤트 입력 (2026-10-31 확인)

- **제1부 실제 문서/제약 근거:** `MicroBlaze_V_SoC01_41/docs/soc01.md`, `docs/soc02.md`, `docs/soc10.md`, `code/soc10/basys3_soc10_integrated.xdc`. 100 MHz Clock 입력 `clk`은 W5, 중앙 버튼 `btnC`는 FPGA `U18`에 연결되어 SoC Reset에 사용됨.
- **제2부 운영 기준:** 사용자 버튼 IP에 연결할 자원은 **BTNU/BTND/BTNL/BTNR의 방향 버튼 4개**이다. **BTNC는 기존 MicroBlaze V/Clocking Wizard/Processor System Reset 경로용**으로 보존한다. 버튼 5개 모두 사용자 이벤트로 사용한다는 이전 표현은 적용하지 않는다.
- 핀 제약·실제 BD 포트·Reset 극성은 11장 이후 새 프로젝트 구성 시 다시 확인한다. 문서 정정은 구현/보드 시험 성공을 의미하지 않는다.
- [CURRICULUM.md §3](CURRICULUM.md)에도 반영함. 제2부 FND 11장 우선순위 및 기존 제1부 구조는 변경 없음.

## 12. 방향 버튼 Short/Long Press IP 요구사항 (2026-10-31)

- **사용자 결정:** 기존 `BTNC(U18)` SoC Reset은 유지. `BTNU/BTND/BTNL/BTNR` 4방향 버튼에서 짧은 누름과 **연속 5초 이상 긴 누름**을 구분한다.
- **제안된 판정 시점:** Short(<5000 ms)는 디바운스된 해제 시 1회, Long(>=5000 ms)은 임계값 도달 시 1회; Long 후 해제에 Short 중복 없음. 버튼별 독립 누름 타이머·동시 누름 지원.
- **구현 제안:** 2FF 동기화 → 디바운스(기본 20 ms, 설정값) → 1 ms 동기 Clock Enable/포화 카운터 → Short/Long Event → Sticky Status/AXI4-Lite Register → 선택 IRQ. 이벤트와 W1C 클리어 동시 발생 시 이벤트 우선; 여러 개의 동일 이벤트를 개별 보존할 필요가 생기면 카운터 또는 FIFO 검토.
- **검증 계획:** 4999/5000/5001 ms 경계, 바운스, 동시 4버튼, Reset, Long 후 Release, Sticky/clear/IRQ/AXI backpressure 테스트.
- **증거 상태:** 요구사항만 문서화. RTL 구현·TB PASS·합성/타이밍·Basys3 보드 실험·웹 배포는 **미실시/미확인**.
- **정본:** [CURRICULUM.md §3](CURRICULUM.md). 11장 FND 시작 작업과 본 버튼 IP 후속 순서는 유지하며 아직 신규 장 번호 확정 없음.

## 13. [이력: 대체됨 → §16] 제2부 내장 사용자 IP 5개 범위 확정 및 구성 Flash 처리 (2026-10-31)

- **최신 사용자 구분:** 내장 기능 주제는 FND, 방향버튼(Short/Long 1종), LED PWM 선택 기능, VGA, 키보드·마우스 공통 PS/2로 5개이나 **독립 핵심 사용자 IP는 4개**이다. PWM은 LED 점등에 부가되는 선택 기능이며 별도 AXI PWM IP로 의무 제작하지 않는다. 기존 AMD IP는 재사용하며 내장 XADC 모니터/Flash/Switch·LED GPIO/UART는 별도 사용자 IP로 만들지 않는다.
- **USB 입력 주의:** Basys3 PIC24가 USB 키보드 또는 마우스를 PS/2로 변환하며 USB 허브는 미지원. 하나의 PS/2 Input IP 내에 공통 수신 및 장치별 디코더를 둔다. 두 장치 동시 연결을 목표로 하지 않는다.
- **Flash:** 32 Mbit(4 MB) 비휘발성 Serial Flash의 주용도는 FPGA 전원 투입 시 불러올 구성 비트스트림 보존이다. Vivado의 Flash 구성 안내 외에는 사용자 IP 개발/쓰기 실습에서 제외하고, 기존 비트스트림과 구성 모드를 보존한다. 공식 근거: Digilent Basys3 Reference Manual §2/§3.
- **정본:** [CURRICULUM.md §3](CURRICULUM.md) 커밋 `62df7923a920cb489f24ddc0bbd7d6f3297c3c75`를 출발 기준으로 사용하며 매 재개 시 HEAD 재조회.
- **이후 단계:** 11장 FND Issue #3 → 버튼 Issue #5 → VGA → PS/2, 필요 시 LED PWM 옵션 → 기존 AMD IP들과 통합 → B단계 외부 모듈; 실물/RTL/AXI/합성/웹 검증은 새 범위에 대해 아직 미실시.

## 14. [이력: 대체됨 → §16] LED PWM은 독립 AXI IP가 아닌 GPIO LED 선택 기능 (2026-10-31 최신 결정)

- **사용자 설계 구분:** PWM은 제1부 LED 점등(AXI GPIO)의 선택적 **밝기 제어 옵션**이다. 새로운 독립 AXI PWM Peripheral 제작은 필수 아님. 기존 5개 실습 기능 주제 가운데 PWM이 이 옵션에 해당하여 독립 핵심 사용자 IP는 FND, Button, VGA, PS/2의 4개.
- **기본:** 기존 AXI GPIO의 LED On/Off 경로 유지. **선택:** RTL `pwm_core`를 별도 독립 실습 프로젝트에서 시험, PWM 모드가 필요할 때에만 최종 LED 출력 경로에 추가. CPU에서 Duty를 지정해야 한다면 레지스터 제어 경로를 별도로 검증한다.
- **중요:** GPIO 출력과 PWM 출력을 같은 FPGA 물리 LED 핀에 이중 구동하지 않는다. 통합 프로젝트에서는 `led_output_controller`가 GPIO 모드/PWM 모드를 선택해 최종 단일 `led` 출력으로 전달한다. 모드 선택 로직은 Top이 아닌 Controller에 둔다.
- **원본 보존:** 제1부 성공 프로젝트와 원본 Top/XDC는 손대지 않고 별도 실습 프로젝트를 생성한다. PWM 미사용 프로젝트에 PWM 회로/IP를 의무 포함하지 않는다.
- **검증 상태:** 결정/문서만 갱신. 신규 SoC 통합·RTL·합성·실물 시험 모두 미확인.

## 15. [이력: 대체됨 → §16] 현 단계 FND·버튼 집중 및 카메라·VGA·마우스 영상 심화 후속 이관 (2026-10-31)

- **사용자 결정:** VGA와 키보드·마우스 PS/2를 **지금 제2부 필수 실습에서 제외**한다. 이후 사용자 제안에 따라 **카메라 영상 입력과 VGA 출력 및 마우스 제어를 같은 후속 영상 입출력/사용자 인터페이스 학습 단계에서 다루는 구성**으로 정리한다. 이는 같은 난이도를 뜻하지 않으며, 제3·4부 중 어느 장에 배치할지는 추가 검토 후 결정한다.
- **현재 필수 사용자 AXI IP 2종:** Basys3 4자리 **FND Controller**([Issue #3](https://github.com/Yuul-Jung/soc/issues/3)), BTNC Reset 보존 + 4방향 버튼 **Short/Long(5초 이상) Button Controller**([Issue #5](https://github.com/Yuul-Jung/soc/issues/5)). **LED PWM과 FND 전체 밝기는 선택 기능**이며 독립 AXI PWM 주변장치 패키징은 필수가 아니다.
- **후속 통합 가안:** 외부 카메라 픽셀/동기 입력 → 라인·소형 프레임 버퍼/필요 시 CDC → VGA 출력 → PS/2 마우스 커서·ROI 선택. Basys3 약 1,800 Kbits BRAM 제약상 640×480 RGB565 전체 프레임은 온칩 BRAM에 담기 어려워 저해상도/스트리밍을 검토한다. 키보드는 필요한 경우 별도 선택.
- **제1부 재사용/보존:** MicroBlaze V·BRAM·AXI GPIO/UART Lite/Timer/INTC·Clock/Reset의 성공 프로젝트를 변경하지 않는다. 각각의 사용자 IP를 별도 소스·TB와 필요 시 별도 Vivado SoC에서 검증하고, 통합은 선택적으로 수행한다.
- **정본:** [CURRICULUM.md §3.2·§3.5](CURRICULUM.md). 이전 §10·§13에 있는 4종(또는 5종) 현행 필수 IP 표현은 **과거 편성 이력**이다. 이 §15가 최신 진행 우선순위를 대체한다.
- **증거:** 신규 FND/버튼/VGA/PS2/카메라의 RTL_SIM·AXI_SIM·합성·실물·웹 PASS 증거는 이번 결정에서 확보되지 않음. 후속 영상 시스템은 편성 가안일 뿐 실제 개발 착수 아님.

## 16. 내부 사용자 IP 3종 최종 확정 및 Claude 독립 검토 반영 (2026-10-31)

- **최근 사용자 결정 우선:** 제2부 내부 사용자 IP는 **① FND, ② 방향버튼 PB SW(Short/Long 5초), ③ 범용 PWM**의 3종으로 확정. 이전 §10·§13·§14·§15의 '필수 2개 + PWM 옵션' 또는 'VGA/PS2 포함'은 **과거 의사결정 기록**이고, 최신 실습 기준은 [CURRICULUM.md §3.2](CURRICULUM.md)이다. 개별 출력장치에서 PWM의 채택 여부는 선택이지만 **범용 PWM IP 개발 자체는 제2부 수행 과제**이다.
- **Claude 독립 검토:** [Issue #4](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544578154), [Issue #5](https://github.com/Yuul-Jung/soc/issues/5#issuecomment-6544578358), [Issue #3](https://github.com/Yuul-Jung/soc/issues/3#issuecomment-6544578500). Claude가 기록한 검토 기준은 `soc/main=55029f9`(과거 SHA) 및 `dev-board/main=40adda4`이며, Claude는 자료 정적 검토만 수행했다.
- **공식 자료 독립 대조:** AMD [PG079 AXI Timer](https://docs.amd.com/r/en-US/pg079-axi-timer) 실제 본문에서 Timer 0·1 한 쌍으로 `PWM0` 한 채널을 생성하고 `TLR0`에 주기,`TLR1`에 HIGH 시간을 설정함을 확인. **단순 PWM의 중복 구현이 아닌 다채널·0/100%·경계 갱신·극성·스캔 동기화** 검증을 범용 IP의 교육적 차별화로 명시. PG079 문서(2025-08-15)의 제품 사양과 실제 Vivado 2024.2 인스턴스 설정은 실습 시 대조하고, AMD PWM의 '100% 불가/변경 시 글리치'는 이 검토만으로 단정하지 않는다.
- **공식 [Digilent Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc) 핀 대조:** `btnC=U18`(Reset 보존), `btnU=T18`, `btnL=W19`, `btnR=T17`, `btnD=U17`; FND `seg[0..6]=W7,W6,U8,V8,U5,V5,U7`, `dp=V7`, `an[0..3]=U2,U4,V4,W4`. 공식 Basys3 매뉴얼에 따르면 버튼은 눌렀을 때 HIGH, FND 자리/세그먼트는 LOW 활성. **XDC는 핀 매핑 근거이며 극성 근거는 보드 매뉴얼/회로**.
- **FND PWM 위험 관리:** 자리 스캔과 무관한 PWM 신호를 AN에 게이팅하면 밝기 불균일 위험. 자리 슬롯 시작에 PWM 위상 동기화, 슬롯 소등·전환 처리. 기본 FND 밝기 100%; 후속 범용 PWM 개발과 통합 단계에서 밝기 연계. FND 기본 표시를 PWM의 선수학습에 묶지 않음.
- **11장 분할 결정:** 장 번호는 **11장 그대로 보존**, 내부 절차만 `A: FND RTL+TB` → `B: AXI Wrapper/IP Packager+Register Map/TB` → `C: Vitis C+실물 보드+HTML` 세 묶음으로 분할한다. 공통 AXI Wrapper 템플릿은 버튼·PWM에서 재사용하는 설계 후보이며 구현/검증은 미실시.
- **버튼 5초 축소 TB 채택:** 1 ms Tick 생성을 파라미터로 축소해 4,999/5,000/5,001 Tick과 동시 입력/리셋/W1C 등을 검증, `100 MHz / 100,000 = 1ms` 생성 정확성 별도 TB, 실제 5초는 Basys3에서 별도 계측. 축소 TB PASS를 실측 5초 PASS라고 보고하지 않는다.
- **PWM 대비 실험 제외(최신 사용자 결정):** Claude [Issue #4 2차 검토](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544700455)의 M1–M7 정밀 성능 지표 및 S(소프트웨어)·T(AXI Timer)·R(사용자 RTL) 3단 비교 실험은 **진행하지 않는다**. CPU 부하별 지터·출력 우열을 측정·주장하지 않는다. 단, 범용 PWM IP의 RTL/AXI 정상 동작 검증(주기·Duty·0/100%·설정 경계 갱신·극성·다채널·Reset)과 실물 사용 기능 확인은 유지한다. 이 항목을 미실시 실험의 PASS/FAIL로 기록하지 않으며 **교육과정 제외**로 명시한다.
- **보존·검증:** 제1부 기존 `~/soc/hw/soc_hw.xpr`, `~/soc/sw`와 HTML 원본은 수정하지 않는다. FND/버튼/PWM 각 독립 프로젝트 구현·RTL/AXI 테스트·합성/타이밍·실물 보드·웹 배포는 **아직 미확인**. Claude 리뷰의 **조건부** 상태는 교차 검토 의견이며 보드 PASS나 독립 구현 PASS가 아니다.

## 17. 제2부 외부 디지털 GPIO 모듈 공용 확장 구조 (2026-11-01 사용자 결정)

- **사용자 결정:** 제1부 AXI GPIO의 16개 SW 입력·16개 LED 출력과 해당 XDC/원본 프로젝트는 그대로 유지. 제2부 **별도 복제 SoC 프로젝트에 AMD AXI GPIO 인스턴스 `axi_gpio_external`을 추가**하고 외부 디지털 입력·출력 모듈들을 해당 인스턴스의 두 채널에 여러 비트로 연결해 재사용. **센서마다 새 AXI GPIO 인스턴스 또는 사용자 정의 GPIO IP를 만드는 방식 아님**.
- **예시 배정(실제 핀·폭 미확정):** 채널 1 입력 8비트에 CDS DO·PIR·TTP223·리드 스위치·TCRT5000 등, 채널 2 출력 8비트에 외부 LED·능동 부저·드라이버 구비 릴레이/모스펫 제어 등. JA/JB/JC의 실제 핀/가용 수·모듈별 전압·출력 극성/풀업·전원 검증 뒤 XDC에 확정.
- **CDS 기준 실습:** CDS 디지털 DO → 새 AXI GPIO 입력 → MicroBlaze V에서 읽기 → UART 터미널 상태 출력 또는 기존 AXI GPIO LED를 C 애플리케이션에서 제어. 제1부 SW→LED C 애플리케이션을 동시에 그대로 실행할 수 있다고 가정하지 않으며, 원본 SW→LED 실습·XDC·IP 설정은 보존.
- **예외:** 정밀 타이밍/프로토콜 모듈(HC-SR04, DHT22, 회전 엔코더 등)은 별도 Controller/IP 검토. 기능 중복 방지, 3.3V I/O 및 5V 레벨 변환, 외부 부하 별도 구동/전원 원칙 유지.
- **진행 상태:** [CURRICULUM.md §3.3](CURRICULUM.md)에 원칙 반영. 추가 인스턴스·새 주소맵·보드 연결·실행·RTL_SIM/AXI_SIM/SYNTH_TIMING/BOARD/Web는 **미실시/미확인**. 제1부 성공 프로젝트·HTML 원본 변경 없음.
