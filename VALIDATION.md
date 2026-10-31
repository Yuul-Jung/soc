# SoC 교육과정 검증 상태 및 승인 기준

> 기준일: 2026-10-31. **이 문서 생성 자체는 RTL 시뮬레이션, Vivado 구현 또는 실제 Basys3 검증을 의미하지 않는다.** 검증 결과는 로그·보고서·스크린샷이 있을 때만 기입한다.

## 1. 판정 체계

| 상태 | 의미 |
|---|---|
| 계획 | 설계/목차 단계. 기능 결과 없음 |
| 자료작성 | 문서 또는 코드 파일이 존재하나 요구 검증 미완 |
| 정적검토 | 코드·공식 문서·파일 구조의 비교 검토 |
| RTL_SIM_PASS | 명시된 시나리오의 RTL 시뮬레이션 통과 |
| UVM_PASS | 명시된 UVM 테스트가 호환 시뮬레이터에서 실행·통과 |
| SYNTH_TIMING_PASS | 실제 대상 디바이스 합성·구현·타이밍 요구 확인 |
| BOARD_PASS | 지정된 Basys3·외부장치에서 실제 동작 검증 |
| WEB_PASS | GitHub Pages 링크·그림·본문 정상 표시 확인 |
| 장별 완료 | 해당 장의 필수 Gate와 교재 검수를 모두 충족 |

서로 다른 증거는 별도 필드로 기록한다. `RTL_SIM_PASS`는 `BOARD_PASS`와 같지 않으며, 자체 테스트 통과만으로 기능 완전성을 주장하지 않는다.

## 2. 저장소 현재 상태 (이번 기준 파일 확인)

| 범위 | 확인 가능한 사실 | 미확인·추가 조치 |
|---|---|---|
| `soc/part01/index.html` | 원본 01–10장 링크와 '완료' 배지가 있음 | 배지와 무관하게 링크·실물 증거별 재점검 |
| `soc/part02/index.html` | 이전 '사용자 정의 IP' 안내 페이지 | 새 제2부 목차·HTML·실습 미구축 |
| `soc/part03/index.html` | 이전 'SoC 응용 및 확장' 안내 페이지 | 새 제3부 내용 반영 필요 |
| `soc/part04/` | 확인된 루트 목록에 없음 | 신규 |
| `soc/part05/` | 확인된 루트 목록에 없음 | 신규 |
| `soc/MicroBlaze_V_SoC01_41/` | 기존 41장 HTML 존재 | 일부 설정·소스·그림·다운로드 별도 검수 필요 |
| `dev-board/rtl/` | RTL01–32 프로젝트·TB·CI 스크립트 존재 | SoC AXI 연결·합성·실물 검증 별도 |

## 3. dev-board에 기록된 기존 테스트 증거

`dev-board/rtl/VERIFICATION_STATUS.md`의 **자체 기록**에 따르면:
- GitHub Actions Icarus Verilog RTL 32/32 PASS 기록 (2026-10-31, run 41189772658 등).
- RTL03 UVM PASS 기록 (run 41189772574).
- RTL 변형 검사 222개 중 114개 검출(51.4%, run 41190240306).
- Vivado 합성·Timing 및 Basys3 실물 검증은 미실시로 기재.
- 일부 과제는 외부 PHY/IP 연결 전의 Controller 단계임.

`dev-board/rtl/ADVERSARIAL_REVIEW_20261031.md`는 초기 검토 환경에서 시뮬레이터를 실행하지 못했다고 기록한다. 이 문서와 후속 검증 상태 문서의 시점·근거가 다르므로, 최종 판정 전에 **실제 GitHub Actions 런·커밋·로그를 조회하여 일치 여부를 확인**한다. 본 파일의 기록은 외부 런을 이번에 직접 재실행한 결과가 아니다.

## 4. 필수 검증 매트릭스

| 시험 축 | 무엇을 확인하는가 | 증거 파일 |
|---|---|---|
| 문서 | AMD IP 버전·사양·핀·레지스터·GUI 일치 | 공식 문서 번호/링크, 리뷰 결과 |
| RTL 컴파일 | 구문·포트·파라미터 정합성 | 컴파일 로그 |
| RTL 동작 | 정상·경계값·Reset·Timeout | TB 소스, PASS/FAIL 로그 |
| AXI | 독립 AW/W, B/R 응답, Backpressure | AXI TB, Assertion 로그 |
| UVM | 시퀀스·Monitor·Scoreboard·RAL | 테스트 이름, 시뮬레이터 버전, 로그 |
| 구현 | LUT/FF/BRAM/DSP, Timing, DRC | Vivado 보고서 |
| 전기 안전 | I/O 전압·외부 전원·모터 드라이버 | 데이터시트, 회로 검토 |
| 실물 | 보드 ID·XSA/bitstream·동작 | GUI 캡처, 측정 로그 |
| 웹 | 링크·그림·다운로드·모바일·한글 | URL, 검사 로그 |

### 시간 정확성 검증

- Clock 주기·분주 방식·출력 주기/펄스폭을 계산하고 테스트벤치에서 측정한다.
- CPU 제어 레지스터 변경 시점과 RTL 출력 반영 시점을 구분한다.
- 물리적 Clock jitter, 타이밍 위반, CDC 문제가 없다고 단정하지 않는다.
- PWM 0/100%·초음파 timeout·FIFO full/empty·동시 접근 등 경계값을 필수 테스트에 포함한다.

## 5. 1–5부 검증 목표

| 부 | 최소 검증 기준 |
|---|---|
| 1부 | 이론 장의 공식 문서 검토, GUI 장의 Vivado/Vitis 화면·기본 SoC 실행 재현 |
| 2부 | 단위 RTL TB + AXI 레지스터 TB + 해당 장의 실제 주변장치 보드 검증 |
| 3부 | RTL TB + Python 정답 모델 비교 + 합성·타이밍·자원 확인 |
| 4부 | 시스템 인터페이스·CDC/Reset·성능 측정·최종 통합 보고서 |
| 5부 | RTL 검증과 UVM 검증을 분리 실행, 커버리지와 미검출 항목 명시 |

## 제2부 FND·PB SW·범용 PWM 3종 검증 게이트 (2026-10-31)

**범위 결정:** 최근 사용자 지시에 따라 내부 사용자 IP는 FND, PB SW(Short/Long), 범용 PWM의 3종이다. 앞선 'FND·버튼 2종 + PWM 선택'은 현재 편성안이 아니다. 현재 기록은 **설계 요구사항**이며 수행 증거는 없다.

| 구분 | 최소 검증 조건 | 증거 구분 |
|---|---|---|
| FND RTL | `an[3:0]`, `seg[6:0]`, `dp` Active-Low, 자리 스캔·표시값·전환 소등 | `RTL_SIM`; 실제 7-seg 표시와 밝기는 별도 `BOARD` |
| FND·PWM 연계 | 슬롯 시작에 PWM 위상 동기화, 0·100% 밝기, 자리별 점등시간 균일, 주기 변경 시 잔상/편차 | RTL 파형 및 필요 시 보드 밝기 비교 |
| PB SW RTL | 방향 버튼 4개 독립 동기화·디바운스, Short/Long 5초, 중복 방지·IRQ·W1C·Reset | 단위 TB·AXI TB |
| PB SW 5초 **축소 TB** | Tick 생성 분주를 파라미터로 축소하고 **4999/5000/5001 Tick**, 누름/해제·동시 4버튼·반복·Reset·W1C 경쟁 시험 | `RTL_SIM_SCALED` — **실제 5초 검증 아님** |
| PB SW **실분주 검증** | Basys3 100MHz에서 1ms마다 Tick 1개(100,000 입력 Clock 당 1 Tick), 오프바이원 검증 | `TICK_REAL_DIV_SIM` |
| PB SW **실물 시간 검증** | FPGA 실물에서 Long 이벤트 약 5초 발생, 5초 이전 Short·이후 Long 구분을 스톱워치 또는 로직 측정으로 검증 | `BOARD_5S_MEASURED` |
| 범용 PWM RTL | 장치 비의존 Core, 다채널 확장, 정확한 0/100%, Duty/Period 갱신 경계, 극성 | `RTL_SIM` |
| 범용 PWM 기존 IP 비교 | AMD PG079 AXI Timer PWM과 제공 기능 비교; 두 Timer 묶음/1채널 확인. 실제 Vivado 2024.2 인스턴스의 PWM 지원·드라이버 차이·출력 측정은 별도 | `DESIGN_REVIEW` 및 필요 시 실제 Vivado 실험 |
| AXI IP 연결 | 독립 AW/W 수락, WSTRB, B/R backpressure, Reset, register read/write·동시 Clear/Event | `AXI_SIM` |
| 보드/구현/웹 | 핀·클록·리셋·실제 비트스트림, 합성·타이밍, 물리 출력, HTML 링크/그림 | `SYNTH_TIMING`·`BOARD`·`WEB` 분리 |

`RTL_SIM_SCALED` 통과만으로 `BOARD_5S_MEASURED` 또는 `TICK_REAL_DIV_SIM` 통과로 판정하지 않는다. FND 11장은 **A: RTL+TB → B: AXI Wrapper/IP Packager/TB → C: Vitis C+Board/HTML** 세 절차로 나누되 기존 장 번호·원본 프로젝트를 변경하지 않는다. 공식 근거: [PG079](https://docs.amd.com/r/en-US/pg079-axi-timer), [Digilent Basys-3-Master.xdc](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc), [Issue #4 Claude 리뷰](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544578154), [Issue #5](https://github.com/Yuul-Jung/soc/issues/5#issuecomment-6544578358), [Issue #3](https://github.com/Yuul-Jung/soc/issues/3#issuecomment-6544578500).

## 6. 검증 결과 레코드 템플릿

```text
검증 ID:
부 / 장:
DUT / RTL 소스 경로:
검증 기준 커밋:
테스트 도구 / 버전:
실행 환경:
실행 명령:
테스트 케이스 / 체크 항목:
기대 결과:
실제 결과:
PASS / FAIL / SKIP:
로그 또는 파형 경로:
Vivado 합성·구현 보고서:
실물 보드 결과:
발견 오류 / 재현 절차:
재검증 커밋:
작성자 / 독립 검토자:
최종 승인 상태:
```

증거 없는 PASS 금지. PASS와 커버리지/검출 범위는 별도로 표시한다.

## 7. 검증 결함 분류

| 우선순위 | 정의 | 예 |
|---|---|---|
| P0 | 안전·프로토콜·기능 파괴 | 5V 직결, AXI 응답 유실, 전원 단락 위험 |
| P1 | 주요 기능·재현성 문제 | Reset 비결정성, 주소 오기, FIFO 데이터 유실 |
| P2 | 교육 및 유지보수 개선 | 중복 설명, 명칭 불일치, 불필요한 코드 변경 |

P0/P1 미해결인 장을 완전 검증 완료로 게시하지 않는다.

## 8. 증거 폴더 및 결과 분리 원칙

- 과제 소스가 `dev-board`에 있으면 원본 커밋·시험 스크립트·런 URL을 연결한다.
- SoC 통합 시험은 `soc`의 해당 부/장 경로에서 별도로 관리한다.
- UVM 검증은 `rtl_verification`과 혼합하지 않고 `uvm_verification`의 파일·실행 로그로 구분한다.
- 로그에는 정확한 시뮬레이터와 사용 버전을 남긴다.
- 도구 미설치나 실행 실패는 `SKIP`/환경 문제로 표기하고 성공으로 기록하지 않는다.

## 9. 최종 승인 조건

1. 해당 장에 필요한 검증 레코드가 존재한다.
2. 코드·문서·그림·스크린샷·실제 설정값이 일치한다.
3. 반례·경계값·발견 오류의 처리 상태가 명확하다.
4. 독립 검토자가 결과와 증거를 재확인한다.
5. GitHub 배포와 GitHub Pages 화면을 실제 확인한다.

이 문서의 검증 상태는 증거 확보 시마다 최신 커밋을 명시하여 갱신한다.
