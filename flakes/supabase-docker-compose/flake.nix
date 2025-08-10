{
  description = "Generate NixOS containers from Supabase docker-compose.yml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    compose2nix.url = "github:mpontus/compose2nix";
  };

  outputs = { self, nixpkgs, flake-utils, compose2nix }:
    let
      supabase-nixos-containers-for = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          src = pkgs.fetchFromGitHub {
            owner = "supabase";
            repo = "supabase";
            rev = "adfc138450c98191ee539c6b9b3e18b87d28ba0b";
            sha256 = "sha256-WoXuFyjpxg6sMFN55Q+m8GSoexsNJd76OJUVOJoo0VQ=";
          };
          envFile = pkgs.writeText ".env" ''
            POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
            POSTGRES_HOST=db
            POSTGRES_PORT=5432
            POSTGRES_DB=postgres
            JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
            VAULT_ENC_KEY=your-vault-encryption-key
            SECRET_KEY_BASE=your-super-secret-and-long-secret-key-base
            ANON_KEY=your-anon-key
            SERVICE_ROLE_KEY=your-service-role-key
            DASHBOARD_USERNAME=supabase
            DASHBOARD_PASSWORD=this_password_is_insecure_and_should_be_updated
            LOGFLARE_PRIVATE_ACCESS_TOKEN=your-logflare-private-access-token
            LOGFLARE_PUBLIC_ACCESS_TOKEN=your-logflare-public-access-token
            POOLER_TENANT_ID=your-pooler-tenant-id
            POOLER_PROXY_PORT_TRANSACTION=6543
            POOLER_MAX_CLIENT_CONN=100
            POOLER_DB_POOL_SIZE=20
            POOLER_DEFAULT_POOL_SIZE=25
            # DOCKER_SOCKET_LOCATION=/var/run/docker.sock
            DOCKER_SOCKET_LOCATION=/var/run/podman/podman.sock
            KONG_HTTP_PORT=8000
            KONG_HTTPS_PORT=8443
            SITE_URL=http://localhost:3000
            API_EXTERNAL_URL=http://localhost:8000
            PGRST_DB_SCHEMAS=public,storage,graphql_public
            FUNCTIONS_VERIFY_JWT=false
            ENABLE_EMAIL_SIGNUP=true
            ENABLE_PHONE_SIGNUP=true
            ENABLE_ANONYMOUS_USERS=false
            ENABLE_EMAIL_AUTOCONFIRM=false
            ENABLE_PHONE_AUTOCONFIRM=false
            DISABLE_SIGNUP=false
            JWT_EXPIRY=3600
            ADDITIONAL_REDIRECT_URLS=
            SMTP_HOST=
            SMTP_PORT=587
            SMTP_USER=
            SMTP_PASS=
            SMTP_SENDER_NAME=
            SMTP_ADMIN_EMAIL=
            MAILER_URLPATHS_INVITE=/auth/v1/verify
            MAILER_URLPATHS_CONFIRMATION=/auth/v1/verify
            MAILER_URLPATHS_RECOVERY=/auth/v1/verify
            STUDIO_DEFAULT_ORGANIZATION=Default Organization
            STUDIO_DEFAULT_PROJECT=Default Project
            SUPABASE_PUBLIC_URL=http://localhost:8000
            IMGPROXY_ENABLE_WEBP_DETECTION=false
          '';
        in pkgs.stdenv.mkDerivation {
          inherit src;
          name = "supabase-nixos-containers";
          version = "latest";

          buildInputs =
            [ compose2nix.packages.${system}.default pkgs.nixfmt-classic ];

          buildPhase = ''
            cd docker

            # Fix the Docker socket mount issue by removing the ,z option that compose2nix doesn't understand
            sed -i 's/:ro,z/:ro/g' docker-compose.yml

            compose2nix \
              -inputs docker-compose.yml \
              -output docker-compose.nix \
              -root_path "${src}/docker" \
              -runtime podman \
              -auto_format \
              -create_root_target \
              -project supabase \
              -env_files ${envFile}

            # Fix PostgreSQL data volume to use writable host directory
            sed -i 's|${src}/docker/volumes/db/data|/var/lib/supabase/db/data|g' docker-compose.nix
            sed -i 's|${src}/docker/volumes/storage|/var/lib/supabase/storage|g' docker-compose.nix
          '';

          installPhase = ''
            mkdir -p $out
            cp docker-compose.nix $out/
            cp docker-compose.yml $out/
          '';
        };
    in (flake-utils.lib.eachDefaultSystem
      (system: { packages.default = supabase-nixos-containers-for system; }))
    // {
      # System-independent NixOS module
      nixosModules.default = import
        "${supabase-nixos-containers-for "x86_64-linux"}/docker-compose.nix";
    };
}
