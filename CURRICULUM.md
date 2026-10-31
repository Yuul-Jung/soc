# Basys3 + MicroBlaze V SoC — 통합 교육과정

> 문서 성격: 교육과정 설계 기준. 장 제목과 실습 배치는 **계획**이며, HTML 구현·시뮬레이션·보드 동작 완료를 뜻하지 않는다.
> 기준일: 2026-10-31 · 환경: Ubuntu, Basys3 (XC7A35T), Vivado/Vitis Unified IDE 2024.2

## 1. 전체 구성

| 부 | 장 번호(신규 편성안) | 교육과정 | 완성 목표 |
|---|---|---|---|
| 제1부 | 01–10 | MicroBlaze V 기본 SoC 구축 | AMD 제공 IP를 활용한 CPU·BRAM·AXI 주변장치 SoC |
| 제2부 | 11–20 | 실시간 주변장치 및 사용자 AXI IP | CPU 제어와 클록 기반 RTL 타이밍 제어 분리 |
| 제3부 | 21–30 | 하드웨어 가속기 및 소형 NPU | MAC·BRAM·INT8 기반 실험용 병렬 연산기 |
| 제4부 | 31–40 | 고급 SoC 통합 및 최적화 | 데이터 이동·CDC·타이밍·전력·시스템 성능 분석 |
| 제5부 | 41–50 | SystemVerilog RTL 검증 및 UVM | 자동 판정 테스트, AXI 프로토콜, UVM, 회귀 검증 |

**번호 주의:** 위 11–50장은 새 교육과정의 가안이다. `MicroBlaze_V_SoC01_41/pages/soc/11_...41_...` 기존 파일의 장 번호 및 내용과 1:1 대응하지 않는다. 기존 문서를 이름만 바꿔 새 장으로 취급하지 않는다.

## 2. 제1부 — 기본 SoC (기존 교재 01–10장)

| 장 | 내용 | 현행 원본 |
|---|---|---|
| 01 | MicroBlaze V + BRAM 최소 SoC | `01_microblaze_bram_minimal_soc.html` |
| 02 | Clock / Reset / Processor System Reset | `02_clock_reset_processor_system_reset.html` |
| 03 | MicroBlaze V BRAM 프로그램 실행 | `03_microblaze_bram_program_execution.html` |
| 04 | Local BRAM Memory Map 읽기·쓰기 | `04_memory_map_memory_mapped_io.html` |
| 05 | AXI4 / AXI4-Lite / AXI4-Stream 구조 | `05_axi4_axi4lite_axi4stream.html` |
| 06 | AXI GPIO | `06_axi_gpio.html` |
| 07 | AXI UART Lite | `07_axi_uart_lite.html` |
| 08 | AXI Timer | `08_axi_timer.html` |
| 09 | AXI Interrupt Controller | `09_axi_interrupt_controller.html` |
| 10 | GPIO·UART·Timer 통합 | `10_microblaze_gpio_uart_timer_integration.html` |

실제 페이지 경로는 `MicroBlaze_V_SoC01_41/pages/soc/` 아래이며, 07–10장에는 일부 `_1_` 형식의 C 코드 해설 보조 페이지가 있다. `part01/index.html`은 현재 이 원본으로 연결한다. 페이지의 '완료' 배지는 **사이트 표기**이며 본 문서가 하드웨어 전수 검증을 새로 확인했다는 뜻은 아니다.

## 3. 제2부 — 실시간 주변장치 / 사용자 AXI IP (11–20, 설계안)

| 장 | 프로젝트 | 기존 dev-board 참고 | 검증의 핵심 |
|---|---|---|---|
| 11 | Basys3 4자리 FND 사용자 AXI IP | `atlas/`, `rtl/rtl08_hc595_7seg/`(개념만) | 내장 FND 전용 자리 스캔, Active-Low 핀, 레지스터 |
| 12 | 버튼 입력·디바운스·이벤트 IP | `rtl01_button_led/`, `rtl02_rgb_buttons/` | 2FF 동기화·바운스·리셋·동시 입력 |
| 13 | 하드웨어 PWM 출력 IP | `rtl04_pwm_led/` | 0/100% 듀티·주기 경계·지터·갱신 시점 |
| 14 | HC-SR04 초음파 거리 측정 | `rtl11_ultrasonic_event/` | Trigger/Echo, Timeout, 5V 입력 보호 |
| 15 | SG90 서보 제어 | `rtl23_servo_pulse/` | 펄스 폭·프레임 주기·전원 분리 |
| 16 | L298N DC 모터 제어 | `rtl22_dc_motor/` | 방향 전환 보호·PWM·외부 전원 |
| 17 | 조도·ADC 측정 | `rtl05_xadc_pwm/` | XADC/외부 ADC 경로 선택·입력 범위 |
| 18 | DHT 계열 온습도 센서 | `rtl12_dht22_alarm/` | 단일선 타이밍·체크섬·타임아웃 |
| 19 | UART형 BLE 제어 | `rtl26_bt_command/` | 기존 AXI UART Lite 재사용·명령/응답 |
| 20 | 실시간 주변장치 통합 SoC | `rtl29_integration/`, `rtl30_event_fifo/`, `rtl32_capstone_control/` | 이벤트 누락·CPU/RTL 역할 구분·실물 |

**중요:** `rtl08_hc595_7seg`는 외부 74HC595용이며 Basys3 내장 FND에 직접 사용하는 소스가 아니다. AMD가 제공하는 GPIO/UART/Timer/IIC/SPI 등을 기능적으로 중복 재구현하지 않는다. 사용자 IP는 정밀 타이밍·특수 기능·병렬 처리에 집중한다.

## 4. 제3부 — 하드웨어 가속 / NPU (21–30, 설계안)

| 장 | 프로젝트 | 검증 포인트 |
|---|---|---|
| 21 | AXI 제어형 덧셈 가속기 | START/BUSY/DONE, 레지스터 |
| 22 | 곱셈·누산 MAC | signed/unsigned, 누산 비트 폭 |
| 23 | 다중 MAC 및 파이프라인 | 데이터 정렬·처리량 |
| 24 | BRAM 데이터·가중치 버퍼 | 주소·읽기 지연·포트 충돌 |
| 25 | 벡터 내적 | Python 기준 모델 비교 |
| 26 | INT8 고정소수점 | 반올림·포화·오버플로 |
| 27 | 버퍼링과 AXI 데이터 경로 | 실제 지원 가능한 데이터 이동 방식 선택 |
| 28 | 소형 Dense Layer | 가중치·바이어스·ReLU |
| 29 | MicroBlaze V 소프트웨어 제어 | 입력·실행·상태·출력 |
| 30 | 소형 NPU 통합 | 성능·자원·타이밍 및 정답 비교 |

Basys3 자원 제약을 고려한다. DMA/AXI4-Stream은 실제 IP 연결과 메모리 구조가 확인된 경우에만 필수 실습으로 확정한다.

## 5. 제4부 — 고급 SoC 통합 및 최적화 (31–40, 설계안)

| 장 | 프로젝트 | 검증 포인트 |
|---|---|---|
| 31 | SoC 시스템 아키텍처 정비 | CPU·IP·BRAM 주소 맵 |
| 32 | AXI4 / AXI4-Stream / FIFO | backpressure·데이터 보존 |
| 33 | DMA / 대용량 데이터 이동 타당성 및 구현 | IP 지원·BRAM 제약·실측 |
| 34 | 멀티클록·CDC·Reset | 동기화·비동기 FIFO·복구 |
| 35 | 인터럽트 및 이벤트 응답 | 누락·지연·우선순위 |
| 36 | 통합 테스트 자동화 | 스크립트·회귀 실행·로그 |
| 37 | 타이밍 분석 및 개선 | Setup/Hold, WNS/TNS |
| 38 | 자원·전력 분석 | LUT/FF/BRAM/DSP, 추정과 실측 구분 |
| 39 | 센서 → NPU → 실시간 출력 통합 | 최종 시스템 지연과 안정성 |
| 40 | 통합 SoC 결과물 배포 | 프로젝트 재현·버전·산출물 |

제4부의 검증 자동화는 시스템 구현 검증이며, UVM 전문 실습은 제5부에서 다룬다.

## 6. 제5부 — RTL Verification / UVM (41–50, 설계안)

| 장 | 프로젝트 | 검증 대상 |
|---|---|---|
| 41 | SystemVerilog 테스트벤치 | FND Controller |
| 42 | Self-checking 테스트벤치 | PWM·버튼·센서 |
| 43 | SVA Assertion | FSM·Handshake·Reset |
| 44 | Functional Coverage | 코너 케이스·기능 커버리지 |
| 45 | AXI4-Lite 프로토콜 검증 | AW/W 분리, B/R, backpressure |
| 46 | UVM 구성요소 기초 | Sequence·Driver·Monitor |
| 47 | UVM Agent / Scoreboard | AXI 및 FND 레지스터 |
| 48 | UVM RAL | Register Map의 읽기·쓰기 |
| 49 | NPU UVM 검증 | MAC·BRAM·정답 모델 |
| 50 | 회귀 검증 및 검증 보고서 | RTL/UVM 별도 결과 보존 |

제2·3부에서도 기본 RTL 테스트를 생략하지 않는다. 제5부는 이를 확장한 독립 검증 과정이다. UVM은 사용 도구의 실제 지원 범위를 확인한 후 실행·판정한다.

## 7. 공통 설계 원칙

1. MicroBlaze V는 명령·설정·상태 관리, RTL은 정밀 타이밍·병렬 연산 담당.
2. AXI4-Lite는 주로 제어·상태 레지스터용. 대량 데이터 경로는 별도 설계·검증.
3. 기능 Controller는 보드·Top과 독립화하고, Top은 연결 중심으로 유지.
4. 기존 AMD IP와 `dev-board`의 성공 코드를 우선 재사용하되 실물 검증 여부는 별도 확인.
5. 보드 외부 모듈은 전원·I/O 허용 전압·레벨 변환·핀 자원을 먼저 검토.
6. 각 장의 최종 산출물: 단계별 HTML, 재현 가능한 소스/프로젝트, 실행 증거, 검증 상태.
7. 변경 관리: [MIGRATION.md](MIGRATION.md) · 검증: [VALIDATION.md](VALIDATION.md) · 협업: [COLLABORATION.md](COLLABORATION.md).

## 8. 진행 상태

- 현재 저장소에 `part01/`, `part02/`, `part03/`가 있다.
- `part01/index.html`은 기존 01–10장 교재를 참조한다.
- `part02/index.html`, `part03/index.html`은 이전 기획을 설명하는 안내 페이지이며 본 문서의 새 편성과 아직 불일치한다.
- `part04/`, `part05/`는 이 문서 작성 시점에 저장소 루트에서 확인되지 않았다.
- 제2–5부의 모든 실습 완료를 선언하지 않는다.
