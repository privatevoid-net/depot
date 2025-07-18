{
  system.extraIncantations = {
    runGaragePostUpgrade = i: i.runGarage ''
      garage repair --all-nodes --yes tables
      garage repair --all-nodes --yes blocks
    '';

    stopGarageNodes = i: version: i.runConsul ''
      while test "$(consul catalog nodes --service=garage --filter='ServiceTags not contains "v${version}"' | wc -l)" -gt 0; do
        echo 'Waiting for all Garage ${version} nodes to disappear'
        sleep 5
      done
    '';
  };

  system.ascensions = {
    garage-pre-upgrade.incantations = i: [
    ];

    garage-post-upgrade.incantations = i: [
    ];
  };
}
