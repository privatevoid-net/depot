{
  hercules-ci.flake-update = {
    enable = true;
    createPullRequest = true;
    autoMergeMethod = "merge";
    forgeType = "github";
    updateBranch = "pr-flake-update";
    when = {
      dayOfWeek = "Fri";
      hour = 2;
    };
  };
}
