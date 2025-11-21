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

    def setenv(self, name: str, value: str) -> None:
        self.monkeypatch.setenv(name, value)


@pytest.fixture
def system_mocks(
    monkeypatch: MonkeyPatch, tmp_path: Path, request: FixtureRequest
) -> SystemMocks:
    return SystemMocks(tmp_path, monkeypatch, request)
