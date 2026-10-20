#!/usr/bin/env python3
"""Check the project launcher without starting terminal sessions.

Run: python3 tests/check-zellij.py
"""
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / "readme.org").read_text()
body = source.split('name = "zellij-start";', 1)[1].split("text = ''\n", 1)[1].split("\n    '';", 1)[0]
body = body.replace("''${", "${")

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    fake = root / "zellij"
    fake.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
    fake.chmod(0o755)
    launcher = root / "launcher"
    launcher.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + body + "\n")
    env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}")
    for key in ("ZELLIJ", "ZELLIJ_SESSION_NAME", "GIT_DIR", "GIT_WORK_TREE"):
        env.pop(key, None)

    def run(cwd, **extra):
        return subprocess.check_output(
            ["bash", str(launcher)], cwd=cwd, env=env | extra, text=True
        ).splitlines()

    assert run(root) == ["-l", "welcome"]
    assert run(root, ZELLIJ_SESSION_NAME="existing project", ZELLIJ="0") == [
        "attach", "--create", "existing project"
    ]
    project = root / "project with spaces"
    project.mkdir()
    subprocess.run(["git", "init", "-q", str(project)], check=True)
    child = project / "subdirectory"
    child.mkdir()
    digest = hashlib.sha256(str(project).encode()).hexdigest()[:8]
    expected = ["attach", "--create", f"{project.name}-{digest}"]
    assert run(project) == expected
    assert run(child) == expected
    assert run(project, ZELLIJ_SESSION_NAME="inherited") == [
        "attach", "--create", "inherited"
    ]
print("Zellij launcher checks passed")
