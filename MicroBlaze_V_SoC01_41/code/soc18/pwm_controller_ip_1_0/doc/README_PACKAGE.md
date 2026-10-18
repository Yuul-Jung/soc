# PWM Controller AXI4-Lite IP

지속 설정형 PWM RTL을 AXI4-Lite IP로 변환합니다.

핵심은 Shadow Register와 UPDATE Pulse입니다.
Software가 PERIOD/DUTY Shadow를 순서대로 쓴 뒤 UPDATE를 실행할 때 Active 설정이 한 번에 바뀝니다.

Packaging Top: `pwm_axi4lite_ip`

권장 VLNV:
- Vendor: user.org
- Library: user
- Name: pwm_controller_ip
- Version: 1.0

Register Map:
- 0x00 CONTROL
- 0x04 PERIOD_SHADOW
- 0x08 DUTY_SHADOW
- 0x0C COMMAND
- 0x10 STATUS
- 0x14 ACTIVE_PERIOD
- 0x18 ACTIVE_DUTY
- 0x1C ID
- 0x20 VERSION

`component.xml`은 Vivado IP Packager가 생성합니다.
