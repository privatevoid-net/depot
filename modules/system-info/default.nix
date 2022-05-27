{ inputs, ... }:

{
  system.configurationRevision = inputs.self.rev or null;
}
