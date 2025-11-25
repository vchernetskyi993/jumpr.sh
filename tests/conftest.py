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
        self.setenv("MOCKS_DIR", f"./mocks/{self._test_name()}")
        return Mock(out_path, executable)

    def home(self) -> None:
        home_stub = (Path("./mocks") / self._test_name() / "home").absolute()
        home = home_stub if home_stub.is_dir() else self.tmp_path / "home"
        if not home.is_dir():
            home.mkdir()
        self.setenv("HOME", str(home))

    def data_dirs(self) -> None:
        data_root = self.tmp_path / "data"
        data_home_stub = (Path("./mocks") / self._test_name() / "data_home").absolute()
        data_home = data_home_stub if data_home_stub.is_dir() else data_root / "home"
        data_dirs_stub = (Path("./mocks") / self._test_name() / "data_dirs").absolute()
        data_dirs = (
            self._list_children_directories(data_dirs_stub)
            if data_dirs_stub.is_dir()
            else str(data_root / "dirs")
        )
        self.setenv("XDG_DATA_HOME", str(data_home))
        self.setenv("XDG_DATA_DIRS", data_dirs)

    def setenv(self, name: str, value: str) -> None:
        self.monkeypatch.setenv(name, value)

    def _list_children_directories(self, directory: Path) -> str:
        return ":".join([str(p) for p in directory.iterdir() if p.is_dir()])

    def _test_name(self) -> str:
        return self.request.node.name


@pytest.fixture
def system_mocks(
    monkeypatch: MonkeyPatch, tmp_path: Path, request: FixtureRequest
) -> SystemMocks:
    return SystemMocks(tmp_path, monkeypatch, request)


@pytest.fixture(autouse=True)
def prepare_directories(system_mocks: SystemMocks):
    system_mocks.data_dirs()
    system_mocks.home()
