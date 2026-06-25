{
  programs.zedless.settings = {
    vim_mode = true;
    vim = {
      use_system_clipboard = "on_yank";
      use_smartcase_find = true;
      toggle_relative_line_numbers = true;
    };
    autosave.after_delay.milliseconds = 500;
    ensure_final_newline_on_save = true;
    terminal = {
      show_count_badge = true;
      line_height = "standard";
      minimum_contrast = 0;
      toolbar.breadcrumbs = true;
    };
    title_bar.show_branch_status_icon = true;
    git.inline_blame.show_commit_summary = true;
    scrollbar = {
      axes = {
        horizontal = false;
        vertical = false;
      };
    };
    minimap.show = "auto";
    max_tabs = 4;
    tabs = {
      git_status = true;
      file_icons = true;
      show_diagnostics = "errors";
    };
  };
}
