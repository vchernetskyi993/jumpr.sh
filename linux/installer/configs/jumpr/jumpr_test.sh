#!/usr/bin/env bash

function test_switch_windows() {
  # given
  function mocked-windows() {
    cat <<'EOF'
('[{"in_current_workspace":true,"wm_class":"my-window","wm_class_instance":"my-window","title":"My Window","pid":5718,"id":12345,"frame_type":0,"window_type":0,"focus":false}]',)
EOF
  }
  export -f mocked-windows 
  mock gdbus mocked-windows
  spy gdbus

  # when
  FZF_DEFAULT_OPTS="--query 'My Window' --exact -1 -0" ./jumpr.sh

  # then
  # assert_same "hello" "$OUT" 
  assert_have_been_called_times 2 gdbus
  assert_have_been_called_with gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/Windows --method org.gnome.Shell.Extensions.Windows.List
  # TODO: gdbus focus called with correct winid
}

