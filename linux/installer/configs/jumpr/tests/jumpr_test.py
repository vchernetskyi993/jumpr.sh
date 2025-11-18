from dataclasses import dataclass, field
import os
from pathlib import Path
import subprocess

import simple_parsing
from pytest import MonkeyPatch, FixtureRequest


def test_switch_windows(
    monkeypatch: MonkeyPatch, tmp_path: Path, request: FixtureRequest
) -> None:
    # given
    mocks_path = Path("./bin/").resolve()
    monkeypatch.setenv("PATH", f"{mocks_path}:{os.environ['PATH']}")
    monkeypatch.setenv("FZF_DEFAULT_OPTS", "--query 'My Window' --exact -1 -0")
    out_path = tmp_path / "out"
    monkeypatch.setenv("OUT_DIR", str(out_path))
    monkeypatch.setenv("MOCKS_DIR", f"./mocks/{request.node.name}")
    # mock applications
    # mock $HOME

    # when
    result = subprocess.run(["../jumpr.sh"], capture_output=True, text=True)

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""

    with open(out_path / "gdbus_args", "r") as args_file:
        lines = args_file.readlines()
        assert len(lines) == 2
        print(lines[1].split()[2:])
        activation_args = simple_parsing.parse_known_args(
            GDBusArgs, args=lines[1].split()
        )
        assert activation_args == (
            GDBusArgs(
                command="call",
                session=True,
                dest="org.gnome.Shell",
                object_path="/org/gnome/Shell/Extensions/Windows",
                method="org.gnome.Shell.Extensions.Windows.Activate",
                window_id=12345,
            ),
            [],
        )


@dataclass
class GDBusArgs:
    command: str = simple_parsing.field(positional=True)
    window_id: int = simple_parsing.field(positional=True)
    session: bool = False
    dest: str = ""
    object_path: str = simple_parsing.field(default="", alias="--object-path")
    method: str = ""
