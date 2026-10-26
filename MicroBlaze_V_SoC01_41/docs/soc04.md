# SoC 04 — Local BRAM Memory Map과 주소 기반 읽기·쓰기

## 1. 실습 범위

MicroBlaze V의 **ILMB/DLMB → Local BRAM** 경로를 통해 C 프로그램이 실제 메모리 주소를 확인하고 32비트 데이터를 쓰고 읽는 과정을 검증한다.

- Vivado Address Editor에서 16 KiB BRAM 주소 확인
- Vitis Application `soc04_memory_map` 생성
- Linker Script의 BRAM·Stack·Heap 설정 확인
- `main.c` 작성, Build, ELF 생성
- `launch.json` 설정 확인 후 FPGA Debug
- WATCH에서 배열의 중간·최종값 검증

04장은 **BRAM 실습**이다. AXI 연결과 MMIO 주변장치 레지스터 접근은 여기서 구현하지 않는다.

## 2. 기존 프로젝트 (변경하지 않음)

| 항목 | 경로 또는 이름 |
| --- | --- |
| Vivado Project | `/home/jung/soc/hw/soc01_microblaze_bram/soc01_microblaze_bram.xpr` |
| Block Design | `soc01_mb_bram` |
| Vitis Workspace | `/home/jung/soc/sw` |
| Platform | `soc_01_platform` |
| Processor | `microblaze_riscv_0` |
| Domain | `standalone_microblaze_riscv_0` |
| 03장 Application | `soc03_bram_run` — 유지 |
| 04장 Application | `soc04_memory_map` — 신규 |

## 3. Vivado Address Editor

Block Design에서 Address Editor를 열어 다음 실제 주소를 확인한다.

| 인터페이스 | Base | Range | High |
| --- | --- | --- | --- |
| ILMB — `ilmb_bram_if_cntlr/SLMB` | `0x00000000` | 16 KiB | `0x00003FFF` |
| DLMB — `dlmb_bram_if_cntlr/SLMB` | `0x00000000` | 16 KiB | `0x00003FFF` |

- Assigned: **2**
- Unassigned: **0**
- Incomplete Paths: **1**, `/microblaze_riscv_0/M_AXI_DP`는 미연결. 이번 실습에서 사용하지 않음.
- 계산: Base `0x0` → Range `0x4000` → High `0x3FFF`
- 두 경로는 같은 Local BRAM에 접근하므로 같은 주소 범위를 사용할 수 있다.

## 4. Vitis Application 만들기

1. Vitis 2024.2에서 Workspace `/home/jung/soc/sw` 열기
2. New Application → 이름 `soc04_memory_map`
3. 기존 Platform `soc_01_platform` 선택
4. Domain `standalone_microblaze_riscv_0` 확인
5. Empty Application → Finish
6. `/home/jung/soc/sw/soc04_memory_map/src/main.c` 생성

## 5. main.c — 실제 실습 코드

```c
#include <stdint.h>
#include <stddef.h>

volatile uint32_t bram_word[4] = {0, 0, 0, 0};

volatile uintptr_t addr_0 = 0;
volatile uintptr_t addr_1 = 0;
volatile uintptr_t addr_2 = 0;
volatile uintptr_t addr_3 = 0;

volatile uint32_t read_0 = 0;
volatile uint32_t read_1 = 0;
volatile uint32_t read_2 = 0;
volatile uint32_t read_3 = 0;

volatile uint32_t stage = 0;

int main(void)
{
    addr_0 = (uintptr_t)&bram_word[0];
    addr_1 = (uintptr_t)&bram_word[1];
    addr_2 = (uintptr_t)&bram_word[2];
    addr_3 = (uintptr_t)&bram_word[3];
    stage = 1;

    bram_word[0] = 0x11111111U;
    bram_word[1] = 0x22222222U;
    bram_word[2] = 0x33333333U;
    bram_word[3] = 0x44444444U;
    stage = 2;

    read_0 = bram_word[0];
    read_1 = bram_word[1];
    read_2 = bram_word[2];
    read_3 = bram_word[3];
    stage = 3;

    bram_word[1] = 0xA5A5A5A5U;
    stage = 4;

    read_1 = bram_word[1];
    stage = 5;

    while (1) {}

    return 0;
}
```

`volatile`은 해당 변수를 통한 메모리 접근이 최적화로 임의 제거되지 않도록 하는 데 중요하다. `uintptr_t`는 포인터 주소를 정수값으로 보관한다. 배열의 실제 시작 주소는 Linker가 결정하므로 고정하지 않는다.

## 6. Linker Script와 Build

`lscript.ld`의 실제 확인 설정:

| 항목 | 확인값 |
| --- | --- |
| Memory Region | `lmb_bram_0` |
| Base / Size | `0x00000000 / 0x00004000` |
| Stack | `0x400` (1 KiB) |
| Heap | `0x800` (2 KiB) |
| 주요 섹션 | `.text`, `.data`, `.bss` → Local BRAM |

Build에서 **Build Finished successfully** 확인.

- ELF: `/home/jung/soc/sw/soc04_memory_map/build/soc04_memory_map.elf`
- GNU Compiler 13.3.0 / `-O2 -march=rv32i_zicsr_zifencei -mabi=ilp32`
- text: **4984 B**, data: **204 B**, bss: **3564 B**
- 이 세 영역 합계: **8752 B** (Heap·Stack 전체 점유량은 미포함)

## 7. launch.json과 Debug

1. 중앙 상단의 **`launch.json` 탭을 직접 클릭해 연다.** Explorer 항목 선택과 구분한다.
2. Launch Config: `soc04_memory_map_app_hw_1`
3. Target Connection: `Local [default]`
4. Target Setup Mode: `Baremetal Debug`
5. Bitstream: `${workspaceFolder}/soc04_memory_map/_ide/bitstream/soc01_mb_bram_wrapper.bit`
6. Application: `${workspaceFolder}/soc04_memory_map/build/soc04_memory_map.elf`
7. Reset Entire System, Program Device, Reset Processor 설정 확인
8. `main()`에 Breakpoint 후 Debug 실행
9. `RISC-V → Hart #0 PAUSED ON BREAKPOINT` 확인

실습 환경에서는 `launch.json` 탭을 연 뒤 Debug 실행이 성공했다. 탭을 열지 않은 경우의 오류 원인은 확인되지 않았으므로 임의로 특정하지 않는다.

## 8. WATCH 검증

WATCH에 `stage`, `addr_0`, `bram_word`, `read_1`을 추가하고 `bram_word`를 펼친다. 과거 03장 변수의 N/A 표시는 해당 변수가 04장에 없기 때문이다.

| 변수 | 중간 `stage=2` | 최종 `stage=5` |
| --- | --- | --- |
| `stage` | `0x00000002` | `0x00000005` |
| `addr_0` | `0x00001460` | `0x00001460` |
| `bram_word[0]` | `0x11111111` | `0x11111111` |
| `bram_word[1]` | `0x22222222` | **`0xA5A5A5A5`** |
| `bram_word[2]` | `0x33333333` | `0x33333333` |
| `bram_word[3]` | `0x44444444` | `0x44444444` |
| `read_1` | `0x22222222` | **`0xA5A5A5A5`** |

최종 WATCH에서 `stage = 5`와 C 소스의 `while(1)` 구간을 확인했다.

`uint32_t` 배열의 주소 간격은 4바이트이다. `addr_0` 실측 `0x00001460`을 기준으로 `bram_word[1]`의 주소는 **`0x00001464`로 계산**되며, 이는 WATCH에서 직접 측정한 개별 주소가 아닌 산출값이다.

## 9. 오류 점검

| 증상 | 확인 사항 |
| --- | --- |
| `M_AXI_DP` Incomplete Paths 1 | 이번 장에서 미사용하는 AXI 경로임 |
| Build 실패 | `main.c`의 C 문법, `lscript.ld` 메모리 배치 |
| Debug 진입 문제 | 중앙 상단 `launch.json` 탭, Bitstream·ELF·Reset 설정 |
| WATCH N/A | 다른 장의 변수 대신 현재 `main.c`의 변수 등록 |
| 중간 단계가 예상보다 작음 | Breakpoint는 해당 대입문 실행 직전에 멈출 수 있음 |
| 배열 주소가 다름 | Linker가 달리 배치했을 수 있으므로 실제 주소 범위를 확인 |

## 10. 최종 결과와 다음 장

**04장 완료: Vivado 16 KiB BRAM 주소 확인 → Vitis Build 성공 → FPGA Debug → 실제 주소 관찰 → BRAM 재기록·재읽기 성공.**

다음 장인 **05장 AXI4 / AXI4-Lite / AXI4-Stream 구조**에서는 AXI 전송 구조를 다룬다. AXI GPIO의 실제 주변장치 제어는 **06장**에서 다룬다.

전체 HTML: [SoC 04 교재](../pages/soc/04_memory_map_memory_mapped_io.html)
