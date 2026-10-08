"""Reproduce preprocessing, diagnostics, relocation and debug-info experiments."""

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
    parser.add_argument("--clang", default="clang")
    parser.add_argument("--riscv-objdump", default="riscv64-linux-gnu-objdump")
    parser.add_argument("--riscv-readelf", default="riscv64-linux-gnu-readelf")
    args = parser.parse_args()
    build = args.build.resolve()
    host_library = str(build / "sysy/libsysy_host.a")
    evidence = build / "test-results/compiler"
    evidence.mkdir(parents=True, exist_ok=True)
    records = []
    checks = []

    def check(name, condition):
        checks.append({"name": name, "passed": bool(condition)})
        if not condition:
            print(f"FAIL {name}")

    def run(name, command, expected_code=0):
        try:
            result = subprocess.run(command, capture_output=True, timeout=30,
                                    env={**os.environ, "LC_ALL": "C"})
            stdout, stderr, code = result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired as error:
            stdout, stderr, code = error.stdout or b"", error.stderr or b"", "TIMEOUT"
        except OSError as error:
            stdout, stderr, code = b"", str(error).encode(), "EXEC_ERROR"
        (evidence / f"{name}.stdout").write_bytes(stdout)
        (evidence / f"{name}.stderr").write_bytes(stderr)
        records.append({"name": name, "command": list(map(str, command)),
                        "exit_code": code, "expected_exit_code": expected_code})
        check(f"{name}: exit", code == expected_code)
        return stdout.decode(errors="replace"), stderr.decode(errors="replace")

    _, phases = run("phases", [args.clang, "-ccc-print-phases", "-I", "src", "src/factorial.c"])
    check("driver phases", all(stage in phases for stage in
                              ("preprocessor", "compiler", "backend", "assembler", "linker")))

    for mode, value, output in ((0, 11, "14"), (1, 7, "10")):
        prefix = f"preprocess-{mode}"
        # Capture the actual preprocessor output, then compile that same file.
        preprocessed, _ = run(prefix, [args.cc, "-E", "-P", "-I", "src", f"-DMODE={mode}",
                                       "experiments/preprocess.c"])
        source = evidence / f"{prefix}.i"
        source.write_text(preprocessed, encoding="utf-8")
        compact = re.sub(r"\s+", "", preprocessed)
        check(f"{prefix}: macro and selected branch", f"putint((({value})+3));" in compact)
        check(f"{prefix}: comments removed", "REMOVE_LINE_MARKER" not in preprocessed
              and "REMOVE_BLOCK_MARKER" not in preprocessed)
        check(f"{prefix}: string preserved", '"/* not a comment */"' in preprocessed)
        check(f"{prefix}: header guard", preprocessed.count("int getint(void);") == 1)
        executable = evidence / prefix
        run(f"{prefix}-link", [args.cc, str(source), host_library, "-o", str(executable)])
        actual, _ = run(f"{prefix}-run", [str(executable)])
        check(f"{prefix}: result", actual == output)

    diagnostics = [
        (0, None),
        (1, "expected expression"),
        (2, "use of undeclared identifier 'undeclared'"),
        (3, "too few arguments"),
        (4, "cannot assign to variable 'bound'"),
        (5, "use of undeclared identifier 'scoped'"),
    ]
    for case, message in diagnostics:
        _, stderr = run(f"diagnostic-{case}", [args.clang, "-std=c11", "-pedantic-errors",
                         "-fsyntax-only", "-I", "src", f"-DCASE={case}", "experiments/diagnostics.c"],
                        expected_code=0 if message is None else 1)
        if message:
            check(f"diagnostic-{case}: expected reason", message in stderr)
    executable = evidence / "valid-scope"
    run("valid-scope-link", [args.clang, "-std=c11", "-I", "src", "-DCASE=0",
                            "experiments/diagnostics.c", host_library, "-o", str(executable)])
    stdout, _ = run("valid-scope-run", [str(executable)])
    check("nested and outer scope result", stdout == "52")

    run("assemble-generated-text", [args.cc, "-c", str(build / "factorial_gcc_O0.s"),
                                    "-o", str(evidence / "factorial_from_asm.o")])
    host_object, _ = run("host-object", ["objdump", "-dr", str(evidence / "factorial_from_asm.o")])
    check("host unresolved calls", "R_X86_64_PLT32" in host_object
          and "getint" in host_object and "putint" in host_object)
    host_linked, _ = run("host-linked", ["objdump", "-d", "--disassemble=main", str(build / "sysy/factorial_c_host")])
    check("host resolved calls", "<getint>" in host_linked and "<putint>" in host_linked)
    host_reloc, _ = run("host-dynamic-relocations", ["readelf", "-Wr", str(build / "sysy/factorial_c_host")])
    check("host libc relocations", "JUMP_SLOT" in host_reloc and "printf" in host_reloc and "scanf" in host_reloc)
    run("host-plt", ["objdump", "-d", "-j", ".plt", str(build / "sysy/factorial_c_host")])
    rv_object, _ = run("riscv-object", [args.riscv_objdump, "-dr", str(build / "sysy/factorial_asm_riscv.o")])
    check("riscv unresolved calls", "R_RISCV_CALL" in rv_object
          and "getint" in rv_object and "putint" in rv_object)
    rv_linked, _ = run("riscv-linked", [args.riscv_objdump, "-d", str(build / "sysy/factorial_asm_riscv")])
    check("riscv resolved calls", "<getint>" in rv_linked and "<putint>" in rv_linked)
    relocations, _ = run("riscv-linked-relocations", [args.riscv_readelf, "-r", str(build / "sysy/factorial_asm_riscv")])
    check("riscv call relocations resolved", re.search(r"R_RISCV_(CALL|JUMP_SLOT)", relocations) is None)
    debug, _ = run("debug-sections", ["readelf", "-SW", str(build / "sysy/features_c_host_g")])
    check("debug info exists", ".debug_info" in debug and ".debug_line" in debug)
    lines, _ = run("debug-lines", ["readelf", "--debug-dump=decodedline", str(build / "sysy/features_c_host_g")])
    check("debug maps to source", "features.sy" in lines)

    observations = {}
    for mode in ("O0", "g_O0", "O2"):
        ir = (build / f"features_clang_{mode}.ll").read_text()
        observations[mode] = {
            "lines": len(ir.splitlines()),
            "alloca": len(re.findall(r"\balloca\b", ir)),
            "phi": len(re.findall(r"\bphi\b", ir)),
            "debug_locations": len(re.findall(r"!dbg", ir)),
        }
    (evidence / "ir-observations.json").write_text(json.dumps(observations, indent=2) + "\n")
    (evidence / "commands.json").write_text(json.dumps(records, indent=2) + "\n")
    (evidence / "checks.json").write_text(json.dumps(checks, indent=2) + "\n")
    passed = sum(check["passed"] for check in checks)
    print(f"compiler: {passed}/{len(checks)} PASS; evidence: {evidence}")
    return 0 if passed == len(checks) else 1


if __name__ == "__main__":
    sys.exit(main())
