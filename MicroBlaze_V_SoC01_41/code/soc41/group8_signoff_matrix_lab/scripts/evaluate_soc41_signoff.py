#!/usr/bin/env python3
import json
import math
import sys
from pathlib import Path


def missing(section: dict, keys: list[str]) -> list[str]:
    return [
        key for key in keys
        if section.get(key) is None or (
            isinstance(section.get(key), str)
            and not section[key].strip()
        )
    ]


def all_true(section: dict, keys: list[str]) -> bool:
    return all(
        section.get(key) is True
        for key in keys
    )


# (추가) bool·NaN·Infinity를 측정 숫자로 승인하지 않는다.
def finite_number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "usage: python3 evaluate_soc41_signoff.py "
            "data/soc41_signoff_input.json"
        )
        return 2

    path = Path(sys.argv[1])
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"Invalid input: {exc}\noverall     : FAIL")
        return 1

    sections = ("design", "functional", "timing", "methodology",
                "resources", "power", "runtime")
    if not isinstance(data, dict) or any(
        not isinstance(data.get(key), dict) for key in sections
    ):
        print("Invalid input sections\noverall     : FAIL")
        return 1

    results = {}

    # (추가) 측정 결과를 실제 도구 버전·Bitstream에 대응시킨다.
    design = data["design"]
    dkeys = ["device", "board", "target_clock_mhz", "vivado_version",
             "vitis_version", "bitstream_id"]
    dm = missing(design, dkeys)
    design_pass = (
        finite_number(design.get("target_clock_mhz"))
        and design["target_clock_mhz"] > 0
        and all(isinstance(design.get(k), str) and design[k].strip()
                for k in dkeys if k != "target_clock_mhz")
    )
    results["design"] = ("INCOMPLETE" if dm else
                         "PASS" if design_pass else "FAIL", dm)

    functional = data["functional"]
    fkeys = [
        "rtl_regression_pass",
        "job0_expected_pass",
        "job1_expected_pass",
        "descriptor_error_irq_pass",
        "done_irq_w1c_pass",
        "job_id_sequence_pass",
    ]

    fm = missing(functional, fkeys)

    if fm:
        results["functional"] = (
            "INCOMPLETE",
            fm,
        )
    else:
        results["functional"] = (
            "PASS" if all_true(functional, fkeys) else "FAIL",
            [],
        )

    timing = data["timing"]
    tkeys = [
        "wns_ns",
        "tns_ns",
        "whs_ns",
        "ths_ns",
        "unconstrained_paths",
        "pulse_width_violations",
        "timing_critical_warnings",
    ]

    tm = missing(timing, tkeys)

    if tm:
        results["timing"] = (
            "INCOMPLETE",
            tm,
        )
    else:
        timing_pass = (
            all(finite_number(timing[k]) for k in tkeys)
            and timing["wns_ns"] >= 0.0
            and timing["tns_ns"] >= 0.0
            and timing["whs_ns"] >= 0.0
            and timing["ths_ns"] >= 0.0
            and timing["unconstrained_paths"] == 0
            and timing["pulse_width_violations"] == 0
            and timing["timing_critical_warnings"] == 0
        )

        results["timing"] = (
            "PASS" if timing_pass else "FAIL",
            [],
        )

    methodology = data["methodology"]
    mkeys = [
        "critical_warnings",
        "drc_errors",
        "cdc_critical",
    ]

    mm = missing(methodology, mkeys)

    if mm:
        results["methodology"] = (
            "INCOMPLETE",
            mm,
        )
    else:
        method_pass = (
            all(type(methodology[k]) is int for k in mkeys)
            and methodology["critical_warnings"] == 0
            and methodology["drc_errors"] == 0
            and methodology["cdc_critical"] == 0
        )

        results["methodology"] = (
            "PASS" if method_pass else "FAIL",
            [],
        )

    resources = data["resources"]
    pairs = [
        ("lut_used", "lut_available"),
        ("ff_used", "ff_available"),
        ("bram_used", "bram_available"),
        ("dsp_used", "dsp_available"),
    ]

    rm = []

    for used, available in pairs:
        if resources.get(used) is None:
            rm.append(used)

        if resources.get(available) is None:
            rm.append(available)

    if rm:
        results["resources"] = (
            "INCOMPLETE",
            rm,
        )
    else:
        resource_pass = all(
            finite_number(resources[used])
            and finite_number(resources[available])
            and 0 <= resources[used] <= resources[available]
            and resources[available] > 0
            for used, available in pairs
        )

        results["resources"] = (
            "PASS" if resource_pass else "FAIL",
            [],
        )

    power = data["power"]
    pkeys = [
        "activity_source",
        "total_on_chip_w",
        "dynamic_w",
        "device_static_w",
        "junction_temp_c",
        "ambient_c",
        "power_budget_w",
        "junction_limit_c",
    ]

    pm = missing(power, pkeys)

    if pm:
        results["power"] = (
            "INCOMPLETE",
            pm,
        )
    else:
        power_pass = (
            isinstance(power["activity_source"], str)
            and all(finite_number(power[k]) for k in pkeys
                if k != "activity_source")
            and all(power[k] >= 0 for k in
                    ("total_on_chip_w", "dynamic_w", "device_static_w"))
            and power["power_budget_w"] > 0
            and power["total_on_chip_w"]
            <= power["power_budget_w"]
            and power["junction_temp_c"]
            <= power["junction_limit_c"]
        )

        results["power"] = (
            "PASS" if power_pass else "FAIL",
            [],
        )

    runtime = data["runtime"]
    rkeys = [
        "measurement_method",
        "repeat_count",
        "start_to_isr_avg_us",
        "full_e2e_avg_us",
        "full_e2e_min_us",
        "full_e2e_max_us",
    ]

    rtm = missing(runtime, rkeys)

    if rtm:
        results["runtime"] = (
            "INCOMPLETE",
            rtm,
        )
    else:
        sane = (
            isinstance(runtime["measurement_method"], str)
            and type(runtime["repeat_count"]) is int
            and runtime["repeat_count"] > 0
            and all(finite_number(runtime[k]) and runtime[k] >= 0
                    for k in rkeys if k not in
                    ("measurement_method", "repeat_count"))
            and runtime["full_e2e_min_us"]
            <= runtime["full_e2e_avg_us"]
            <= runtime["full_e2e_max_us"]
        )

        results["runtime"] = (
            "RECORDED" if sane else "FAIL",
            [],
        )

    print("SoC41 SIGN-OFF EVALUATION")

    for name, (status, missing_keys) in results.items():
        print(
            f"{name:12s}: {status}"
        )

        if missing_keys:
            print(
                "  missing: "
                + ", ".join(missing_keys)
            )

    hard_gates = [
        "design",
        "functional",
        "timing",
        "methodology",
        "resources",
        "power",
    ]

    if any(
        results[key][0] == "FAIL"
        for key in results
    ):
        overall = "FAIL"
    elif any(
        results[key][0] == "INCOMPLETE"
        for key in hard_gates
    ):
        overall = "INCOMPLETE"
    elif results["runtime"][0] == "INCOMPLETE":
        overall = "INCOMPLETE"
    elif results["runtime"][0] == "FAIL":
        overall = "FAIL"
    else:
        overall = "PASS"

    print(f"overall     : {overall}")

    # (변경) 미완료도 Shell/CI에서 성공으로 오인하지 않게 구분한다.
    return {"PASS": 0, "FAIL": 1, "INCOMPLETE": 2}[overall]


if __name__ == "__main__":
    raise SystemExit(main())
