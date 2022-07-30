REPO_ROOT="${REPO_ROOT:-.}"
NPINS_DIRECTORY="${NPINS_DIRECTORY:-npins}"

cmd="$1"
shift
case $cmd in
  update)
    for pkg in "$@"; do
      oldver=$(nix eval --raw "${REPO_ROOT}#${pkg}.version")
      npins update "$pkg"
      newver=$(nix eval --raw "${REPO_ROOT}#${pkg}.version")
      git add "${NPINS_DIRECTORY}"
      git commit "${NPINS_DIRECTORY}" -m "packages/$pkg: $oldver -> $newver"
    done;;
  *)
    echo Unknown command: "$cmd";;
esac