# Custom Processing AXI4-Lite IP Packaging Source

## 1. 목적

SoC 12~15에서 만든 다음 자산을 Vivado Custom IP로 Packaging하기 위한 소스 디렉터리입니다.

- AXI4-Lite Slave Adapter
- Register Bank
- RTL Controller
- Top Wrapper
- Verilog Testbench
- MicroBlaze V Software Driver
- Driver Example / Host Mock Test

## 2. Top Module

`custom_axi4lite_controller_ip`

Top은 Shell/Wrapper 역할만 하며 기능 로직을 포함하지 않습니다.

## 3. 권장 Packaging 방법

Vivado 2026.1 기준:

1. Vivado Project를 엽니다.
2. `Tools > Create and Package New IP`
3. `Package a specified directory`
4. Directory에 이 `custom_processing_ip_1_0` 폴더를 지정합니다.
5. `Package as a library core`는 선택하지 않습니다.
6. Edit IP Packager Project를 엽니다.
7. Identification을 확인합니다.
8. Ports and Interfaces에서 AXI4-Lite `S_AXI`, Clock, Reset을 확인합니다.
9. File Groups를 확인합니다.
10. Software Drivers File Group에 `drivers/custom_processing_v1_0/src`의 파일을 추가합니다.
11. Test Bench File Group에 `testbench/tb_custom_axi4lite_controller_ip.v`를 확인합니다.
12. Review and Package에서 DRC/Warning을 확인하고 Package IP를 실행합니다.

## 4. 권장 Identification

- Vendor: `user.org`
- Library: `user`
- Name: `custom_processing_ip`
- Version: `1.0`
- Display Name: `Custom Processing AXI4-Lite IP`
- Taxonomy: `/UserIP`

Vendor 값은 실제 배포 조직에 맞게 변경할 수 있습니다.

## 5. Ports and Interfaces 확인

Top Port는 다음 이름 규칙을 사용합니다.

- `s_axi_aclk`
- `s_axi_aresetn`
- `s_axi_awaddr`
- `s_axi_awvalid`
- `s_axi_awready`
- `s_axi_wdata`
- `s_axi_wstrb`
- `s_axi_wvalid`
- `s_axi_wready`
- `s_axi_bresp`
- `s_axi_bvalid`
- `s_axi_bready`
- `s_axi_araddr`
- `s_axi_arvalid`
- `s_axi_arready`
- `s_axi_rdata`
- `s_axi_rresp`
- `s_axi_rvalid`
- `s_axi_rready`

AXI interface가 `S_AXI` 또는 동등한 Slave AXI4-Lite Interface로 추론되는지 확인합니다.

Clock Interface:
- Port: `s_axi_aclk`
- Associated Bus Interface: `S_AXI`
- Associated Reset: `s_axi_aresetn`

Reset Interface:
- Port: `s_axi_aresetn`
- Polarity: Active-Low

## 6. File Group 기준

### Synthesis

`hdl/`

### Test Bench

`testbench/tb_custom_axi4lite_controller_ip.v`

### Software Drivers

`drivers/custom_processing_v1_0/src/`

- `custom_driver.c`
- `custom_driver.h`
- `custom_regmap.h`

### Examples

`examples/`

- `custom_driver_example.c`
- `test_custom_driver_mock.c`

### Documentation

`doc/`

## 7. 중요한 제한

`component.xml`과 `xgui/*.tcl`은 Vivado IP Packager가 생성하는 산출물입니다.

이 Source Package에는 수동으로 만든 `component.xml`을 넣지 않습니다.

Software Drivers File Group에 C/H 파일을 포함하는 것과
Vitis BSP에서 Driver가 자동 선택되고 Config Table이 자동 생성되는 것은 별개의 문제입니다.
이번 단계에서는 Driver를 IP와 함께 배포 가능한 자산으로 Packaging하는 것까지 다룹니다.

## 8. IP Catalog 등록

Packaging 완료 후 새 Project에서:

```tcl
set_property IP_REPO_PATHS {/absolute/path/to/ip_repo} [current_fileset]
update_ip_catalog -rebuild
```

그 다음 IP Catalog에서 `Custom Processing AXI4-Lite IP`를 검색합니다.

## 9. 재사용 검증

새 Vivado Project에서 다음을 확인합니다.

1. IP Catalog에서 Custom IP 검색
2. Block Design에 IP 추가
3. `S_AXI`를 MicroBlaze V SmartConnect에 연결
4. `s_axi_aclk`, `s_axi_aresetn` 연결
5. Address Editor에서 Base Address 할당
6. Validate Design
7. Synthesis
8. XSA Export
9. Vitis에서 실제 Base Address를 Driver `CustomDrv_Initialize()`에 전달
10. `CustomDrv_SelfTest()`와 `CustomDrv_RunBlocking()` 확인
