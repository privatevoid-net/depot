REPO_ROOT="${REPO_ROOT:-.}"
NPINS_DIRECTORY="${NPINS_DIRECTORY:-npins}"

cmd_update() {
  for pkg in "$@"; do
    oldver=$(nix eval --raw "${REPO_ROOT}#${pkg}.version")
    npins update "$pkg"
    newver=$(nix eval --raw "${REPO_ROOT}#${pkg}.version")
    git add "${NPINS_DIRECTORY}"
    git commit "${NPINS_DIRECTORY}" -m "packages/$pkg: $oldver -> $newver" || true
  done
}

cmd_update_all() {
  # shellcheck disable=SC2046
  cmd_update $(jq < "${NPINS_DIRECTORY}/sources.json" -r '.pins | keys | .[]')
}

cmd="$1"
shift
case $cmd in
  update)
    cmd_update "$@";;
  update-all)
    cmd_update_all "$@";;
  *)
    echo Unknown command: "$cmd";;
esac