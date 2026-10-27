# 07장 실제 GUI 캡처 기록

## 최종 교재 포함

| 순서 | 연계 절 | 제목 | 판정 |
|---:|---|---|---|
| 01 | `s01` | 06장 성공 Vivado 프로젝트 열기 | procedure |
| 02 | `s01` | Save Project As — 07장 프로젝트 분리 | procedure |
| 03 | `s01` | Save Block Design As — 07장 BD 분리 | procedure |
| 04 | `s03` | AXI UART Lite 100 MHz · 115200 · 8N1 설정 | procedure |
| 05 | `s04` | Run Connection Automation — S_AXI만 선택 | procedure |
| 06 | `s04` | AXI SmartConnect의 두 출력과 UART 연결 확인 | procedure |
| 07 | `s05` | UART_0 외부 인터페이스 생성 | procedure |
| 08 | `s06` | Let Vivado manage wrapper and auto-update 선택 | procedure |
| 09 | `s06` | 자동 생성 모듈의 실제 UART_0_rxd · UART_0_txd 확인 | procedure |
| 10 | `s07` | 정정된 UART 포트명과 B18/A18 핀 제약 | verified |
| 11 | `s08` | 주소 할당 — GPIO 0x40000000 / UART 0x40600000 | verified |
| 12 | `s09` | Generate Bitstream 실행 설정 | procedure |
| 13 | `s09` | Bitstream Generation successfully completed | success |
| 14 | `s09` | 실제 타이밍 성공 WNS +0.817 ns | success |
| 15 | `s09` | Vivado 추정 소비전력 0.196 W (Low Confidence) | estimate |
| 16 | `s09` | Export Hardware — Include bitstream | procedure |
| 17 | `s09` | 07장 XSA 파일명과 저장 위치 확인 | procedure |
| 18 | `s09` | XSA 내보내기 Finish 확인 | procedure |
| 19 | `s10` | Vitis Platform soc07_axi_uartlite_platform 생성 | procedure |
| 20 | `s10` | 생성된 soc07_axi_uartlite.xsa 파일 선택 | verified |
| 21 | `s10` | Vitis Hardware Design(XSA) 경로 확인 | procedure |
| 22 | `s10` | standalone 및 microblaze_riscv_0 선택 | procedure |
| 23 | `s10` | Vitis Platform 생성 요약 | procedure |
| 24 | `s11` | Echo Application 이름 soc07_axi_uartlite | procedure |
| 25 | `s11` | 07장 전용 Platform 선택 | procedure |
| 26 | `s11` | standalone_microblaze_riscv_0 Domain 선택 | procedure |
| 27 | `s11` | Application 생성 시 Source Files 단계 | procedure |
| 28 | `s11` | Application 생성 요약 | procedure |
| 29 | `s13` | 재부팅 없이 clangd Language Server 재시작 메뉴 | procedure |
| 30 | `s13` | 실제 BSP xparameters.h에 UART 주소 매크로 생성 | verified |
| 31 | `s13` | FPGA configuration complete 로그 | success |
| 32 | `s13` | launch.json에서 Bitstream·ELF·CPU 실행 설정 확인 | verified |
| 33 | `s13` | MicroBlaze V Hart #0 Debug 진입 — 53행 일시정지 | verified |
| 34 | `s15` | moserial Received ASCII에 abc Echo 반환 | success |

## 배포에서 제외한 캡처

| 시각 | 제외 근거 |
|---|---|
| 123017 | UART 외부화 이전 중간 배선 화면 — 최종 그림으로 사용하지 않음 |
| 122724 | UART 추가 이전 06장 기준 블록도 — 07장 최종 사례 아님 |
| 123445 | Wrapper 변경 중간 화면 — 최종 상태 캡처와 중복 |
| 123557 | Vivado BD 구버전 참조 경고 출력 — 교재 성공 사례에서 제외 |
| 123936 | 수정 전 XDC 및 경고가 보이는 화면 — UART 포트명 미일치 |
| 124341 | BD/IP 선택 중인 중간 화면 — 최종 화면과 중복 |
| 124741 | Bitstream Generation failed — 실패 화면 |
| 131110 | 헤더 인식 빨간 밑줄(14개 문제) — 정상 완료 화면 아님 |
| 135023 | Program Device 화면의 ELF 선택이 비어 있음 — 프로그램 실행 성공 근거 아님 |
| 141332 | TX 안내문만 확인된 moserial 중간 화면 — Echo 최종 성공으로 대체 |
| 141341 | 54행 정지 중간 화면 — Echo 실행 완료 화면 아님 |

원본 이미지는 originals에 보존했고, 교재 배포용은 WebP로 변환했습니다. 
실제 작업 중 발생한 오류 또는 잘못된 포트명은 최종 성공 사례로 취급하지 않습니다.
실제 Success 판정은 Bitstream 생성, 타이밍 보고서, FPGA 다운로드, moserial Echo에 한정합니다.
전력 보고서는 추정치이며 Confidence Level Low입니다.