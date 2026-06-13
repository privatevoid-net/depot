{ config, lib, ... }:

{
  options.desktop = {
    appFolders = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          translate = lib.mkEnableOption "folder name translation";
          categories = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          apps = lib.mkOption {
            default = [];
            type = lib.types.listOf (lib.types.submodule {
              options = {
                package = lib.mkOption {
                  type = lib.types.nullOr lib.types.package;
                  default = null;
                };
                appId = lib.mkOption {
                  type = lib.types.str;
                };
              };
            });
          };
        };
      }));
    };
  };

  config = let
    allApps = lib.filter (app: app.package != null) (lib.flatten (lib.mapAttrsToList (n: v: v.apps) config.desktop.appFolders));

    sanitizeName = name: "folder-${lib.strings.sanitizeDerivationName name}";

    toGVariantStringArray = xs: if xs == []
      then lib.gvariant.mkEmptyArray lib.gvariant.type.string
      else lib.gvariant.mkArray xs;

    mkAppFolderDconfEntry = name: folder: lib.nameValuePair "org/gnome/desktop/app-folders/folders/${sanitizeName name}" (folder // {
      apps = toGVariantStringArray (map (app: "${app.appId}.desktop") folder.apps);
      categories = toGVariantStringArray folder.categories;
    });
  in {
    environment.systemPackages = map (app: app.package) allApps;

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;
          settings = lib.mkMerge [
            { "org/gnome/desktop/app-folders".folder-children = map sanitizeName (lib.attrNames config.desktop.appFolders); }
            (lib.mapAttrs' mkAppFolderDconfEntry config.desktop.appFolders)
          ];
        }
      ];
    };
  };
}
