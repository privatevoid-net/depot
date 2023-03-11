{ depot, ... }:

{
  system.configurationRevision = depot.rev or null;
}
