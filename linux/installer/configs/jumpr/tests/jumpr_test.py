import os
from pathlib import Path
import subprocess

from pytest import MonkeyPatch


def test_switch_windows(monkeypatch: MonkeyPatch) -> None:
    # given
    mocks_path = Path("./bin/").resolve()
    monkeypatch.setenv("PATH", f"{mocks_path}:{os.environ['PATH']}")
    monkeypatch.setenv("FZF_DEFAULT_OPTS", "--query 'My Window' --exact -1 -0")
    # mock list applications

    # when
    result = subprocess.run(["../jumpr.sh"], capture_output=True, text=True)

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""
    # assert 2 gdbus calls
    # assert window activate called with correct arguments
