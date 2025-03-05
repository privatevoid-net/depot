export GRAFANA_HOST="${GRAFANA_HOST:-https://monitoring.privatevoid.net}"
export GRAF_TOKEN_FILE="${GRAF_TOKEN_FILE:-$HOME/.config/graf/token}"
export GRAF_DASHBOARDS_DIR="$REPO_ROOT/cluster/services/monitoring/provisioning/objects/dashboards"

api() {
  reqpath="$1"
  shift
  gum spin --title="Querying Grafana API..." --show-output -- curl -H @"$GRAF_TOKEN_FILE" -sSL --fail-with-body "$GRAFANA_HOST/api$reqpath" "$@"
}

cmd_export() {
  dashboardUid="$(api '/search?type=dash-db' | jq -r '.[] | "\(.uid) | \(.title)"' | gum choose | cut -d " " -f1)"
  dashboardLoc="$GRAF_DASHBOARDS_DIR/dashboard-$dashboardUid.json"
  api "/dashboards/uid/$dashboardUid" | jq '{ dashboard: .dashboard, folderId: .meta.folderId, overwrite: true }' > "$dashboardLoc"
  gum format "## Successfully exported dashboard to *$(realpath --relative-to="$REPO_ROOT" "${dashboardLoc}")*"
}

cmd_import() {
  dashboardUid="$(cat "$GRAF_DASHBOARDS_DIR"/dashboard-*.json | jq -r '"\(.dashboard.uid) | \(.dashboard.title)"' | gum choose | cut -d " " -f1)"
  dashboardLoc="$GRAF_DASHBOARDS_DIR/dashboard-$dashboardUid.json"
  dashboardUrl="$(api /dashboards/import -H "Content-Type: application/json" --data @"$dashboardLoc" | jq -r .importedUrl)"
  gum format "## Successfully imported dashboard to ${GRAFANA_HOST}${dashboardUrl}"
}

cmd="$1"
shift
case $cmd in
  export)
    cmd_export "$@";;
  import)
    cmd_import "$@";;
  *)
    echo Unknown command: "$cmd";;
esac
