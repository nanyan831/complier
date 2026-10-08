"""Check hand-written multidimensional-array and binary32 implementations."""

import argparse
import json
import math
from pathlib import Path
import random
import struct
import subprocess
import sys


def f32(value):
    return struct.unpack("!f", struct.pack("!f", value))[0]


def float_result(scale, x, y):
    shifted = f32(f32(f32(x) * 1.5) + f32(f32(y) / 2.0))
    changed = f32(-shifted + f32(scale)) if shifted < 0 else f32(shifted - 0.25)
    return f32(changed - 2.0)


def cases():
    rng = random.Random(831)
    matrices = [[0] * 12, [1] * 12, list(range(12)), list(range(-6, 6))]
    matrices += [[int(i == j) for i in range(12)] for j in range(12)]
    matrices += [[rng.randint(-1000, 1000) for _ in range(12)] for _ in range(8)]
    for index, values in enumerate(matrices):
        answer = sum((i + 1) * value for i, value in enumerate(values)) + 12
        yield "arrays", index, " ".join(map(str, values)) + "\n", f"{answer} {values[-1]}\n"

    floats = [(0, 0.0, 0.0), (3, 2.0, 1.0), (7, -2.0, 1.0),
              (-5, -2.0, -1.0), (0, 0.1, 0.2), (2, -0.1, -0.2),
              (1, 1.5, 0.0), (0, -0.0, 0.0), (9, 0.25, -0.75),
              (3, -10000.0, 0.125)]
    floats += [(rng.randint(-20, 20), rng.uniform(-100, 100), rng.uniform(-100, 100))
               for _ in range(20)]
    for index, (scale, x, y) in enumerate(floats):
        # Hex input encodes the exact binary32 operands, including signed zero.
        data = f"{scale} {f32(x).hex()} {f32(y).hex()}\n"
        value = float_result(scale, x, y)
        yield "floating", index, data, (value, math.trunc(value))


def matches(sample, actual, expected):
    if sample == "arrays":
        return actual == expected.encode()
    try:
        floating, integer = actual.decode("ascii").strip().split()
        return (actual.endswith(b"\n") and
                struct.pack("!f", float.fromhex(floating)) == struct.pack("!f", expected[0]) and
                integer == str(expected[1]))
    except (ValueError, UnicodeError, OverflowError):
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, default=Path("build"))
    parser.add_argument("--qemu", default="qemu-riscv64")
    args = parser.parse_args()
    build = args.build.resolve()
    evidence = build / "test-results/advanced"
    evidence.mkdir(parents=True, exist_ok=True)
    rows = []
    routes = ("sy_host", "ir_host", "sy_riscv", "ir_riscv", "asm_riscv", "sy_host_O2")
    for sample, index, data, expected in cases():
        for route in routes:
            name = f"{sample}-{index}-{route}"
            command = [str(build / "sysy" / f"{sample}_{route}")]
            if route.endswith("riscv"):
                command.insert(0, args.qemu)
            (evidence / f"{name}.stdin").write_text(data)
            try:
                result = subprocess.run(command, input=data.encode(), capture_output=True, timeout=5)
                stdout, stderr, code = result.stdout, result.stderr, result.returncode
            except subprocess.TimeoutExpired as error:
                stdout, stderr, code = error.stdout or b"", error.stderr or b"", "TIMEOUT"
            except OSError as error:
                stdout, stderr, code = b"", str(error).encode(), "EXEC_ERROR"
            passed = code == 0 and matches(sample, stdout, expected)
            (evidence / f"{name}.stdout").write_bytes(stdout)
            (evidence / f"{name}.stderr").write_bytes(stderr)
            rows.append({"name": name, "expected": expected, "actual": stdout.decode(errors="replace"),
                         "exit_code": code, "passed": passed})
            if not passed:
                print(f"FAIL {name}: expected={expected!r}, actual={stdout!r}, exit={code}")
    (evidence / "results.json").write_text(json.dumps(rows, indent=2) + "\n")
    passed = sum(row["passed"] for row in rows)
    print(f"advanced: {passed}/{len(rows)} PASS; evidence: {evidence}")
    return 0 if passed == len(rows) else 1


if __name__ == "__main__":
    sys.exit(main())
