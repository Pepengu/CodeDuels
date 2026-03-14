{
  description = "Code duels app";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        code-duels = pkgs.stdenv.mkDerivation {
          name = "code-duels-runner";
          src = ./.;

          buildInputs = with pkgs;[
            elixir
            erlang
            nodejs
            postgresql
            tailwindcss_4
            esbuild
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp -r . $out/project

            cat > $out/bin/run-code-duels << EOF
            #!/bin/bash
            set -e

            # Copy project to a writable temporary directory
            TMP_DIR=\$(mktemp -d)
            cp -r $out/project/* \$TMP_DIR/
            # Copy the built release from the original project directory
            if [ -d "/home/daniil/Documents/elixir/code-duels/_build" ]; then
              mkdir -p \$TMP_DIR/_build
              cp -r /home/daniil/Documents/elixir/code-duels/_build/prod \$TMP_DIR/_build/
            fi
            cd \$TMP_DIR

            echo "Portfolio Phoenix Application"
            echo "=============================="
            echo "Starting Phoenix server with database setup..."
            echo ""

            DATA_DIR="\$HOME/.code-duels-data"
            mkdir -p \$DATA_DIR

            export PGDATA="\$DATA_DIR/postgres"
            export PGHOST="\$DATA_DIR/postgres"

            if [ ! -d \$PGDATA ]; then
              echo "Setting up PostgreSQL database..."
              initdb --auth-host=trust --auth-local=trust --username=postgres
              echo "listen_addresses = 'localhost'" >> \$PGDATA/postgresql.conf
              echo "port = 5432" >> \$PGDATA/postgresql.conf
              echo "unix_socket_directories = '\$DATA_DIR/postgres'" >> \$PGDATA/postgresql.conf
            fi

            echo "Starting PostgreSQL..."
            pg_ctl start -o "-k \$DATA_DIR -h localhost" -l "\$DATA_DIR/postgres.log" 2>/dev/null || echo "PostgreSQL already running"

            # Ensure postgres user exists and create database
            echo "Setting up database user and database..."
            psql -h localhost -U postgres -d postgres -c "CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';" 2>/dev/null || echo "User already exists or creation failed"
            createdb -h localhost -U postgres code-duels_prod 2>/dev/null || echo "Database already exists"

            if [ -f .env ]; then
              echo "Loading environment from .env file..."
              export \$(grep -v "^#" .env | xargs)
            fi

            export PHX_SERVER=true
            export MIX_ENV=prod
            export SECRET_KEY_BASE="''${SECRET_KEY_BASE:-\"REPLACED_IN_CLEANUP\"}"
            export LIVEVIEW_SIGNING_SALT="''${LIVEVIEW_SIGNING_SALT:-\"REPLACED_IN_CLEANUP\"}"
            export DATABASE_URL="''${DATABASE_URL:-\"ecto://postgres:postgres@localhost/code-duels_prod\"}"
            export PHX_HOST="''${PHX_HOST:-\"localhost\"}"
            export PORT="''${PORT:-\"4000\"}"

            echo "Waiting for database to be ready..."
            for i in {1..30}; do
              if pg_isready -h localhost -U postgres >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done

            # Try to use existing release, otherwise provide instructions
            if [ -f "_build/prod/rel/code-duels/bin/code-duels" ]; then
              echo "Using existing release..."
            else
              echo "No release found. Please build it manually first:"
              echo "  mix deps.get"
              echo "  mix compile"
              echo "  mix release"
              exit 1
            fi

            echo "Running database migrations..."
            _build/prod/rel/code-duels/bin/code-duels eval "Portfolio.Release.migrate" 2>/dev/null || echo "Migrations completed or skipped"

            echo ""
            echo "🚀 Phoenix server starting on http://\$PHX_HOST:\$PORT"
            echo "📊 Admin login: admin / REPLACED_IN_CLEANUP"
            echo "📁 Data stored in: \$HOME/.code-duels-data"
            echo "🛑 Press Ctrl+C to stop"
            echo ""

            exec _build/prod/rel/code-duels/bin/code-duels start
            EOF
            chmod +x $out/bin/run-code-duels
          '';
        };

      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
              elixir
              elixir-ls
              postgresql

              tailwindcss_4
              esbuild

              inotify-tools
              watchman
          ];

          env = {
            TAILWIND_BINARY = "${pkgs.tailwindcss_4}/bin/tailwindcss";
            ESBUILD_BINARY = "${pkgs.esbuild}/bin/esbuild";
            PGDATA = ".postgres";
            PGHOST = ".postgres";
          };

          shellHook = ''

            if [ -f .env ]; then
              export $(grep -v "^#" .env | xargs)
              echo ".env file loaded successfully"
            else
              echo "Warning: .env file not found. Create one with admin credentials."
            fi

            if [ ! -d $PGDATA ]; then
              initdb --auth-host=trust --auth-local=trust
              echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf
              echo "port = 5432" >> $PGDATA/postgresql.conf

              pg_ctl start -o "-k $PWD -h localhost" -w
              psql -h localhost -d postgres -c "CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';"
              pg_ctl stop -w
            fi
            pg_ctl start -o "-k $PWD -h localhost"
            echo "PostgreSQL started with postgres user. You can now run: mix ecto.create"
          '';
        };

        packages.default = code-duels;

        apps.default = flake-utils.lib.mkApp {
          drv = code-duels;
          exePath = "/bin/run-code-duels";
        };
      }
    );
}


