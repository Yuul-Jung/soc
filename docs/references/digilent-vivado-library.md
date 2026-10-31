# Digilent Vivado Library — SoC/RTL 참고자료 및 외부 모듈 활용 원칙

> 구분: **참고자료** (필수 실습 부품·검증 완료 IP 목록 아님)  
> 대상: Basys3 (XC7A35T), MicroBlaze V, Vivado/Vitis 2024.2  
> 기준: 2026-10-31 사용자 결정 및 업로드된 `vivado-library-master.zip`의 정적 파일 목록 확인  
> 정본: [CURRICULUM.md §3](../../CURRICULUM.md) · [PROJECT_STATE.md](../../PROJECT_STATE.md) · [COLLABORATION.md](../../COLLABORATION.md)

## 1. 참고 출처 및 관리 방식

- Digilent 공식 원본: https://github.com/Digilent/vivado-library
- 원본 설명: Xilinx/AMD Vivado IP Catalog용 IP Core·인터페이스 정의 모음.
- 확인한 사용자 제공 자료: `vivado-library-master.zip` (이 문서에 ZIP 원본은 첨부하지 않음).
- 압축본 정적 확인: 전체 ZIP 엔트리(폴더 포함) **3,172개**, `component.xml` **66개**. 이는 포함된 IP 정의 파일 수이며, 모두 독립·지원·동작 검증된 IP라는 의미는 아니다.
- 라이선스: 압축본 최상위 `License.txt`에 **MIT License (Copyright 2017 Digilent)** 명시. 제3자 소스 재배포 시 해당 라이선스 및 저작권 고지를 유지한다.
- **원본 ZIP 전체를 `soc`에 복제하지 않는다.** 필요 시 공식 저장소의 특정 경로와 고정 커밋 SHA를 기록하고, 해당 코드를 참고하여 독립 IP를 구현한다.
- 사용자가 제공한 ZIP은 참고 스냅샷으로만 취급하며 공식 GitHub의 최신 버전과 동일하다고 가정하지 않는다.

## 2. 사용자의 최종 하드웨어 선택 기준

1. **Digilent 전용 Pmod/Zmod 모듈 구매를 전제로 교육과정을 구성하지 않는다.** 상대적으로 높은 가격·구매 난이도와 실물 검증 어려움 때문이다.
2. **국내에서 저렴하고 쉽게 구하거나 AliExpress에서 구매 가능한 Arduino 호환 범용 모듈**을 우선한다. 'Arduino 호환'은 Arduino 보드를 반드시 함께 쓴다는 뜻이 아니다.
3. Basys3에 직접 연결해 RTL·AXI IP를 개발하는 구조가 기본이다. 외부 MCU 중계는 전기적/구현상 이점이 있을 때 별도 선택한다.
4. 모듈 선택 시 실제 판매 모델의 **데이터시트, 핀맵, I/O 전압, 전원 전류, 논리 레벨, 타이밍, 구매 가능 여부**를 확인한다. Arduino용/5V용이라는 사실만으로 Basys3 3.3V FPGA I/O에 직접 연결하지 않는다.
5. 일반 통신/기반 기능은 기존 AMD 제공 IP의 재사용을 먼저 검토하고, 교육 가치가 있는 고유 기능만 독립 RTL Core와 필요 시 AXI4-Lite Wrapper로 구현한다.

## 3. 압축본에서 확인한 IP의 활용 구분

| 라이브러리 예시 (실제 압축본 경로) | 부품 의존성 | 본 교육과정 판단 |
|---|---|---|
| `ip/Pmods/PmodALS_v1_0/`, `PmodGYRO_v1_0/`, `PmodOLED_v1_0/` | 특정 센서·표시장치와 인터페이스 의존 | 해당 하드웨어가 없으면 실물 시험용으로 사용하지 않음. 버스·드라이버 구조 참고 |
| `ip/Pmods/PmodCAN_v1_0/`, `PmodBT2_v1_0/`, `PmodESP32_v1_0/` | 대상 통신 모듈 및 펌웨어/핀 조건 의존 | 범용 통신 개념 참고. 실제 선택 모듈에 맞춰 별도 설계 |
| `ip/Zmods/` | Zmod 계열 하드웨어 의존 | 현재 Basys3 기본 실습 대상에서 제외 |
| `ip/PWM_1.0/`, `ip/PWM_2.0/`, `ip/PWM_Analyzer_1.0/` | RTL/AXI 구조 자체는 참고 가능 | **범용 PWM 자체 제작 시 참고**. 원본을 그대로 복제해 사용자 설계 완료로 취급하지 않음 |
| `ip/axi_ps2_1.0/`, `ip/Sync_v1_0/`, `ip/clock_forwarder/` | 기능별 장치·클록 조건 차이 | 프로토콜·동기화·구조 참고. 현 제2부 필수 기능으로 추가하지 않음 |

**실제 확인 예:** `ip/PWM_2.0/`에 `hdl/PWM_AXI.sv`, `hdl/PWM_v2_0.sv`, `drivers/PWM_v1_0/src/PWM.c`, `PWM.h`가 포함되어 있다. AXI 인터페이스·RTL·C 드라이버의 역할 분리를 연구하는 데 유용하나, 이 사실만으로 Vivado 2024.2/MicroBlaze V에서 호환·합성·실물 동작이 입증되는 것은 아니다.

## 4. Basys3에서 활용할 범용 모듈 후보

| 후보 모듈 | 연결/실습 개념 | 전기적·검증 주의사항 |
|---|---|---|
| HC-SR04 초음파 센서 | GPIO 펄스·Echo 시간 계측·타임아웃 | 통상 Echo 5V → FPGA 입력에 레벨 변환 필요 |
| SG90 서보 | PWM 제어 펄스·타이밍 | 모터 전원 별도 공급·공통 GND·I/O 인식 레벨 확인 |
| L298N DC 모터 드라이버 | PWM + 방향 제어 | 모터용 외부 전원, 전류/발열, 공통 GND, 논리 입력 조건 확인 |
| CDS/조도 센서 모듈 | 디지털 임계값 GPIO 또는 아날로그 취득 | 아날로그는 XADC의 **실제 보드 입력 허용 범위**와 전처리 회로를 먼저 검토 |
| DHT 계열 온습도 센서 | 단일 데이터선 타이밍·체크섬·타임아웃 | 모듈 풀업 전압이 FPGA 허용 범위를 넘지 않게 설정 |
| UART형 BLE/시리얼 모듈 | 기존 AXI UART Lite 재사용, 명령/응답 | TX/RX 방향·전압 레벨·모듈별 펌웨어/통신 조건 확인 |
| MAX7219 도트매트릭스 | 시리얼 제어·레지스터 데이터 표시 | 5V 구동 모듈의 입력 HIGH 인식·레벨 변환 여부 확인 |

> 위 목록은 **구매/실습 후보**이지 구매 완료·소지·배선 검증을 뜻하지 않는다. 구체 모델명과 데이터시트 확인 전 실습 확정 금지.

## 5. 현행 SoC 교육과정에 적용할 범위

- **제1부(01–10장):** 기존 MicroBlaze V + BRAM + AMD AXI GPIO/UART Lite/Timer/INTC/Clock·Reset 유지. 성공 원본·HTML을 변경하지 않는다.
- **제2부 A단계:** [CURRICULUM.md §3](../../CURRICULUM.md)의 **사용자 IP 3종** — ① FND Controller(11장 시작), ② 방향버튼 4개 Short/Long Controller(BTNC는 Reset 보존), ③ 범용 PWM Controller — 를 독립 RTL 및 필요 시 AXI Wrapper로 개발한다. Digilent PWM IP는 참조 구현일 뿐이다.
- **PWM 실습 범위:** Core 기능·레지스터·AXI·테스트는 현행 계획대로 유지한다. **PWM 성능 측정 지표(M1~M7)와 소프트웨어 PWM/AXI Timer PWM/사용자 RTL PWM 3단 성능 비교 실험은 진행하지 않는다.**
- **제2부 B단계:** 저가 범용 모듈 중심으로 초음파 → 서보 → DC 모터 → 조도/ADC → DHT → UART BLE → 통합 확장. 실제 선수학습과 하드웨어 확보에 따라 순서를 조정할 수 있다.
- **I2C:** 현재 제2부에 무리하게 통합하지 않고 별도 독립 과제로 검토한다. SPI 등 공통 통신 기능도 필요성에 따라 AMD IP·재사용 가능한 IP·외부 MCU 중계 중 선택한다.
- **구현 구조:** 보드 Top은 배선 중심 Shell/Wrapper; 기능은 독립 Controller/Core; 외부 모듈·핀/전원·클록 정책은 명시한다.

## 6. Vivado IP 등록은 선택 사항

Digilent IP를 직접 열어 구조를 확인해야 할 경우에만 등록한다.

1. 원본을 로컬에 내려받거나 ZIP을 압축 해제한다.
2. 기존 Vivado 프로젝트에서 `Project Settings → IP → Repository → Add` 경로로 IP Repository를 등록한다. 설치 전체의 기본값은 원본 README가 안내하는 `Tools → Options → General → IP Catalog` 경로를 참고한다.
3. 해당 IP의 `component.xml`, RTL, 의존 XCI/BD, 드라이버를 확인한다.
4. Vivado/Vitis 2024.2, MicroBlaze V, Basys3(XC7A35T)에서 필요한 의존성·버전·합성 가능 여부를 **별도 검증**한다.

**등록 성공 ≠ IP 호환/실물 동작 확인.** 특정 Pmod/Zmod 전용 IP를 이름만 바꿔 범용 Arduino 모듈용으로 사용하지 않는다.

## 7. 검증·인계 기록 원칙

선별해서 실제 채택하는 IP마다 다음을 기록한다.

- 공식 원본 URL·참조 SHA·라이선스, 대상 외부 모듈의 정확한 모델/데이터시트
- FPGA 핀과 연결 구조, 3.3V I/O·레벨 변환·전원·공통 GND
- Core/AXI Wrapper/드라이버의 역할 및 재사용 범위
- RTL TB, AXI TB, 합성/타이밍, 실물 보드 시험을 **각각 분리**한 증거/상태
- 원본과 달라진 코드, 검증되지 않은 부분, 최종 사용 여부

**상태(2026-10-31):** 업로드 ZIP의 정적 파일·라이선스 확인만 수행. IP 빌드, Vivado 2024.2 통합, MicroBlaze V 동작 및 Basys3 실물 시험은 **미실시**. 이 참고 문서 등록만으로 교재 장 완료나 실습 검증 PASS를 선언하지 않는다.
