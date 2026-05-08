handle_option() {
  # default impl: unknown option, die
  # return the number of args consumed by the option so the caller can shift them
  die "Unknown option: $1"
  return 1
}

handle_positional_args() {
  # default impl: do nothing
  return 0
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --debug)
        set_debug
        shift
        ;;
      --debug2)
        set_debug 2
        shift
        ;;
      --trace)
        set_trace
        shift
        ;;
      -*)
        handle_option "$@"
        shift $?
        ;;
      *)
        break
    esac
  done
  handle_positional_args "$@"
}
