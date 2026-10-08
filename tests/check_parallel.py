"""Verify GCC automatic loop parallelization, including actual thread creation."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, default=Path("build"))
    parser.add_argument("--cc", default="gcc")
    args = parser.parse_args()
    evidence = args.build.resolve() / "test-results/parallel"
    evidence.mkdir(parents=True, exist_ok=True)
    checks = []
    commands = []

    def check(name, value):
        checks.append({"name": name, "passed": bool(value)})
        if not value:
            print(f"FAIL {name}")

    def run(name, command):
        env = {**os.environ, "LC_ALL": "C", "OMP_DYNAMIC": "FALSE",
               "OMP_THREAD_LIMIT": "4", "OMP_NUM_THREADS": "4"}
        try:
            result = subprocess.run(command, capture_output=True, timeout=30, env=env)
            stdout, stderr, code = result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired as error:
            stdout, stderr, code = error.stdout or b"", error.stderr or b"", "TIMEOUT"
        except OSError as error:
            stdout, stderr, code = b"", str(error).encode(), "EXEC_ERROR"
        (evidence / f"{name}.stdout").write_bytes(stdout)
        (evidence / f"{name}.stderr").write_bytes(stderr)
        commands.append({"name": name, "command": list(map(str, command)), "exit_code": code})
        check(f"{name}: exit", code == 0)
        return stdout.decode(errors="replace")

    dump = evidence / "parloops.txt"
    for mode, flags in (("O0", ["-O0"]), ("serial", ["-O2", "-fno-tree-vectorize"]),
                        ("parallel", ["-O2", "-fno-tree-vectorize", "-ftree-parallelize-loops=4",
                                      f"-fdump-tree-parloops-details={dump}"])):
        executable = evidence / mode
        run(f"build-{mode}", [args.cc, *flags, "experiments/parallel.c", "-o", str(executable)])
        for seed in (-100, -3, 0, 7, 100):
            expected = sum((i % 97 + seed) * 3 + 7 for i in range(262144))
            actual = run(f"{mode}-{seed}", [str(executable), str(seed)])
            check(f"{mode}-{seed}: checksum", actual == f"{expected}\n")

    detail = dump.read_text() if dump.exists() else ""
    check("compiler parallelization dump", "SUCCESS: may be parallelized" in detail)
    symbols = run("parallel-symbols", ["nm", "-u", str(evidence / "parallel")])
    check("parallel runtime call generated", "GOMP_parallel" in symbols)
    serial_symbols = run("serial-symbols", ["nm", "-u", str(evidence / "serial")])
    check("serial has no parallel runtime call", "GOMP_parallel" not in serial_symbols)
    disassembly = run("parallel-transform", ["objdump", "-d", "--disassemble=transform",
                                             str(evidence / "parallel")])
    check("selected transform has parallel dispatch", "GOMP_parallel" in disassembly)

    for mode in ("serial", "parallel"):
        trace = evidence / f"{mode}.strace"
        stdout = run(f"trace-{mode}", ["strace", "-f", "-e", "trace=clone,clone3", "-o", str(trace),
                                      str(evidence / mode), "0"])
        check(f"trace-{mode}: checksum", stdout == f"{sum((i % 97) * 3 + 7 for i in range(262144))}\n")
        lines = trace.read_text().splitlines() if trace.exists() else []
        # Count only successful thread creation, not failed clone3 probes.
        created = sum("CLONE_THREAD" in line and re.search(r"= [1-9][0-9]*$", line) is not None
                      for line in lines)
        check(f"{mode}: actual worker threads", created >= 3 if mode == "parallel" else created == 0)

    (evidence / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
    (evidence / "checks.json").write_text(json.dumps(checks, indent=2) + "\n")
    passed = sum(item["passed"] for item in checks)
    print(f"parallel: {passed}/{len(checks)} PASS; evidence: {evidence}")
    return 0 if passed == len(checks) else 1


if __name__ == "__main__":
    sys.exit(main())
