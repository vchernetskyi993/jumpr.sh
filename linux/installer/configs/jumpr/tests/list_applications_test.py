import subprocess


def test_empty_data_dirs() -> None:
    _list_applications()


def test_missing_data_dirs() -> None:
    _list_applications()


def _list_applications() -> None:
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
