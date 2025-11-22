from dataclasses import dataclass
import os
from pathlib import Path
import shutil

import pytest
from pytest import MonkeyPatch, FixtureRequest


@dataclass
class Mock:
    out_path: Path
    executable: str

    def received_args(self) -> list[str]:
        args_path = self.out_path / f"{self.executable}_args"
        if not args_path.is_file():
            return []

        with args_path.open("r") as args_file:
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
        self.setenv("PATH", f"{bin_dir}:{os.environ['PATH']}")
        out_path = self.tmp_path / "out"
        self.setenv("OUT_DIR", str(out_path))
        self.setenv("MOCKS_DIR", f"./mocks/{self.request.node.name}")
        return Mock(out_path, executable)

    def home(self) -> None:
        home = self.tmp_path / "home"
        home.mkdir()
        self.setenv("HOME", str(home))

    def data_dirs(self) -> None:
        data_root = self.tmp_path / "data"
        data_home = data_root / "home"
        data_dirs = data_root / "dirs"
        self.setenv("XDG_DATA_HOME", str(data_home))
        self.setenv("XDG_DATA_DIRS", str(data_dirs))

    def setenv(self, name: str, value: str) -> None:
        self.monkeypatch.setenv(name, value)


@pytest.fixture
def system_mocks(
    monkeypatch: MonkeyPatch, tmp_path: Path, request: FixtureRequest
) -> SystemMocks:
    return SystemMocks(tmp_path, monkeypatch, request)


@pytest.fixture(autouse=True)
def prepare_directories(system_mocks: SystemMocks):
    system_mocks.data_dirs()
    system_mocks.home()
