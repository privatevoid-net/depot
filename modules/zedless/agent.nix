{
  programs.zedless.settings = let
    allTools = [
      "apply_code_action"
      "copy_path"
      "create_directory"
      "delete_path"
      "diagnostics"
      "edit_file"
      "fetch"
      "find_path"
      "find_references"
      "get_code_actions"
      "go_to_definition"
      "grep"
      "list_directory"
      "move_path"
      "now"
      "open"
      "project_notifications"
      "read_file"
      "rename_symbol"
      "restore_file_from_disk"
      "save_file"
      "search_web"
      "skill"
      "spawn_agent"
      "terminal"
      "thinking"
      "update_plan"
      "write_file"
    ];
  in {
    agent = {
      show_turn_stats = true;
      thinking_display = "always_collapsed";
      # profiles = {

      # };
    };
  };
}
