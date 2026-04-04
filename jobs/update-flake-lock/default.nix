{
  hercules-ci.flake-update = {
    enable = true;
    createPullRequest = true;
    autoMergeMethod = "merge";
    forgeType = "github";
    updateBranch = "pr-flake-update";
    baseMerge = {
      enable = true;
      method = "reset";
    };
    when = {
      dayOfWeek = "Fri";
      hour = 2;
    };
  };
}
