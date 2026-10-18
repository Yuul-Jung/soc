# Legacy Processing AXI4-Lite IP

## 목적

기존 독립 Verilog RTL을 수정하지 않고 AXI4-Lite Custom IP로 변환하는 예제입니다.

핵심 구조:

`legacy_processing_core`
→ `legacy_core_controller_adapter`
→ `custom_axi4lite_ip`
→ `custom_axi4lite_legacy_ip`

## 원칙

- 기존 정상 RTL은 가능한 한 수정하지 않습니다.
- Bus/Software 의미 변환은 Adapter에 둡니다.
- AXI Protocol은 기존 `axi4lite_slave_adapter`를 재사용합니다.
- Register Map은 기존 `custom_register_bank`를 재사용합니다.
- Top Wrapper에는 기능 로직을 넣지 않습니다.
- Software Driver는 Register Contract가 동일하므로 SoC 15 Driver를 그대로 재사용합니다.

## Packaging Top

`custom_axi4lite_legacy_ip`

## Identification 예

- Vendor: `user.org`
- Library: `user`
- Name: `legacy_processing_ip`
- Version: `1.0`
- Display Name: `Legacy Processing AXI4-Lite IP`
- Taxonomy: `/UserIP`

## 검증 순서

1. 원본 `legacy_processing_core` 단독 검증
2. Adapter 연결 검증
3. AXI Register 경로 통합 검증
4. Software Driver Regression
5. Vivado Packaging
6. 새 Project IP Catalog 재사용

## 중요한 점

`component.xml`과 `xgui`는 실제 Vivado IP Packager가 생성합니다.
이 Source Package에는 수동 생성하지 않습니다.
