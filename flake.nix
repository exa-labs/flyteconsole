{
  description = "Flyteconsole development environment with AWS CLI and ECR credential helper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # AWS tools
            awscli2
            amazon-ecr-credential-helper

            # Additional tools you might need
            docker
            docker-compose
            jq
            curl

            # Node.js for flyteconsole development
            nodejs_22
            yarn

            # Other useful tools
            git
            which
          ];

          shellHook = ''
            echo "Flyteconsole development environment loaded!"
            echo "Available tools:"
            echo "  - AWS CLI v2"
            echo "  - Amazon ECR credential helper"
            echo "  - Docker & Docker Compose"
            echo "  - Node.js & Yarn"

            # Set up Docker credential helper for ECR
            if [ ! -f ~/.docker/config.json ]; then
              mkdir -p ~/.docker
              echo '{"credsStore": "ecr-login"}' > ~/.docker/config.json
            else
              # Check if ECR credential helper is already configured
              if ! grep -q "ecr-login" ~/.docker/config.json; then
                echo "Note: Docker config exists but ECR credential helper is not configured."
                echo "You may want to add '\"credsStore\": \"ecr-login\"' to ~/.docker/config.json"
              fi
            fi
          '';
        };
      });
}
