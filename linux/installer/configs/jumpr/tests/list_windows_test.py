import subprocess

from conftest import SystemMocks


def test_list_no_windows(system_mocks: SystemMocks) -> None:
    # given
    _ = system_mocks.binary("gdbus")

    # when
    result = subprocess.run(
        ["/bin/bash", "-c", "source ../jumpr.sh && list-windows"],
        capture_output=True,
        text=True,
    )

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""
