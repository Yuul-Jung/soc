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

### 제2부 CDS 외부 GPIO/RTL SoC 통합 검증 게이트 (2026-11-01, 수행 전)

**[CURRICULUM.md §3.3](CURRICULUM.md)의 사용자 Top 또는 BD Add Module 연결 설계안에 적용한다.** 현재 C안(CDS DO → RTL Controller → 외부 LED)을 기준으로 하되, A안(내장 LED MUX)은 **미확정 선택 실습**이므로 필수 PASS 대상으로 추가하지 않는다.

| 검증 축 | 확인해야 할 사항 | 증거 및 판정 |
|---|---|---|
| 구조·원본 보존 | 제1부 성공 프로젝트/원본 BD·내장 `SW[15:0]`/`LED[15:0]` 경로·XDC 파일을 그대로 보존. 복제본에서 **C안도 새 사용자 Top 또는 BD Add Module, CDS DO·외부 LED 포트 추가가 필요**함을 파일/계층으로 확인 | 실제 경로·파일 비교, Vivado Design Sources/BD 캡처 (미실행) |
| 클록/리셋 단일 도메인 | CDS 입력 2FF 동기화·필터 및 `axi_gpio_external` 관찰은 **기존 SoC AXI 측 Clock Wizard 출력 클록**을 공통 사용하도록 우선 설계. 실제 출력 주파수·Reset 극성·`clk_out1`/`peripheral_aresetn` 명칭·BD/Wrapper 포트 노출 확인 | BD 포트/Clock Summary, Reset 연결 스크린샷, CDC·Reset 정적 검토. Clock/Reset 외부 미노출 시 **BD 포트 내보내기 + XSA 재생성** 필요성 기록 |
| 클록 교차 예외 | 외부 보드 100MHz 클록을 새 Controller에 쓰면서 BD AXI는 별도 Clock Wizard 클록을 쓰는 경우, **동일 도메인이라고 간주하지 않음**. 1비트 상태 동기화/핸드셰이크 및 타이밍 제약/리셋 해제 검증 | CDC/Timing 보고서 및 RTL TB. 단순 동일 주파수만으로 PASS 금지 |
| RTL_SIM | 실제 CDS DO 극성 반영, 비동기 입력 2FF 동기화, 안정화 필터(적용 시), 밝음·어두움 전환, Reset·글리치·단일 최종 LED 구동을 시험 | Self-checking TB/로그; 검증 전 **미실시** |
| AXI_SIM(선택 기능) | `axi_gpio_external`을 실제 추가한 경우, **상태 관찰만** 가능하고 LED 자동 제어 경로에 CPU 쓰기를 요구하지 않는지 확인; AXI 입력 읽기/주소/Reset 확인 | AXI 레지스터 TB/로그. AXI GPIO 인스턴스를 추가하지 않은 C안 초기 독립 RTL 실습에는 **해당 없음** |
| 합성·타이밍·XSA | 기존 Wrapper 포트→사용자 Top 핀 매핑·XDC 일치, 클록·리셋 경로, 기존 SW/LED 기능 회귀, 새 Bitstream과 XSA/Vitis 플랫폼의 일치 | Vivado Validate Design, Implementation, Timing, XSA/bitstream 확인; **미실시** |
| BOARD | 센서 모듈의 정확한 모델·3.3V DO 논리 레벨/극성·Pmod 핀, 외부 LED 직렬 전류제한 확인. **CPU가 LED 제어 코드를 실행하지 않아도** CDS가 외부 LED를 직접 제어하는지 실물 시험. 공유 Reset에 의해 RTL까지 Reset되는 상황을 CPU 독립 동작 시험으로 착각하지 않음 | 실제 Basys3 + 모듈 배선/사진·동작 관찰/로그. **미실시** |
| 후속 A안 MUX(미확정) | 사용자 최종 채택 시에만 기존 AXI GPIO→내장 LED 직행 경로가 MUX로 바뀌는지, MUX 기본값/단일 구동원/기존 SW→LED 동작을 독립 회귀 검증 | A안 선정 후 별도 RTL/BOARD Gate 설정; **현재 해당 없음** |

**비교 기준:** 사용자 Top이 있다는 것만으로 모든 RTL의 BD 변경이 없어지는 것은 아니다. **A안과 C안 모두 Top/BD 계층 추가라는 구조 변경**이 있으나, **내장 LED 출력 경로 변경은 A안에만 해당**한다. 추가 AXI GPIO 모니터링 또는 공통 Clock Wizard 클록/Reset 내보내기가 필요하면 C안에서도 BD가 변경될 수 있다. 설계안 기록·코드 작성·정적 검토를 RTL_SIM/SYNTH_TIMING/BOARD PASS로 전용하지 않는다.

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
**PWM 비교 실험 제외(사용자 최신 결정):** Claude가 [Issue #4에서 제안](https://github.com/Yuul-Jung/soc/issues/4#issuecomment-6544700455)한 M1~M7 성능 측정 지표 및 소프트웨어 PWM/AXI Timer PWM/사용자 RTL PWM의 3단 성능 비교는 **교육과정에서 수행하지 않는다**. 해당 지표·대비 실험의 로그나 결과를 제출 조건으로 요구하지 않는다. 이는 새 범용 PWM IP 자체의 기본 기능 검증을 생략한다는 뜻이 아니다.


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
| 범용 PWM RTL·AXI 단독 검증 | 설정한 PWM 주기·Duty, 0%/100% 상수 출력, 주기 경계 설정 갱신, 극성, 다채널 동작, Reset·Register Map을 자기 명세와 대조 | `RTL_SIM` / `AXI_SIM`, 필요 시 `BOARD`로 기본 출력 확인 |
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
