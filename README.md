# Drata Agent

The Drata Agent is a lightweight application that lives in your computer's toolbar. This application is granted READ ONLY access to your system preferences to help ensure proper security configurations are set - such as screensaver locking, password manager, antivirus software and automatic updates are enabled. These security configurations are required for SOC 2 compliance.

# NixOS Flakes Installation

`flake.nix`

``` nix
{
    inputs = {
        drata.url = "github:ddlees/drata.flake";
    };
}
```

`configuration.nix`

``` nix
environment.systemPackages = with pkgs; [
    inputs.drata.packages.${system}.drata
];
```
