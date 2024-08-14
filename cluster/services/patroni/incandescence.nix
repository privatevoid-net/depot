{ config, lib, ... }:

{
  incandescence.providers.patroni = {
    objects = {
      user = lib.attrNames config.patroni.users;
      database = lib.attrNames config.patroni.databases;
    };
  };
}
