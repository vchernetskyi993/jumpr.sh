import subprocess


def test_empty_data_dirs() -> None:
    # when
    result = _list_applications()

    # then
    assert result == ""


def test_missing_data_dirs() -> None:
    # when
    result = _list_applications()

    # then
    assert result == ""


def test_duplicate_desktop_files() -> None:
    # when
    result = _list_applications()

    # then
    assert (
        result
        == "app:my-application.desktop\x1fapp: My Application \x1b[90m# my-application Home;\x1b[0m\n"
    )


def test_no_display() -> None:
    # when
    result = _list_applications()

    # then
    assert result == ""


def _list_applications() -> str:
    # when
    result = subprocess.run(
        ["/bin/bash", "-c", "source ../jumpr.sh && list-applications"],
        capture_output=True,
        text=True,
    )

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    return result.stdout
