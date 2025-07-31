{
  inputs,
  lib,
  config,
  ...
}:
{
  # Git includes will be configured when private repository is available

  programs.git = {
    enable = true;
    userName = "Wolfgang";
    userEmail = "mail@weirdrescue.pw";

    extraConfig = {
      core = {
        sshCommand = "ssh -o 'IdentitiesOnly=yes' -i ~/.ssh/amoon";
      };
    };
    # includes = [
    #   {
    #     path = "~/.config/git/includes";
    #     condition = "gitdir:~/Workspace/Projects/";
    #   }
    # ];
  };
}
