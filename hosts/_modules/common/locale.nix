{lib, ...}: {
  time.timeZone = lib.mkDefault "Asia/Shanghai";
  environment .variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
