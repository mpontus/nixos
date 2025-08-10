{
  description = "NixOS Flake Configuration";
  inputs.self.submodules = true;
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    mcp-crawl4ai-rag.url = "github:mpontus/nixos?dir=flakes/mcp-crawl4ai-rag";
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.mcp-crawl4ai-rag.nixosModules.default
      ];
    };
  };
}
