# SoC 01~10 최종 기술·절차 정합성 검토

## 검토 기준

- 실습 환경: Basys3, Vivado/Vitis Unified IDE 2024.2.
- 원본 프로젝트와 이미 성공한 C/RTL 코드는 함부로 변경하지 않음.
- 공식 AMD PG079(AXI Timer), PG099(AXI INTC), PG142(AXI UART Lite), PG144(AXI GPIO), UG994(Address Editor), UG1400(Vitis), UG906(Timing)과 대조.
- 공식 기능 설명, 교육용 구조도, 실제 FPGA 보드의 실행 결과, 계측되지 않은 추정값을 구분.
- 실습 순서: Vivado Block Design → Validate → Bitstream/Implementation 보고서 → XSA → Vitis Platform → Application/Linker → Build → Program/Debug → 실제 보드 동작.
- HTML과 검증 문서에서 작업자의 개인 홈 디렉터리 및 작업 날짜를 제거; 공통 상단 장 이동 스타일 적용.

## 장별 확인 내용

| 장 | 판정·교정 |
|---|---|
| 01 | 최소 MicroBlaze V + 공유 Local BRAM 16 KiB, 프로젝트·BD 구성 범위 유지. GUI 화면을 추가하지 않음 |
| 02 | Basys3 W5 100 MHz/Reset·Processor System Reset/XDC, -add 옵션 정리와 Bitstream 결과 기준 유지. GUI 추가하지 않음 |
| 03 | Vitis BRAM Application Build·다운로드·Debug 실행 성공. HTML 코드와 원본 파일은 주석 차이만 있는 동일 실행 로직 |
| 04 | Local BRAM 0x00000000~0x00003FFF, WATCH stage=5, bram_word[1]/read_1=0xA5A5A5A5 실제 확인. 본문 인라인 SVG 3개는 설명용이지 GUI 사진이 아님 |
| 05 | AXI4·AXI4-Lite·AXI4-Stream 차이, AXI4-Lite 5채널, VALID/READY, 독립 AW/W 전송 개념 확인. 이론 장으로 유지 |
| 06 | AXI GPIO Ch1 LED 출력 / Ch2 SW 입력, 베이스 0x40000000, 실기 기능 확인. 본문 간결 코드와 저장소의 SDT/Classic 공용 예제는 별도 구현임을 명시 |
| 07 | AXI UART Lite 0x40600000, B18/A18, 115200 8N1, moserial Echo abc 실기 확인 |
| 08 | AXI Timer 0x41C00000, 100 MHz, TLR0 49,999,998, Polling LED0 점멸 및 ELF 검증. PG079 Down-count 공식 (TLRx+2)×Clock Period 대조 |
| 09 | AXI INTC 0x41200000, Timer→INTC→CPU 인터럽트 연결, interrupt_count 증가/LED0 점멸 확인. 선택 레지스터와 설정 관계 명시. 실습 main.c와 09장/09.1장 전체 코드를 동일하게 맞춤 |
| 10 | BRAM ILMB/DLMB 64 KiB, Block RAM Tile 16/50, Timing WNS +1.347 ns/WHS +0.016 ns/WPWS +3.000 ns. 새 XSA/Platform/Linker 0x10000, ELF Build 성공, SW·UART·Timer 통합 보드 실기 확인. Stack/Heap 설명을 Application linker 단계에 배치 |

## 화면·소스 정적 검사

- SoC 01~10 본문과 07.1/08.1/09.1/10.1 코드 해설까지 14개 HTML의 상대 링크와 로컬 이미지 경로 총 514건을 저장소 파일 트리와 대조: 누락 없음.
- 이미지 <img> 159개(보조 해설 포함), SoC 04 인라인 SVG 3개. SoC 08과 09의 AMD 공식 그림은 외부 URL을 사용하며 오류 발생 시 원문 링크로 안내하는 fallback이 있음.
- 모든 본문 SECTION 번호 연속, 중복 HTML ID 없음, 내부 앵커 없음 오류, 주요 HTML 태그 균형 이상 없음.
- 07~10장 프로그램 소스 대조: 07/08/09/10 본문의 전체 main.c와 code/socXX/main.c가 동일. 10.1의 전체 코드도 10장과 동일.
- 03 본문/실습 소스는 주석 표현만 달라 실행 구문 동일. 06장은 교육용 간결 버전과 SDT/Classic 공용 버전을 구별하여 안내.
- 01/02 기초 장은 GUI 이미지 증설 없이 내용·절차만 정비.
- 09/10 검증 문서에 남았던 과거 NOT RUN 판정을 실제 성공 증거로 업데이트했고, 나머지 장도 현재 범위별로 상태를 통일.

## 검증 경계

- SoC 04의 원본 WATCH GUI PNG는 GitHub에 포함되어 있지 않음. 설명용 SVG와 실측값 표를 사용하며 가짜 GUI 이미지는 생성하지 않음.
- 08/09 AMD 원본 이미지는 제3자 제공 서버에 의존하므로 브라우저에서 항상 표시된다고 보장하지 않음. 공식 원문 링크는 유지.
- Vivado Timing Summary에서 사용자 지정 제약 충족을 확인했지만, 전체 Unconstrained Paths 검사·확정까지 주장하지 않음.
- Timer 실제 초 단위 주기와 전력은 별도 계측 결과가 아님. 10장의 Power 0.205 W는 추정치이며 신뢰도 Low.
- 수정된 최신 페이지에 대해 실브라우저의 해상도별 렌더링/이미지 표시를 다시 수행한 것은 아님. GitHub 저장소의 정적 검사 결과와 구분함.
