{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
    };
  };
}
