{
  description = "mcp-crawl4ai-rag as a NixOS service";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/e462a75ad44682b4e8df740e33fca4f048e8aa11";
    flake-utils.url = "github:numtide/flake-utils";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, uv2nix, pyproject-nix
    , pyproject-build-systems }:
    let
      inherit (nixpkgs) lib;

      # Function to create packages for a given system
      mkSystemPackages = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          src = pkgs.fetchFromGitHub {
            owner = "coleam00";
            repo = "mcp-crawl4ai-rag";
            rev = "main"; # Choose a commit for reproducibility
            sha256 = "4FNCKgGGs3T/OIQwTtp/+wR5RzCwhdyfonX+a3P2GWc=";
          };

          # Load the uv workspace
          workspace =
            uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };

          # Create overlay from workspace
          overlay =
            workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

          # Extend generated overlay with build fixups
          #
          # Uv2nix can only work with what it has, and uv.lock is missing essential metadata to perform some builds.
          # This is an additional overlay implementing build fixups.
          # See:
          # - https://pyproject-nix.github.io/uv2nix/FAQ.html
          pyprojectOverrides = _final: _prev: {
            # Implement build fixups here.
            # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
            # It's using https://pyproject-nix.github.io/pyproject.nix/build.html

            # Override NVIDIA packages that are causing build failures
            nvidia-cufile-cu12 = _prev.nvidia-cufile-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps =
                  [ "libmlx5.so.1" "librdmacm.so.1" "libibverbs.so.1" ];
              });

            nvidia-cusolver-cu12 = _prev.nvidia-cusolver-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps = [
                  "libnvJitLink.so.12"
                  "libcusparse.so.12"
                  "libcublas.so.12"
                  "libcublasLt.so.12"
                ];
              });

            nvidia-cusparse-cu12 = _prev.nvidia-cusparse-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps = [
                  "libnvJitLink.so.12"
                  "libcublas.so.12"
                  "libcublasLt.so.12"
                ];
              });

            nvidia-cublas-cu12 = _prev.nvidia-cublas-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps = [ "libnvJitLink.so.12" ];
              });

            nvidia-cufft-cu12 = _prev.nvidia-cufft-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps =
                  [ "libnvJitLink.so.12" "libcufftw.so.11" ];
              });

            nvidia-curand-cu12 = _prev.nvidia-curand-cu12.overrideAttrs
              (oldAttrs: {
                autoPatchelfIgnoreMissingDeps = [ "libnvJitLink.so.12" ];
              });

            # Use nixpkgs pyperclip instead of building from source
            pyperclip = pkgs.python312Packages.pyperclip;

            # Fix torch CUDA dependency issues
            torch = _prev.torch.overrideAttrs (oldAttrs: {
              autoPatchelfIgnoreMissingDeps = [
                "libcudnn.so.9"
                "libcusparseLt.so.0"
                "libcufile.so.0"
                "libcupti.so.12"
                "libcudart.so.12"
                "libnvrtc.so.12"
                "libcuda.so.1"
                "libcusparse.so.12"
                "libcufft.so.11"
                "libcurand.so.10"
                "libcublas.so.12"
                "libcublasLt.so.12"
                "libnccl.so.2"
                "libcusolver.so.11"
              ];
            });
          };

          # Python environment
          python = pkgs.python312;

          # Construct package set
          pythonSet =
            # Use base package set from pyproject.nix builders
            (pkgs.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope (lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              overlay
              pyprojectOverrides
            ]);

          # Virtual environment with all dependencies
          venv = pythonSet.mkVirtualEnv "mcp-crawl4ai-rag-env"
            workspace.deps.default;
          
          # Create executable package with baked-in browser paths
          package = pkgs.writeShellScriptBin "mcp-crawl4ai-rag" ''
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            exec ${venv}/bin/python ${src}/src/crawl4ai_mcp.py "$@"
          '';
        in {
          inherit src venv package;

          # For development/testing
          app = flake-utils.lib.mkApp {
            drv = package;
          };
        };
    in (flake-utils.lib.eachDefaultSystem (system:
      let systemPkgs = mkSystemPackages system;
      in {
        packages.default = systemPkgs.package;
        packages.venv = systemPkgs.venv;  # Keep venv available as a separate package
        apps.default = systemPkgs.app;
      })) // {
        # System-independent NixOS modules
        nixosModules.default = { config, lib, pkgs, ... }: {
          systemd.services.mcp-crawl4ai-rag = {
            description = "mcp-crawl4ai-rag server";
            after = [
              "network.target"
              "oci-containers-supabase-db.service"
              "oci-containers-neo4j.service"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = let
              # Only try to build the package on supported systems
              systemPkgs = if pkgs.stdenv.isLinux then
                mkSystemPackages pkgs.stdenv.hostPlatform.system
              else
                throw
                "mcp-crawl4ai-rag is only supported on Linux systems due to NVIDIA CUDA dependencies";
            in {
              ExecStart =
                "${systemPkgs.venv}/bin/python ${systemPkgs.src}/src/crawl4ai_mcp.py";

              Restart = "always";
              RestartSec = 5;
              WorkingDirectory = "${systemPkgs.src}";
              Environment = [
                "SUPABASE_URL=postgresql://postgres:password@localhost:5432/postgres"
                "NEO4J_URI=bolt://localhost:7687"
                "USE_CONTEXTUAL_EMBEDDINGS=true"
                "USE_HYBRID_SEARCH=true"
                "USE_AGENTIC_RAG=true"
                "USE_RERANKING=true"
                "USE_KNOWLEDGE_GRAPH=true"
                "PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}"
                "PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1"
              ];
            };
          };
        };
      };
}
