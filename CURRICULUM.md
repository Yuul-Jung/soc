# Basys3 + MicroBlaze V SoC — 통합 교육과정

> 문서 성격: 교육과정 설계 기준. 장 제목과 실습 배치는 **계획**이며, HTML 구현·시뮬레이션·보드 동작 완료를 뜻하지 않는다.
> 기준일: 2026-10-31 · 환경: Ubuntu, Basys3 (XC7A35T), Vivado/Vitis Unified IDE 2024.2

## 1. 전체 구성

| 부 | 초기 편성 번호(잠정) | 교육과정 | 완성 목표 |
|---|---|---|---|
| 제1부 | 01–10 | MicroBlaze V 기본 SoC 구축 | AMD 제공 IP를 활용한 CPU·BRAM·AXI 주변장치 SoC |
| 제2부 | 11–20 | 실시간 주변장치 및 사용자 AXI IP | CPU 제어와 클록 기반 RTL 타이밍 제어 분리 |
| 제3부 | 21–30 | 하드웨어 가속기 및 소형 NPU | MAC·BRAM·INT8 기반 실험용 병렬 연산기 |
| 제4부 | 31–40 | 고급 SoC 통합 및 최적화 | 데이터 이동·CDC·타이밍·전력·시스템 성능 분석 |
| 제5부 | 41–50 | SystemVerilog RTL 검증 및 UVM | 자동 판정 테스트, AXI 프로토콜, UVM, 회귀 검증 |

**편성 원칙 (2026-10-31 사용자 결정): 5부 구분은 유지하지만 각 부의 분량은 10장으로 고정하지 않는다.** 교육 목표·선수학습·실습 난이도·필요 검증 단위에 맞춰 장 수를 확장하거나 통합한다. 제2부는 11장부터 시작하되 20장에 끝나야 하는 것은 아니며, 제3–5부의 21–50 번호는 최초 가안의 자리표시자로서 제2부 편성 후 순차 재번호화한다. 이미 배포된 제1부 01–10장과 구 41장 원본은 변경하지 않는다. 새로 번호를 확정한 뒤 `MIGRATION.md`, HTML 목차·URL, 검증 매트릭스와 함께 동기화한다. 장 수 확대 자체를 구현 또는 검증 완료로 취급하지 않는다.

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

## 3. 제2부 — Basys3 내부 사용자 IP 3종(FND·PB SW·범용 PWM) → 외부 확장 (11장부터, 장 수 미확정)

> **2026-10-31 최종 사용자 결정(Claude Issue #4 독립 검토 후 기준):** 내부 신규 사용자 IP는 **① FND Controller, ② PB SW Controller(방향 버튼 4개 Short/Long), ③ 범용 PWM Controller**의 3종이다. 앞선 '필수 2종 + PWM 선택'은 과거 단계의 편성안으로 대체한다. **범용 PWM IP 자체는 제2부 개발 대상**, 개별 프로젝트가 PWM 기능을 연결할지는 선택이다. VGA·PS/2 키보드·마우스는 외부 카메라 입력과 묶는 후속 영상 심화로 보류한다. 기존 AXI GPIO/UART Lite/Timer/INTC/BRAM/Clock·Reset은 제1부 성과를 재사용한다. **11장 FND부터 시작**하며, 전체 장 수와 후속 장 번호는 확정하지 않는다([Issue #3](https://github.com/Yuul-Jung/soc/issues/3), [Issue #4](https://github.com/Yuul-Jung/soc/issues/4), [Issue #5](https://github.com/Yuul-Jung/soc/issues/5)).

### 3.1 내장 자원 목록과 구현 경계

공식 기준: [AMD Digilent Basys3 Board](https://www.amd.com/ko/corporate/university-program/aup-boards/digilent-basys3.html), [Digilent Basys3 rev.C Reference Manual](https://www.amd.com/content/dam/amd/en/documents/university/aup-boards/XUPBasys3/documentation/Basys3_rm_8_22_2014.pdf). 대상은 실제 Basys3 XC7A35T이며, 해당 보드 회로·마스터 XDC를 대조한다.

| 내장 자원 | 구성 방향 | 중복·제약 및 검증 |
|---|---|---|
| 4자리 7-Segment FND | **사용자 IP**: `fnd_scan_controller` + AXI4-Lite 레지스터 | AN/Segment Active-Low, 자리 스캔·표시 데이터 반영 타이밍 |
| 16 Switch / 16 LED | **기존 AXI GPIO 재사용**; 필요 시 LED 패턴/상태 Controller만 추가 | 기존 제1부 GPIO를 중복 재제작하지 않음 |
| 5 Pushbutton (BTNC는 기존 Reset) | **BTNU/BTND/BTNL/BTNR 방향 버튼 4개**: 2FF 동기화·디바운스·Short/Long(5초 이상) 이벤트·IRQ + AXI 레지스터 | **BTNC(U18)는 제1부 SoC Reset 용도로 유지**. 버튼별 독립 타이머·5초 경계·중복 이벤트·동시 입력·리셋·이벤트 유실 검증 |
| 범용 PWM(LED·FND·모터) | **③ 독립 사용자 IP**: 장치 비의존 PWM Core + 필요 시 AXI4-Lite 설정 Wrapper(주기·Duty·채널·극성·적용 경계) | 기존 AXI Timer PWM과 비교 후 차별 기능 검증. LED는 GPIO와 단일 출력 소유권, FND는 자리 슬롯에 동기, 모터는 외부 드라이버/전원 필요 |
| USB-UART Bridge | **기존 AXI UART Lite 재사용**; 명령/상태 Controller 또는 C 응용 추가 | USB-UART 브리지 자체를 FPGA에서 재구현하지 않음 |
| 12-bit VGA 출력 | **후속 영상 심화로 보류**: 외부 카메라 입력의 영상·오버레이 표시용 VGA 타이밍/픽셀 출력 | 현 FND/버튼 기반 제2부의 필수 IP 대상 아님; 실제 VGA 모니터·카메라·영상 버퍼·클록 제약 검토 후 별도 추진 |
| USB Type-A 키보드·마우스 | **후속 심화로 보류**: 카메라 영상/VGA 표시와 함께 마우스 커서·관심영역 선택에 사용하는 공통 PS/2 입력부, 키보드 해독은 추후 별도 선택 | 현 제2부 필수 IP 대상 아님; 보드 PIC24가 USB HID→PS/2로 변환하며 USB 허브 미지원(키보드 또는 마우스 한 번에 하나) |
| FPGA 내부 XADC | 기존 AMD XADC Wizard 등 **제공 IP 재사용**(필요 시 모니터용); **내부 사용자 IP 3종에는 불포함** | 내부 온도·전압 모니터는 선택적 통합 과제, 보드 내장 조도·온습도 센서가 아니며 외부 센서는 B단계 |
| 32 Mbit(4 MB) 직렬 Quad SPI Flash | **새 사용자 IP 대상에서 제외**. 비휘발성 FPGA 구성 비트스트림 저장·전원 켤 때 재구성 용도로 보존 | JTAG로 FPGA SRAM에만 설정한 경우 전원 OFF 시 소멸; Flash에 저장한 경우 모드 선택에 따라 부팅 가능. 공식 매뉴얼상 사용자 데이터 공간은 일부 존재하지만 본 과정에서 Flash 쓰기/포맷 실습 제외 |
| 100 MHz Clock / Clock·Reset | 기존 Clock Wizard/Reset 구조 **공용 기반 인프라** | 사용자 주변장치로 중복 IP화하지 않음 |
| 3개 디지털 Pmod + XADC용 Pmod | **외부 모듈 연결용 포트**; 내부 기능/센서로 간주하지 않음 | 보드 XDC, I/O 전압·전원·핀 배치 선확인 |
| JTAG/PROG/전원 상태 LED | FPGA 설정·보드 지원 회로 | 제어 가능한 사용자 GPIO로 오인하거나 별도 주변장치 IP 대상에 넣지 않음 |

### 3.2 제2부 A단계 — 사용자 IP 3종 우선 개발

| 순서 | 사용자 IP | 핵심 기능·재사용 경계 |
|---|---|---|
| **11장 (확정된 시작점)** | **① FND Controller** | Basys3 내장 4자리 FND 자리 스캔·Active-Low 세그먼트·표시값·AXI 제어. **기본 밝기 100%**, 후속 범용 PWM과 자리 슬롯 동기 연계. [Issue #3](https://github.com/Yuul-Jung/soc/issues/3) |
| 후속(장 번호 미정) | **② PB SW Controller** | BTNC(U18)는 기존 SoC Reset 유지. BTNU/BTND/BTNL/BTNR 4개에서 2FF·디바운스·Short(<5초, 해제 시)·Long(≥5초, 임계값 도달 시) 1회 이벤트·Sticky 상태·선택 IRQ. [Issue #5](https://github.com/Yuul-Jung/soc/issues/5) |
| 후속(장 번호 미정) | **③ General PWM Controller** | **독립·범용 PWM IP**. LED/FND 밝기·외부 모터 드라이버 속도 제어 등에서 동일한 Core 재사용. 입력 주기·Duty·극성·갱신 정책 및 다채널 확장, AXI 래퍼는 기능 범위에 맞춰 분리. FND는 Scan Slot 연동 필요 |

**① FND 11장 실습의 내부 절차 분할(같은 장 안 3단계, 장 번호 변경 아님):** (a) FND RTL Scan Controller + 독립 TB → (b) AXI4-Lite Register Bank/Wrapper + IP Packager + AXI TB → (c) Vitis C 제어 + 실물 Basys3 검증 + HTML. FND 스캔·밝기 연계의 독립성을 지키되, **범용 PWM 실습을 11장의 선수조건으로 요구하지 않는다**. 11장의 기본 밝기는 100%이고, PWM 재사용/슬롯 동기는 ③ 개발 이후 통합 실습에서 검증한다.

**범용 PWM과 제1부 AMD AXI Timer 차별화(정당화):** AMD [PG079](https://docs.amd.com/r/en-US/pg079-axi-timer)의 AXI Timer에는 **2개 Timer를 한 쌍으로 묶어 PWM0 한 채널을 생성**하는 모드가 있다. 따라서 단순 1채널 PWM을 또 만드는 것만으로는 독립 IP의 필요성이 약하다. 이 과정의 ③은 **모듈형 재사용, 다채널 확장, 정확한 0%/100% 처리, 주기 경계 설정 갱신, 선택 가능한 출력 극성, FND Slot 동기 입력**을 직접 검증하는 데 차별점이 있다. 사용 Vivado 2024.2 내 실제 AXI Timer IP 구성과 PG079 버전을 대조해야 하며, PG079 본문만으로 해당 제품의 0%·100% 듀티 제약 및 재설정 글리치를 확정하지 않는다. `dev-board/rtl/rtl04_pwm_led/src/pwm_core.v`는 기존 약 1kHz/256단계 PWM 예시이므로 범용화 시 주기·채널·출력 정책을 확장한다.

**FND 밝기와 PWM 경계:** FND의 `an[3:0]`, `seg[6:0]`, `dp`는 Active-Low. 4자리 스캔 슬롯과 무관하게 프리런하는 PWM 하나로 자릿수 전체를 게이팅하면 자리별 밝기가 달라질 수 있다. FND 모드에서는 **자리 슬롯 시작에 PWM 위상 동기화**하고, 자리 전환 때 소등(Blanking) 시간을 고려한다. 모터 PWM은 FND 슬롯/LED 표시와 독립된 주기로 운용한다. **같은 Core를 사용하더라도 응용별 동기화·출력 래퍼는 구분**한다.

**버튼 5초 검증 방식(Claude 제안 수용):** 1 ms Tick 분주를 TB에서 파라미터로 축소하고 4,999/5,000/5,001 Tick, 바운스·동시 입력·반복·리셋·W1C 충돌을 검증한다. 실제 100 MHz에서 1 ms는 **100,000 클록**인지 분주기 단독 검증을 추가하고, 실제 5초 길이는 Basys3에서 계측한다. 축소 TB 통과를 실제 5초 보드 검증 통과로 바꾸어 기록하지 않는다.

**원본 보존·연동:** 기존 제1부 AXI GPIO/UART Lite/Timer/INTC 및 Clock/Reset은 재사용하고 기존 `/home/jung/soc/hw/soc_hw.xpr`, `/home/jung/soc/sw`와 구 41장 HTML 원본은 변경하지 않는다. 세 IP는 각각 독립 Core/TB/프로젝트로 개발하여 필요한 경우에만 새 SoC 프로젝트에서 선택적으로 통합한다. LED는 AXI GPIO와 PWM이 물리 핀을 동시에 구동하지 않게 출력 Controller에서 선택한다. 모터는 PWM 신호를 직접 연결하지 않고 L298N 등 드라이버 및 안전한 외부 전원을 사용한다.

### 3.3 제2부 B단계 — 보드에 없는 외부 주변장치 연결 (A단계 이후)

| 권장 순서 | 외부 모듈 / 실습 | 기술 및 안전 기준 | `dev-board` 후보 |
|---|---|---|---|
| B1 | Pmod 연결·3.3 V I/O·레벨 변환 | 핀맵·공통 GND·전원·입력 보호 | `atlas/` (참고) |
| B2 | HC-SR04 초음파 | Trigger/Echo, timeout, Echo 5 V 레벨 변환 | `rtl/rtl11_ultrasonic_event/` |
| B3 | SG90 서보 | 펄스 타이밍, 외부 전원·공통 GND | `rtl/rtl23_servo_pulse/` |
| B4 | L298N DC 모터 | PWM·방향/데드타임 보호·외부 전원 | `rtl/rtl22_dc_motor/` |
| B5 | 조도센서 및 ADC | 외부 센서 → XADC 입력 한계·ADC 선택 | `rtl/rtl05_xadc_pwm/` |
| B6 | DHT 계열 온습도 | 1-wire 타이밍·체크섬·timeout | `rtl/rtl12_dht22_alarm/` |
| B7 | UART형 BLE | 기존 AXI UART Lite 재사용·명령 응답 | `rtl/rtl26_bt_command/` |
| B8 | **외부 센서·구동기 통합 SoC** | Event FIFO, CPU/RTL 역할·자원·실물 안전 | `rtl/rtl29_integration/`, `rtl/rtl30_event_fifo/`, `rtl/rtl32_capstone_control/` |

새로 필요한 사용자 IP는 **정밀 시간 제어·이벤트 처리·표시 처리·다중 동작 병렬화**에 집중한다. I2C/SPI/일반 GPIO/UART와 같은 공통 주변장치 기능은 AMD 지원 IP·필요 시 외부 MCU 중계 활용을 먼저 검토하고 중복 RTL 구현을 필수화하지 않는다.

### 3.4 공통 구현·검증 원칙

1. 내부 사용자 IP 3종(FND·PB SW·범용 PWM)은 **기능 독립 Controller/Core → 독립 RTL TB → 필요할 때 AXI4-Lite Wrapper/Register Bank → 별도 MicroBlaze V SoC 연동** 순서로 개발한다. Top은 배선·인스턴스·상수 연결만 담당하고, 원본 제1부 프로젝트를 수정하지 않는다.
2. 제1부에서 `btnC`(Center Button, FPGA 핀 U18)를 `Clocking Wizard`/`Processor System Reset`의 시스템 Reset 입력으로 사용했다. 제2부에서도 **해당 Reset 경로를 보존**하고, 버튼 이벤트 IP는 **방향 버튼 4개(BTNU/BTND/BTNL/BTNR)**만 연결한다. RESET 용도로 할당한 버튼은 동시에 일반 이벤트 입력으로 쓰지 않는다. 원본 근거: `MicroBlaze_V_SoC01_41/docs/soc01.md`, `docs/soc02.md`, `docs/soc10.md`, `code/soc10/basys3_soc10_integrated.xdc`.
3. 새 IP는 독립 RTL TB를 필수로 검증하고, AXI 인터페이스를 추가하는 장에서는 별도 Register Map·AXI 핸드셰이크/리셋·TB 증거를 남긴다. 합성/타이밍·Basys3 실물·HTML 검증도 **서로 다른 증거**로 관리한다. PWM은 0/100%, 1주기 동기 갱신, 극성, 다채널/주기 설정을 검증한다.
4. `dev-board/rtl/rtl08_hc595_7seg/`는 **외부 74HC595 용도**로 Basys3 내장 FND에 직접 사용할 수 없다. 단지 참고하며, 참고 원본 SHA 및 수정 이력을 남긴다.
5. 외부 모듈은 실제 데이터시트·핀·전압·전류·전원 분리·제어 방향을 확인한 뒤 추가한다.
6. 제2부 종료 장 수가 확정되면 제3–5부의 최초 계획 번호를 재편성하되 기존 `MicroBlaze_V_SoC01_41/` 파일명·URL·검증 프로젝트는 보존한다.


### 3.5 후속 심화 가안 — 카메라 입력 + VGA 출력 + PS/2 마우스 영상 시스템 (현 단계 보류)

- **사용자 제안(2026-10-31):** VGA와 마우스를 각각 단독 필수 IP로 만들지 않고, 나중에 외부 **카메라 영상 입력과 동일한 학습 단계**에서 통합 실습으로 다룬다. 편성 부·장 번호와 실제 회로·프로젝트는 **미확정**. 고급 SoC 통합 또는 별도 영상 응용 블록으로 향후 검토한다.
- 교육 흐름: 카메라의 픽셀/라인/프레임 동기 신호 수신 → 작은 영상 버퍼 또는 라인 버퍼 및 필요 시 클록 도메인 교차 → VGA 영상/상태 오버레이 출력 → PS/2 마우스 커서·관심영역(ROI) 제어.
- **난이도 구분:** 카메라는 외부 인터페이스 전압·카메라 설정용 버스·픽셀 클록·입력 대역폭·메모리 용량이 핵심; VGA는 출력 픽셀 타이밍·HS/VS가 핵심; 마우스는 보드 PIC24가 USB HID를 PS/2로 변환해 주므로 패킷 수신/좌표만 구현한다. 세 인터페이스는 **동일한 구현 난이도**라고 보지 않는다.
- Basys3 XC7A35T 온칩 BRAM은 약 1,800 Kbits(약 225 KB)이므로 640×480 RGB565 전체 프레임(600 KiB)은 온칩 메모리에 맞지 않는다. 저해상도/부분 프레임/라인 버퍼 등 자원 제약에 맞춘 영상 경로가 필요하며, 카메라 커넥터·핀 수·전압·클록 경로를 실제 보드/모듈 데이터시트로 검증한다.
- USB 마우스와 USB 키보드는 Basys3 USB Host 경로에서 허브 동시 사용을 전제로 하지 않는다. 키보드 해독은 영상 통합과 별도로 필요할 때 추가하는 **후속 선택 사항**이다.
- 이 항목은 후속 학습 아이디어 등록이며 **RTL_SIM·AXI_SIM·SYNTH_TIMING·BOARD·WEB 모두 미실시/미확인**이다.

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
