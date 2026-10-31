# SoC 교재 구조 개편 및 자료 이관 대장

> 기준일: 2026-10-31. 이 문서는 **현행 확인 구조 / 목표 구조 / 이관 조건**을 구분한다. 파일 경로를 계획했다고 실제 생성된 것으로 취급하지 않는다.


> **편성 변경 (2026-10-31): 부별 10장 고정 편성은 폐지.** 이 문서에 표시된 신편 제2부 11–20장 및 제3–5부의 21–50장 번호는 초기 이관 기준 가안이다. 제2부는 11장부터 시작하고 필요 시 장 수를 늘리며, 후속 부 번호는 교육과정 재편성 확정 시 일괄 동기화한다. 기존 원본 01–41장 파일명·URL은 재편성과 무관하게 보존한다. 신규 제2부 첫 실습은 [Issue #3](https://github.com/Yuul-Jung/soc/issues/3)에서 추적한다.

## 1. 원칙

- 기존 `MicroBlaze_V_SoC01_41/`은 전체 이관·링크·이미지·다운로드·실습 검증 전 **삭제·이동·이름 변경하지 않는다**.
- 검증된 Vivado/Vitis 프로젝트도 기존 경로에서 보존한다.
- 기계적인 번호 변경 금지: 원본 11–41장은 신편 11–50장과 1:1 대응하지 않는다.
- 이미지/다운로드 파일의 상대 경로와 인코딩을 실제 브라우저에서 확인한다.
- 새 구조 검증 후 전환하고, 기존 링크 사용자에 대한 리디렉션/호환성을 별도 검토한다.

## 2. 현재 확인된 GitHub 구조

| 경로 | 2026-10-31 확인 결과 | 조치 |
|---|---|---|
| `index.html` | 통합 홈페이지 존재 | 5부 목록으로 갱신 필요 |
| `assets/site.css` | 공통 스타일 존재 | 유지·확장 |
| `part01/index.html` | 01–10장 옛 HTML로 링크 | 최종 이관 전까지 유지 |
| `part02/index.html` | '사용자 정의 IP' 안내용 | 새 제2부 목차로 개정 필요 |
| `part03/index.html` | 'SoC 응용 및 확장' 안내용 | 새 제3부 목차로 개정 필요 |
| `part04/` | 루트 목록에서 미확인 | 신규 구성 예정 |
| `part05/` | 루트 목록에서 미확인 | 신규 구성 예정 |
| `MicroBlaze_V_SoC01_41/pages/soc/` | 구 01–41장 및 07–10장 보조 해설 파일 존재 | 원본 보존 |
| `dev-board/` | **별도 저장소** | 참조 링크/버전 지정, 무단 이동 금지 |

## 3. 이관 목표 디렉터리 (아직 일괄 생성되지 않음)

```text
soc/
├── index.html
├── assets/
├── part01/
│   ├── index.html
│   ├── chapters/
│   ├── images/
│   └── files/
├── part02/
│   ├── index.html
│   ├── chapters/
│   ├── images/
│   └── files/
├── part03/
│   ├── index.html
│   ├── chapters/
│   ├── images/
│   └── files/
├── part04/
│   ├── index.html
│   ├── chapters/
│   ├── images/
│   └── files/
├── part05/
│   ├── index.html
│   ├── chapters/
│   ├── rtl_verification/
│   ├── uvm_verification/
│   └── reports/
├── MicroBlaze_V_SoC01_41/    # 이전 교재, 전환 완료 전 보존
├── CURRICULUM.md
├── MIGRATION.md
├── VALIDATION.md
└── COLLABORATION.md
```

실제 소스와 검증 파일은 과제별로 구성하되, 소스의 정본과 복제본이 섞이지 않도록 `dev-board` 원본 커밋을 기록한다.

## 4. 제1부 원본 → 신편 일람

원본 기본 경로: `MicroBlaze_V_SoC01_41/pages/soc/`

| 신편 | 기존 소스 파일 | 현재 연결 | 이관 상태 |
|---|---|---|---|
| 01 | `01_microblaze_bram_minimal_soc.html` | part01 목차에서 연결 | 본문 이동 전 |
| 02 | `02_clock_reset_processor_system_reset.html` | 연결 | 본문 이동 전 |
| 03 | `03_microblaze_bram_program_execution.html` | 연결 | 본문 이동 전 |
| 04 | `04_memory_map_memory_mapped_io.html` | 연결 | 본문 이동 전 |
| 05 | `05_axi4_axi4lite_axi4stream.html` | 연결 | 본문 이동 전 |
| 06 | `06_axi_gpio.html` | 연결 | 본문 이동 전 |
| 07 | `07_axi_uart_lite.html` + `07_1_uart_echo_c_code_guide.html` | 연결 | 본문 이동 전 |
| 08 | `08_axi_timer.html` + `08_1_axi_timer_c_code_guide.html` | 연결 | 본문 이동 전 |
| 09 | `09_axi_interrupt_controller.html` + `09_1_axi_interrupt_c_code_guide.html` | 연결 | 본문 이동 전 |
| 10 | `10_microblaze_gpio_uart_timer_integration.html` + `10_1_integration_c_code_guide.html` | 연결 | 본문 이동 전 |

'연결'은 `part01/index.html`에 링크가 있음을 뜻한다. 404·이미지 로딩·실습 동작을 이번에 전수 확인한 뜻은 아니다.

## 5. 구 11–41장 재분류 대장

현재 원본에 존재하는 구간을 **주제별로** 재분류한다. 신편 교재로 옮긴 상태는 아니다.

| 기존 범위 | 원본 주제 | 신규 활용 방향 | 상태 |
|---|---|---|---|
| 구 11–17 | Register Map, AXI4-Lite, Register Bank, C Driver, Packaging, RTL IP화 | 제2부 11장 공통 AXI IP 절차 및 각 주변장치 과제 | 내용 선별·재작성 필요 |
| 구 18–20 | UART/PWM Controller, AXI control/status, CDC/Reset | 제2부 PWM 및 제4부 CDC 참고 | 기능·중복 대조 필요 |
| 구 21 | Self-checking/Assertion/Coverage | 제5부 RTL 검증 기초 | 원본 재검증 필요 |
| 구 22–23 | Timing, 자원/전력/열 | 제4부 분석 실습 | 실제 보고서와 대조 필요 |
| 구 24–30 | MAC, PE, BRAM feeding, prefetch, data reuse, requantization | 제3부 NPU 과제 | 선수학습·코드 연결 검증 필요 |
| 구 31–36 | NPU AXI, interrupt, tensor buffer, job control, integration, software | 제3·4부 통합 | 실제 구현 경계 확인 필요 |
| 구 37–40 | 성능·최적화·병렬화 | 제4부 최적화 및 제3부 심화 참고 | 실측 근거 필요 |
| 구 41 | 최종 누적 검증 매트릭스 | 제4·5부 최종 평가 참고 | 실제 검증 근거 필요 |

### Basys3 사용자 IP 5개 확정 및 외부 확장 원칙 (2026-10-31 최신 결정)

- [CURRICULUM.md §3](CURRICULUM.md)에 따라 제2부 A단계에서 개발하는 **신규 사용자 IP는 정확히 다섯 종류: FND, 방향 버튼(Short/Long 통합), LED PWM, VGA, 키보드·마우스 공통 PS/2**이다. 이 개수는 내부 하위 RTL 모듈 수나 교육 장 수 제한이 아니다.
- 기존 01–10장의 AXI GPIO(Switch/LED), UART Lite, Timer, INTC, MicroBlaze V/BRAM/Clock/Reset은 **재사용**한다. 내부 XADC Wizard도 필요 시 AMD 기존 IP로 활용하되 신규 사용자 IP로 세지 않는다.
- **내장 Quad SPI Flash 32 Mbit(4 MB)는 비휘발성 FPGA 설정 비트스트림 보존용으로 취급**한다. 안전상 Flash 사용자 IP와 쓰기 실습은 제2부에서 제외한다. 설정 데이터 보호 및 모드/재구성은 제1부 인프라/부팅 설명만 참조한다. 공식 근거: [Digilent Basys3 Reference Manual §2·§3](https://www.amd.com/content/dam/amd/en/documents/university/aup-boards/XUPBasys3/documentation/Basys3_rm_8_22_2014.pdf).
- 키보드·마우스는 Basys3 USB Host의 PIC24→PS/2 변환을 통해 **공통 IP 하나**에서 선택 사용한다. 보드는 USB 허브를 지원하지 않으므로 동시 연결을 전제로 하지 않는다.
- B단계 **외부** HC-SR04/SG90/L298N/조도/DHT/BLE 등은 A단계 이후 연계하며 내용은 유지한다.
- 기존 이관 대장에 표시된 11–20 및 21–50 번호나 `dev-board` 자산 대응은 **이전 편성의 역사적 참고표**이다. 기존 `MicroBlaze_V_SoC01_41/` 원본·URL/성공 Vivado/Vitis 프로젝트는 변경하지 않으며, 신규 HTML/장 번호는 실습 성과·검증을 기준으로 별도 확정한다.
- 이번 커밋은 **교육과정 이관 방침만 기록**한다. RTL 시뮬레이션·AXI·합성/타이밍·실물·웹 통과를 주장하지 않는다.

## 6. dev-board 자산 편입 매핑

정본 저장소: https://github.com/Yuul-Jung/dev-board

| SoC 신편 | dev-board 참고 경로 | 이관 방식 | 주의 |
|---|---|---|---|
| 제2부 11 | `atlas/`, `rtl/rtl08_hc595_7seg/` | 핀/시분할 개념 참고 | 외부 74HC595와 Basys3 내장 FND 불일치 |
| 12 | `rtl/rtl01_button_led/`, `rtl/rtl02_rgb_buttons/` | 동기화·디바운스 Controller 검토 | Reset·핀 연계 |
| 13 | `rtl/rtl04_pwm_led/` | PWM RTL 재사용 검토 | AXI Timer와 기능 비교 |
| 14 | `rtl/rtl11_ultrasonic_event/` | FSM/카운터 재사용 검토 | Echo 5V 주의 |
| 15 | `rtl/rtl23_servo_pulse/` | 서보 제어 재사용 검토 | 실제 PWM 코어 연동 확인 |
| 16 | `rtl/rtl22_dc_motor/` | 방향·PWM 제어 재사용 검토 | 모터 안전·전원 |
| 17 | `rtl/rtl05_xadc_pwm/` | 샘플 처리 Controller 참고 | XADC Wizard 실제 연결 전 |
| 18 | `rtl/rtl12_dht22_alarm/` | 타이밍 FSM 참고 | 체크섬·타임아웃 |
| 19 | `rtl/rtl26_bt_command/` | 명령 Controller 참고 | UART PHY는 AMD IP 재사용 |
| 20 | `rtl/rtl29_integration/`, `rtl/rtl30_event_fifo/`, `rtl/rtl32_capstone_control/` | 기능별 선별 통합 | 실물 시스템 완성으로 단정 금지 |
| 제3부 | `rtl/rtl30_event_fifo/`, `rtl/rtl31_register_map/` | 버퍼·제어 레지스터 참고 | MAC/NPU 설계는 별도 |
| 제5부 | `rtl/*/tb/`, `rtl/verification/` | DUT·TB·테스트 결과 재사용 | CI PASS와 실물 검증 분리 |

각 적용 시 사용한 **dev-board 원본 커밋 SHA / 파일 경로 / 수정 여부**를 장별 문서에 기록한다.

## 7. 작업 카드 (장별 반복)

```text
Part / Chapter:
기존 원본 경로:
dev-board 원본 경로 및 커밋:
새 HTML 경로:
이미지·다운로드 파일 목록:
Vivado/Vitis 프로젝트 경로:
작성 AI / 검증 AI:
공식 문서 대조:
시뮬레이션 로그:
합성·타이밍 보고서:
실물 스크린샷·결과:
새 URL 열람:
미해결 항목:
최종 판정:
```

## 8. 전환 완료 Gate

1. 새 경로에 본문·원본 그림·파일·소스가 전부 존재한다.
2. HTML 상대 링크·모바일 레이아웃·UTF-8 한글·페이지 내비게이션·이미지 열람이 정상이다.
3. GUI 절차와 프로젝트 설정·주소·핀·클록·리셋이 일치한다.
4. 장의 성격에 맞는 시뮬레이션/합성/실물 검증 증거가 [VALIDATION.md](VALIDATION.md)에 연결되어 있다.
5. ChatGPT와 Claude의 독립 검토 및 수정 반영이 기록되어 있다.
6. GitHub Pages 새 URL을 실제 열어 확인한다.
7. 그 뒤에만 이전 경로 보존/리디렉션/삭제 여부를 별도로 결정한다.

## 9. 우선순위

**P0:** 원본 보호, 5부 구조 및 링크 정비, 실제 사용 중인 제1부 안정화.  
**P1:** 제2부 핵심 프로젝트(FND·버튼·PWM)와 dev-board 재사용 기준 확정.  
**P2:** 제3·4·5부 실습과 검증 환경 확장.  

2주 목표는 일정 목표이지, 실행하지 않은 검증의 완료 보증이 아니다.
