import subprocess
from conftest import SystemMocks


def test_empty_data_dirs(system_mocks: SystemMocks) -> None:
    # given
    # TODO: move to before_each
    system_mocks.data_dirs()
    system_mocks.home()

    # when
    result = subprocess.run(
        ["/bin/bash", "-c", "source ../jumpr.sh && list-applications"],
        capture_output=True,
        text=True,
    )

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == ""
