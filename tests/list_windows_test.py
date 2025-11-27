import subprocess

from conftest import SystemMocks


def test_list_no_windows(system_mocks: SystemMocks) -> None:
    # given
    _ = system_mocks.binary("gdbus")

    # when
    result = _list_windows()

    # then
    assert result == ""


def test_window_with_double_quote(system_mocks: SystemMocks) -> None:
    # given
    _ = system_mocks.binary("gdbus")

    # when
    result = _list_windows()

    # then
    assert result == _double_quoted_window()


def test_window_with_single_quote(system_mocks: SystemMocks) -> None:
    # given
    _ = system_mocks.binary("gdbus")

    # when
    result = _list_windows()

    # then
    assert result == _single_quoted_window()


def test_window_with_both_quotes(system_mocks: SystemMocks) -> None:
    # given
    _ = system_mocks.binary("gdbus")

    # when
    result = _list_windows()

    # then
    assert result == _mixed_quoted_window()


def _list_windows() -> str:
    result = subprocess.run(
        ["/bin/bash", "-c", "source ./jumpr.sh && list-windows"],
        capture_output=True,
        text=True,
    )

    # then
    assert result.returncode == 0
    assert result.stderr == ""
    return result.stdout


def _double_quoted_window() -> str:
    # should be the last line in the file, since Neovim indent gets broken for all lines after this string
    return 'win:12345\x1fwin: My "Window" \x1b[90m# my-window\x1b[0m\n'


def _single_quoted_window() -> str:
    # should be the last line in the file, since Neovim indent gets broken for all lines after this string
    return "win:12345\x1fwin: My 'Window' \x1b[90m# my-window\x1b[0m\n"


def _mixed_quoted_window() -> str:
    # should be the last line in the file, since Neovim indent gets broken for all lines after this string
    return "win:12345\x1fwin: My \"Window' \x1b[90m# my-window\x1b[0m\n"
