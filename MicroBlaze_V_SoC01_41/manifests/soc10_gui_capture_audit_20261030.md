# SoC 10 GUI 화면 판독 기록 — 2026-10-30

범위: Vivado/Vitis Unified IDE 2024.2, Basys3, 09장 하드웨어 보존 후 10장 Local BRAM 64 KiB 확장. 이 문서는 편집용 증빙 목록이며 학생용 성공 결과를 대신하지 않는다.

| 시간 기반 원본 PNG | SECTION | 실제 화면·판정 | 교재 사용 |
|---|---|---|---|
| `image(20261030-014530).png` | 과거 Vitis 작업 | 10장 App 이름·경로 구성 | 보존만, 신규 64 KiB 플랫폼 성공 사례 아님 |
| `image(20261030-014602).png` | 과거 Vitis 작업 | 09장 Platform 선택 | 보존만 |
| `image(20261030-014616).png` | 과거 Vitis 작업 | soc10_integration App Summary / 09장 Platform | 보존만 |
| `image(20261030-015148).png` | 과거 Vitis 작업 | 09장 BSP xparameters.h / main.c 생성 | 보존만 |
| `image(20261030-024921).png` | 07 | `soc10_integration.xpr`, 프로젝트 경로, part 확인 | 정상 과정 |
| `image(20261030-030049).png` | 07 | Save Block Design As → `soc10_integration`, local to project | 정상 과정 |
| `image(20261030-030103).png` | 07 | 복제 BD · CPU/AXI/INTC 연결 | 정상 과정 |
| `image(20261030-030358).png` | 07 | `soc10_integration_wrapper` Top과 Vivado 12-3647 warning | 중간·경고, 성공 최종 그림으로 배제 |
| `image(20261030-033745).png` | 08 | Initial Address Editor ILMB/DLMB 16K, AXI 네 개 주소 유지 | 변경 전 상태 |
| `image(20261030-033938).png` | 09 | ILMB 64K, DLMB 16K | 중간 상태, 최종 그림으로 배제 |
| `image(20261030-034100).png` | 09 | ILMB/DLMB 모두 Range 64K, High `0x0000_FFFF` | 설정 완료 화면 |
| `image(20261030-034339).png` | 10 | DLMB BRAM_PORT → PORTA, ILMB → PORTB | 내부 회로 구조 확인 |
| `image(20261030-034517).png` | 10 | BMG Basic: BRAM Controller, True Dual Port RAM, No ECC, AUTO | IP 구성 확인 |
| `image(20261030-034711).png` | 11 | Validate Design successful · no errors or critical warnings | 실제 검증 성공 |
| `image(20261030-034855).png` | 11 | 검증 후 회로 화면 | 중복 장면, 우선 제외 |
| `image(20261030-034948).png` | 11 | BMG Summary: 18K 0, 36K 16, 양쪽 1 Clock | *IP 구성/예상 자원*, 실제 구현 보고서 아님 |
| `image(20261030-035256).png` | 10 | AXI SmartConnect, clock, reset, INTC, UART/LED/SW 연결 | 회로 확인 |

## 기술적 판정 구분

- **확인:** 64K/64K 주소 범위, `0x0000_FFFF` High, BMG 16 RAMB36 구성 표시, BD Validate Design 성공
- **아직 확인하지 않음:** Synthesis/Implementation의 자원 사용량, Timing WNS/TNS/WHS/THS 및 Check Timing, Bitstream, 10장 XSA, 새 Platform+Linker 64KiB 적용, 10장 ELF 및 보드 통합 동작
- **변경 제외:** 09장 XPR/XSA/Platform. 10장 C 프로그램 구현은 이미 작성된 `main.c`를 보존한다.
- **교재 절차 수정:** SECTION 11은 Validate Design과 BMG IP Summary까지만, SECTION 12는 Bitstream 이후 실제 Utilization과 Timing Summary, Output Products 수동 실행 단계는 생략

PNG 원본은 수집된 대화 첨부에 보존되어 있으며, 이 Markdown 파일은 증빙 파일 목록과 판독 결과만 기록한다. 해당 PNG가 GitHub에 업로드됐다는 의미가 아니다.

## GitHub Pages 교재에 포함한 실제 캡처 이미지 (원본 PNG에서 변환한 WebP)

정상 실습 과정을 나타내는 아래 10장의 WebP를 `images/soc10/gui_20261030/`에 게시하고 10장 HTML의 SECTION 07~11에 실제 시간순으로 배치했습니다.

| 교재 이미지 | 원본 캡처 | 본문 SECTION |
|---|---|---|
| `01_project_xpr.webp` | 024921 | 07 |
| `02_save_bd_as.webp` | 030049 | 07 |
| `03_bd_connections.webp` | 030103 | 07 |
| `04_address_before.webp` | 033745 | 08 |
| `05_address_64k.webp` | 034100 | 09 |
| `06_local_bram_connections.webp` | 034339 | 10 |
| `07_bram_basic.webp` | 034517 | 10 |
| `08_validate_success.webp` | 034711 | 11 |
| `09_bram_summary.webp` | 034948 | 11 |
| `10_soc10_connections.webp` | 035256 | 11 |

기존의 09장 Vitis Platform 화면, 중간 16K/64K 혼합 화면, Vivado 경고가 나타난 화면은 교재 본문에서 제외했습니다. 10장 Implementation/Timing/Bitstream/보드 검증 성공 화면은 아직 게시되지 않았습니다.
