# Basys3 + MicroBlaze V SoC 41장 교재 제작·검증 지침

> **2026-10-27 개정 · 07장 스타일 기준**  
> 기준 페이지: [SoC 07 — AXI UART Lite](pages/soc/07_axi_uart_lite.html)  
> 실제 검증 범위: [SOC07_VALIDATION.txt](validation/SOC07_VALIDATION.txt)

이 지침은 41장 교재의 신규 집필과 기존 페이지 보완에 공통 적용한다. **07장 문서·이미지·정적 검증 성공은 Vivado XSim 또는 Basys3 실제 보드 검증 성공을 뜻하지 않는다.**

## 1. 교재의 성격과 실습 범위

- **41장 전체가 독립적으로 완결되는 Basys3 + MicroBlaze V SoC 따라 하기 실습서**이다. 별도의 RV32I CPU 설계 34장 과정은 필수 선수학습이나 필수 후속 과정이 아니다.
- 기준 환경: Ubuntu, Basys3, Vivado/Vitis Unified IDE 2024.2.
- 원칙: **왜 필요한가 → 실제 GUI 작업 → 입력·설정값 → 성공 여부 확인 → 짧은 동작 해설**.
- 앞 장의 성공 절차를 중복 반복하거나 다음 장에서 구현할 주변장치를 미리 구현하지 않는다.
- 영문 전문용어는 최초 1회 한글 발음·간단한 뜻을 병기하되 실제 IP, Port, GUI, 함수, HDL 코드 명칭은 원문 그대로 유지한다.
- 쉽고 직관적인 한글 설명, 필요한 만큼의 그림, 짧은 문단과 표를 우선하며 사족은 줄인다.

## 2. 07장형 HTML 디자인과 레이아웃

- `MicroBlaze_V_SoC01_41/pages/soc/`의 **07장 페이지 스타일을 우선 준용**한다.
- 다크 컬러 히어로, 제목·부제·주요 설정 배지, 흰 SECTION 카드, 자주색 SECTION 번호, 좌측 세부 목차와 장 이동, 모바일 탐색, 표·코드·그림 확대 링크를 유지한다.
- 장 첫머리에 목적과 입출력 신호의 개략 흐름을 보여준다. 자체 제작 **교육용 개념도**는 박스, 화살표, 핵심 장치 강조와 충분한 글자 크기를 사용한다.
- 중요한 작업은 한 화면/한 SECTION에 최대한 하나씩 설명한다. 그림 아래에는 간결한 해설과 확인값을 붙인다.
- **07장의 27개 SECTION 수를 다른 장에 억지로 맞추지 않는다.** 해당 장의 실제 내용과 실습 흐름에 맞춰 구성한다.
- 코드 전체 복사, 표의 가독성, 모바일 320px의 수평 넘침 방지와 200% 확대 가독성을 보장한다.
- 배포 본문에서 `[ ]`, `[x]` 체크박스 표기를 제거한다. 제작 과정 메모, 오류 사례를 성공 사례처럼 보이는 표현, 반복 안내문을 싣지 않는다.

## 3. 공식 원본 그림 — 07장에서 확정된 핵심 원칙

1. AMD PG/UG 및 Digilent 공식 문서에서 해당 장에 **교육적 가치가 있는 원본 그림·회로도·레지스터 도표·타이밍도·GUI 화면을 충분히** 선택한다. 불필요한 그림까지 무조건 복제하지 않는다.
2. 공식 도판은 새로 그리거나 블록·화살표·신호·원본 문구를 임의로 변경하지 않는다. 한글 해설은 **그림 아래**에 별도로 작성한다.
3. 그림마다 **공식 문서명 + Figure/Table 번호 + PDF 페이지 + 공식 원문 링크**를 표기한다.
4. 배포·인용 조건을 먼저 확인한다. 허용되는 범위에서 공식 원본 PDF의 해당 도판을 충분한 해상도로 추출하고, `images/socNN/` 아래 **로컬 PNG 등**으로 저장한다.
5. **외부 이미지 핫링크와 PDF iframe/object 임베드에 의존하지 않는다.** 07장에서는 이 때문에 온라인 그림이 표시되지 않아 로컬 이미지 파일 방식으로 바로잡았다.
6. 이미지가 너무 작거나 잘리지 않았는지 원본 PDF와 **눈으로 대조**한다. 도판의 캡션·상단 신호 라벨·아래 비트 필드·화살표가 누락되지 않도록 한다.
7. **‘원본 그림 크게 보기’는 저장된 원본 그림 파일**, **‘공식 원문’은 공식 문서 PDF 페이지**로 연결한다. 실제로 사용한 아카이브 PDF와 공식 배포본이 다른 버전이면 출처 차이를 기록한다.
8. 원본 그림의 소스 문서·추출 파일의 체크섬(SHA-256)을 `manifest.json` 등으로 기록하고, 그림 링크·파일 무결성과 브라우저 로딩을 검증한다.
9. 과거 공식 GUI 화면에 있는 **예시값을 실습값으로 오인하지 않도록 주의**한다. 예: PG142 원본 GUI의 9600 baud는 07장의 실제 설정 115200 baud와 다르므로 명확히 구분한다.
10. 공식 원본 그림 / 자체 제작 이해용 그림 / 사용자가 제공한 실제 GUI 성공 화면을 서로 명시적으로 구분한다.

## 4. Vivado·Vitis GUI 실습

### 모든 장 시작 시 기존 프로젝트 인계 순서를 표시한다

- 첫 SECTION에 **출발 원본 `.xpr` → 새 프로젝트 `.xpr` → Design Sources의 기존 `.bd` → 새 `.bd` → 새 HDL Wrapper / Set as Top → 기존 Wrapper Remove from Project → IP Status → 신규 IP 추가** 흐름을 명시한다.
- 실제 GUI 캡처가 이미 있으면 당시의 성공 화면과 작업 순서로 교재를 복원한다. **사용자에게 같은 지시나 캡처를 반복 요청하지 않는다.**
- `File → Project → Save As`는 프로젝트 복제이고, **`File → Save Block Design As`와 `Create HDL Wrapper`는 별도의 단계**다. 프로젝트명만 바뀌었다고 Design Sources까지 정리됐다고 쓰지 않는다.
- 원래 Wrapper는 **Remove File from Project**로만 정리하고 **Delete files from disk**는 선택하지 않는다. 공유 XDC·Block Design 파일 경로도 확인하여 이전 장 원본을 수정하지 않는다.
- 예시: 06장은 `soc01_microblaze_bram.xpr` → `soc06_axi_gpio.xpr`, `soc01_mb_bram.bd` → `soc06_axi_gpio.bd`, `soc06_axi_gpio_wrapper` 생성 후 Top 지정, 기존 IP 9개 Up-to-date 확인, 다음에 AXI GPIO를 추가했다.
- 07장은 성공한 `soc06_axi_gpio.xpr`에서 출발해 별도 `soc07_axi_uartlite.xpr`, `soc07_axi_uartlite.bd`, `soc07_axi_uartlite_wrapper`를 준비하는 순서로 안내한다. 해당 장에서 실제 검증하기 전까지 예정 절차를 성공 기록으로 표시하지 않는다.

- 검증된 성공 프로젝트의 HW/SW 프로젝트, XSA·ELF·코드를 임의로 삭제·이동하거나 덮어쓰지 않는다.
- 이전 장과 연결되는 실습은 성공 Block Design·Clock·Reset·BRAM·AXI 설정을 보존한다. 회로 구성이 바뀌면 `/home/jung/soc/hw/socNN_...`으로 새 프로젝트를 만들어 분리하고, 이전 프로젝트 소스를 참조하여 함께 수정하는 위험이 없는지 점검한다.
- IP 이름, 실제 핀·포트, AXI 클록·리셋, Address Editor 주소, XDC, wrapper, `xparameters.h`를 실제 GUI에서 확인한 값으로 적는다. **예시 주소나 포트 이름을 실측 성공값처럼 확정하지 않는다.**
- 사용자가 보내는 스크린샷을 시간순으로 비교하고 **성공/정상**, **중간·미검증**, **오류/실패**로 분류한다. 최종 배포에는 검증된 정상 화면을 우선한다.
- Vivado/Vitis 절차는 사용자의 **현재 화면 확인 후 다음 한 단계**만 안내한다. 이미 검증한 쉬운 작업은 불필요하게 세분화하지 않는다.
- 최종 스크린샷은 **시간순으로 묶어 ZIP 파일**로 제공한다. 오류 화면, 중복 이미지, 미검증 화면은 성공 증거용 ZIP에서 제외한다.

## 5. 코드 및 테스트벤치

- 첫 C 프로그램은 코드 **전문**과 주석을 포함하며, 헤더·드라이버 함수·변수·레지스터 주소와 실행 결과를 직관적으로 연결해 해설한다. 다음 장에서는 동일 설명을 과도하게 반복하지 않는다.
- 공식 제공 코드 / 사용자가 작성한 코드 / 교재용 직접 작성 코드를 반드시 구별한다.
- RTL·테스트벤치의 기본 언어는 **Verilog**이며 실제 모듈·Port·Signal·Parameter 명칭과 블록도 명칭을 일치시킨다.
- 공식 테스트벤치가 VHDL(`*.vhd`)로만 제공되면 **동작과 검증 목적을 분석해 Verilog(`*.v`)로 구현**한다. 문장별 번역이 아니라면 ‘1:1 변환’이라고 표시하지 않고 **공식 테스트 기능의 Verilog 재구현**으로 표시한다.
- 가능한 Verilog 테스트벤치는 Clock·Reset·입력 자극·자동 PASS/FAIL·타임아웃·파형·기대값 비교를 포함하며, UART 송수신과 AXI VALID/READY 등 장에 필요한 신호를 검증한다.
- **Stub 모델만 붙여 수행한 문법 검사 ≠ 실제 AMD IP XSim 시뮬레이션 검증**이다. 원본 IP를 직접 구동한 Run Behavioral Simulation 로그·파형을 따로 확인한다.
- 소프트웨어 Debug WATCH, 터미널 출력 및 FPGA LED 동작은 모두 **실제 보드 확인이 있을 때만** 성공 결과로 적는다.
- 정상 동작하는 코드에 대한 선택적 개선은 필수 수정과 분리하고 사용자가 결정할 수 있도록 한다.

## 6. UART PC 터미널: moserial 사용

- Ubuntu PC↔FPGA 시리얼 실습의 표준은 GUI 도구 **moserial(모시리얼)**이다. 후속 실습에서 minicom 절차를 재사용하지 않는다.
- 먼저 `ls -l /dev/serial/by-id/`로 실제 장치와 `/dev/ttyUSB*` 경로를 확인한다. USB 장치 번호를 특정 값으로 확정하지 않는다.
- **07장 설정:** 115200, 8 Data Bits, No Parity, 1 Stop Bit, Handshake None, Echo received data Off.
- 진행: FPGA Program → moserial 실제 Port 선택 및 Connect → Vitis ELF 실행 → **Received ASCII**에서 시작 메시지 확인 → **Outgoing / ASCII / No end / Send** → **Sent ASCII / Received ASCII** 비교.
- moserial의 Sent ASCII는 PC가 보낸 문자 표시이며, Received ASCII는 FPGA에서 실제 받은 문자 표시이다. 둘을 혼동하지 않는다.
- 설정값은 후속 장의 하드웨어 특성에 따라 달라질 수 있으므로 장별 실제 설정을 우선한다.

## 7. 적대적 검증 절차

| 단계 | 검증 항목 | 성공 판정 |
| --- | --- | --- |
| 공식 근거 | Figure/Table, CPU/IP 지원 범위, Clock, Reset, 주소, 핀, 문서 개정판 | 근거와 본문 일치 |
| 이미지 | 원본 도판 화질·잘림·캡션, 상대 경로, 확대 및 공식 PDF 링크 | 직접 이미지 확인 |
| 웹 UI | HTML 구조, 장·절 목차, 1440/1024/390/320px, 200% 확대 | 이미지 로딩·수평 넘침·탐색 정상 |
| 코드 정적 | Verilog 문법, C 헤더·매크로, Port, 파라미터, 함수 | **정적 검사 한정 PASS** |
| RTL/IP 시뮬레이션 | 실제 IP/RTL + 테스트벤치 + 자동 판정 | 파형·로그의 실제 PASS |
| Vivado | Block Design, Address Editor, Bitstream, XSA | 실제 타깃 프로젝트 성공 |
| Vitis/보드 | Platform, ELF Build, Debug, 실제 Basys3 I/O | 보드·터미널 실측 확인 |
| 배포 | GitHub 커밋, GitHub Pages 온라인 화면·이미지·원문 링크 | 브라우저 직접 확인 |

- **문서 완료 / 정적 검사 완료 / 실제 시뮬레이션 완료 / Vivado 빌드 완료 / Basys3 실기 검증 완료 / GitHub 게시 완료**를 각각 따로 기록한다.
- 시뮬레이션 실패를 숨기지 않고 실패 원인과 수정 후 같은 조건에서 재검사한 결과를 확인한다.
- 정적 검사 PASS, CI 통과, 예상 출력 문자열만으로 FPGA 실기 검증 성공이라고 쓰지 않는다.
- 검증 중 잘못된 스크린샷·원본 도판 잘림·코드 오류가 나오면 먼저 수정하고 재검증한다.
- `validation/SOCNN_VALIDATION.txt`에 테스트 방법, PASS/FAIL, 미수행 범위, 근거를 누적한다. 배포용 본문에는 과도한 제작 메모를 노출하지 않는다.

## 8. 장별 작업·산출물 표준

```text
MicroBlaze_V_SoC01_41/
├── pages/soc/NN_<chapter>.html  # 07장형 배포 HTML · 좌측 목차
├── docs/socNN.md               # 동기화된 Markdown
├── images/socNN/               # 공식 원본 도판 · 검증된 GUI 스크린샷
├── code/socNN/                 # C / Verilog / XDC / testbench
├── packages/                   # 시간순 검증 스크린샷 ZIP 등
└── validation/SOCNN_VALIDATION.txt
```

1. **기존 HTML·앞 장·다음 장·공식 원본 문서 분석**
2. **장별 학습 범위와 기존 프로젝트 보존·복제 방식 결정**
3. **필요한 공식 원본 도판 확보와 출처·추출 상태 검증**
4. **사용자가 제공하는 Vivado/Vitis GUI를 실제로 따라 하며 단계별 검증**
5. **코드·Verilog 테스트벤치·타깃 빌드·실제 FPGA 검증**
6. **정상 자료만 골라 HTML·Markdown 보완**
7. **적대적 문서/이미지/코드/브라우저 검증과 결과 기록**
8. **GitHub 게시 후 Pages 온라인 페이지 재확인**
9. **시간순 실습 스크린샷 ZIP 저장 및 다음 장 진행**

> **07장의 현재 상태:** 공식 원본 도판 10개 로컬 삽입, 브라우저·정적 문법 검사, moserial 절차 문서화까지는 성공하였다. **Vivado 2024.2 실제 AXI UART Lite XSim과 Basys3↔moserial Echo 실측은 미검증**이다. 후속 장을 작성할 때 이 차이를 엄격히 유지한다.
