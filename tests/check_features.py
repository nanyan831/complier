"""Check the feature program against independently calculated expected values."""

import argparse
from pathlib import Path
import subprocess
import sys


def transform(value):
    base = (value + 3) * 2 - value // 2
    return base + 7 if value % 2 == 0 else base - 5


def expected(values):
    total = 0
    for index, value in enumerate(values):
        if value == -99 and index > 0:
            break
        total += transform(value) if 0 < value < 20 else 1
    return total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, default=Path("build"))
    parser.add_argument("--qemu", default="qemu-riscv64")
    parser.add_argument("--suite", choices=("features", "options"), default="features")
    args = parser.parse_args()
    directory = args.build.resolve() / "sysy"
    programs = [
        ("C-host", [str(directory / "features_c_host")]),
        ("IR-host", [str(directory / "features_ir_host")]),
        ("C-RV", [args.qemu, str(directory / "features_c_riscv")]),
        ("IR-RV", [args.qemu, str(directory / "features_ir_riscv")]),
        ("ASM-RV", [args.qemu, str(directory / "features_asm_riscv")]),
    ]
    if args.suite == "options":
        programs = [
            ("C-host-O2", [str(directory / "features_c_host_O2")]),
            ("C-host-g", [str(directory / "features_c_host_g")]),
            ("IR-host-O2", [str(directory / "features_ir_host_O2")]),
            ("C-RV-O2", [args.qemu, str(directory / "features_c_riscv_O2")]),
            ("IR-RV-O2", [args.qemu, str(directory / "features_ir_riscv_O2")]),
        ]
    cases = [
        (0, 0, 0),
        (2, 3, 4),
        (0, 20, -3),
        (19, 1, 18),
        (7, 7, 7),
        (1, 2, 19),
        (20, 21, 22),
        (-1, 0, 1),
        (2, -99),
        (2, 3, -99),
        (-99, 2, 3),
        (-2147483648, 2147483647, 19),
        (-1, 2, -99),
    ]
    evidence = args.build.resolve() / "test-results" / args.suite
    evidence.mkdir(parents=True, exist_ok=True)
    failures = 0
    with (evidence / "results.tsv").open("w", encoding="utf-8") as summary:
        summary.write("case\tprogram\texpected\tactual\texit_code\tstatus\n")
        for index, values in enumerate(cases):
            input_bytes = (" ".join(map(str, values)) + "\n").encode()
            output_bytes = str(expected(values)).encode()
            for name, command in programs:
                prefix = evidence / f"case{index}-{name}"
                prefix.with_suffix(".stdin").write_bytes(input_bytes)
                try:
                    result = subprocess.run(command, input=input_bytes, capture_output=True, timeout=5)
                    actual, stderr, code = result.stdout, result.stderr, str(result.returncode)
                    ok = result.returncode == 0 and actual == output_bytes
                except subprocess.TimeoutExpired as error:
                    actual, stderr, code = error.stdout or b"", error.stderr or b"", "TIMEOUT"
                    ok = False
                except OSError as error:
                    actual, stderr, code = b"", str(error).encode(), "EXEC_ERROR"
                    ok = False
                prefix.with_suffix(".stdout").write_bytes(actual)
                prefix.with_suffix(".stderr").write_bytes(stderr)
                status = "PASS" if ok else "FAIL"
                summary.write(f"{index}\t{name}\t{output_bytes!r}\t{actual!r}\t{code}\t{status}\n")
                if not ok:
                    failures += 1
                    print(f"FAIL case{index}/{name}: exit={code}, expected={output_bytes!r}, actual={actual!r}")
                    print(f"  stderr: {stderr[:1000]!r}")
    total = len(cases) * len(programs)
    print(f"{args.suite}: {total - failures}/{total} PASS; evidence: {evidence}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
