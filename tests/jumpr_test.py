from ast import arg
from dataclasses import dataclass
import subprocess

import simple_parsing
from simple_parsing.utils import DataclassT

from conftest import SystemMocks


def test_switch_windows(system_mocks: SystemMocks) -> None:
    # given
    gdbus = system_mocks.binary("gdbus")

    # when
    _run_jumpr(system_mocks, "My Window")

    # then
    args = gdbus.received_args()
    assert len(args) == 2
    assert _parse(GDBusArgs, args[1]) == _activate_window(12345)


def test_launch_application(system_mocks: SystemMocks) -> None:
    # given
    gdbus = system_mocks.binary("gdbus")
    gtk_launch = system_mocks.binary("gtk-launch")

    # when
    _run_jumpr(system_mocks, "My Application")

    # then
    assert len(gdbus.received_args()) == 1
    launch_args = gtk_launch.received_args()
    assert len(launch_args) == 1
    assert _parse(GtkLaunchArgs, launch_args[0]) == GtkLaunchArgs(
        desktop_file="my-application.desktop"
    )


def _run_jumpr(system_mocks: SystemMocks, query: str) -> None:
    # given
    system_mocks.setenv("FZF_DEFAULT_OPTS", f"--query '{query}' --exact -1 -0")

    # when
    result = subprocess.run(["../jumpr.sh"], capture_output=True, text=True)

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""


def _parse(type: type[DataclassT], args: str) -> DataclassT:
    return simple_parsing.parse(type, args=args)


@dataclass
class GtkLaunchArgs:
    desktop_file: str = simple_parsing.field(positional=True)


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
