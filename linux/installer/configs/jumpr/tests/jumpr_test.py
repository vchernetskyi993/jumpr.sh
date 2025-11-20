from dataclasses import dataclass
import os
from pathlib import Path
import shutil
import subprocess

import simple_parsing
from pytest import MonkeyPatch, FixtureRequest
from simple_parsing.utils import DataclassT


def test_switch_windows(
    monkeypatch: MonkeyPatch, tmp_path: Path, request: FixtureRequest
) -> None:
    # given
    mocks = SystemMocks(tmp_path, monkeypatch, request)
    gdbus = mocks.binary("gdbus")
    monkeypatch.setenv("FZF_DEFAULT_OPTS", "--query 'My Window' --exact -1 -0")
    # TODO: mock applications
    mocks.home()

    # when
    result = subprocess.run(["../jumpr.sh"], capture_output=True, text=True)

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""

    args = gdbus.received_args()
    assert len(args) == 2
    assert _parse(GDBusArgs, args[1]) == _activate_window(12345)


def _parse(type: type[DataclassT], args: str) -> DataclassT:
    return simple_parsing.parse(type, args=args)


@dataclass
class GDBusArgs:
    command: str = simple_parsing.field(positional=True)
    window_id: int = simple_parsing.field(positional=True)
    session: bool = False
    dest: str = ""
    object_path: str = simple_parsing.field(default="", alias="--object-path")
    method: str = ""


def _activate_window(window_id: int) -> GDBusArgs:
    return GDBusArgs(
        command="call",
        session=True,
        dest="org.gnome.Shell",
        object_path="/org/gnome/Shell/Extensions/Windows",
        method="org.gnome.Shell.Extensions.Windows.Activate",
        window_id=window_id,
    )


@dataclass
class Mock:
    out_path: Path
    executable: str

    def received_args(self) -> list[str]:
        with open(self.out_path / f"{self.executable}_args", "r") as args_file:
            return args_file.readlines()


@dataclass
class SystemMocks:
    tmp_path: Path
    monkeypatch: MonkeyPatch
    request: FixtureRequest

    def binary(self, executable: str) -> Mock:
        bin_dir = self.tmp_path / "bin"
        bin_dir.mkdir(exist_ok=True)
        _ = shutil.copy2("./bin/stub", bin_dir / executable)
        self.monkeypatch.setenv("PATH", f"{bin_dir}:{os.environ['PATH']}")
        out_path = self.tmp_path / "out"
        self.monkeypatch.setenv("OUT_DIR", str(out_path))
        self.monkeypatch.setenv("MOCKS_DIR", f"./mocks/{self.request.node.name}")
        return Mock(out_path, executable)

    def home(self) -> None:
        home = self.tmp_path / "home"
        home.mkdir()
        self.monkeypatch.setenv("HOME", str(home))
