"""Check factorial results, exact output bytes and exit status; retain evidence."""

import argparse
import math
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", choices=("baseline", "sysy-host", "sysy-riscv", "sysy"))
    parser.add_argument("--build", type=Path, default=Path("build"))
    parser.add_argument("--qemu", default="qemu-riscv64")
    args = parser.parse_args()
    build = args.build.resolve()
    programs = []
    if args.suite == "baseline":
        programs = [
            ("C", [str(build / "factorial_c")]),
            ("IR", [str(build / "factorial_ir")]),
            ("ASM-RV", [args.qemu, str(build / "factorial_riscv64")]),
        ]
    if args.suite in ("sysy", "sysy-host"):
        programs.extend([
            ("C-host", [str(build / "sysy/factorial_c_host")]),
            ("IR-host", [str(build / "sysy/factorial_ir_host")]),
        ])
    if args.suite in ("sysy", "sysy-riscv"):
        programs.extend([
            ("C-RV", [args.qemu, str(build / "sysy/factorial_c_riscv")]),
            ("IR-RV", [args.qemu, str(build / "sysy/factorial_ir_riscv")]),
            ("ASM-RV", [args.qemu, str(build / "sysy/factorial_asm_riscv")]),
        ])

    cases = [(f"n{n}", f"{n}\n".encode(), math.factorial(n)) for n in range(13)]
    if args.suite != "baseline":
        cases.extend([("whitespace", b" \t5\n", 120), ("plus-sign", b"+5\n", 120)])
    evidence = build / "test-results" / args.suite
    evidence.mkdir(parents=True, exist_ok=True)
    failures = 0
    total = 0
    with (evidence / "results.tsv").open("w", encoding="utf-8") as summary:
        summary.write("case\tprogram\texpected_bytes\tactual_bytes\texit_code\tstatus\n")
        for case, data, value in cases:
            expected = str(value).encode() + (b"\n" if args.suite == "baseline" else b"")
            for name, command in programs:
                total += 1
                prefix = evidence / f"{case}-{name}"
                prefix.with_suffix(".stdin").write_bytes(data)
                try:
                    result = subprocess.run(command, input=data, capture_output=True, timeout=5)
                    stdout, stderr, code = result.stdout, result.stderr, str(result.returncode)
                    ok = result.returncode == 0 and stdout == expected
                except subprocess.TimeoutExpired as error:
                    stdout, stderr, code = error.stdout or b"", error.stderr or b"", "TIMEOUT"
                    ok = False
                except OSError as error:
                    stdout, stderr, code = b"", str(error).encode(), "EXEC_ERROR"
                    ok = False
                prefix.with_suffix(".stdout").write_bytes(stdout)
                prefix.with_suffix(".stderr").write_bytes(stderr)
                status = "PASS" if ok else "FAIL"
                summary.write(f"{case}\t{name}\t{expected!r}\t{stdout!r}\t{code}\t{status}\n")
                if not ok:
                    failures += 1
                    print(f"FAIL {case}/{name}: exit={code} expected={expected!r} actual={stdout!r}")
                    print(f"  stderr: {stderr[:1000]!r}")
    print(f"{args.suite}: {total - failures}/{total} PASS; evidence: {evidence}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
