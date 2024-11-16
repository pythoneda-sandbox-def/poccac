# poccac/flake.nix
#
# This file defines a nix flake for poccac-0.0.0.
#
# GNU GENERAL PUBLIC LICENSE
# Version 3, 29 June 2007
#
# Copyright (C) 2024-today rydnr https://github.com/pythoneda-sandbox/poccac
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
{
  description = "Proof of concept for code-as-code";
  inputs = rec {
    flake-utils = { url = "github:numtide/flake-utils/v1.0.0"; };
    nixos = { url = "github:NixOS/nixpkgs/24.05"; };
    pythoneda-shared-git-github = {
      url = "github:pythoneda-shared-git-def/github/0.0.16";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
    };
    pythoneda-shared-git-shared = {
      url = "github:pythoneda-shared-git-def/shared/0.0.54";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
    };
    pythoneda-shared-pythonlang-banner = {
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.61";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
    };
    pythoneda-shared-pythonlang-domain = {
      url = "github:pythoneda-shared-pythonlang-def/domain/0.0.64";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
    };
    stringtemplate3 = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/nix-flakes/stringtemplate3-3.1b?dir=stringtemplate3";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "pythoneda-sandbox";
        repo = "poccac";
        version = "0.0.0";
        sha256 = "0vap6rwiawn5lxnf9bx854jqypy1ycpf348kxk3jj40sh99fkpfi";
        pname = "${org}-${repo}";
        pythonpackage = "pythoneda.sandbox.poc.cac";
        package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
        entrypoint = "poccac_app";
        description = "Proof of concept for code-as-code";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        archRole = "B";
        space = "D";
        layer = "D";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixos-${nixosVersion}";
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        pkgs = import nixos { inherit system; };
        pythoneda-sandbox-poccac-for = { python, pythoneda-shared-git-github
          , pythoneda-shared-git-shared, pythoneda-shared-pythonlang-banner
          , pythoneda-shared-pythonlang-domain, stringtemplate3 }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
            banner_file = "${package}/poccac_banner.py";
            banner_class = "poccacBanner";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTomlTemplate = ./templates/pyproject.toml.template;
            pyprojectToml = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              hypothesis = python.pkgs.hypothesis.version;
              inherit homepage pname pythonMajorMinorVersion pythonpackage
                version;
              pythonedaSharedGitGithub = pythoneda-shared-git-github.version;
              pythonedaSharedGitShared = pythoneda-shared-git-shared.version;
              pythonedaSharedPythonlangBanner =
                pythoneda-shared-pythonlang-banner.version;
              pythonedaSharedPythonlangDomain =
                pythoneda-shared-pythonlang-domain.version;
              pytest = python.pkgs.pytest.version;
              pytestAsyncio = python.pkgs.pytest-asyncio.version;
              package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
              src = pyprojectTomlTemplate;
              stringtemplate3 = stringtemplate3.version;
            };
            bannerTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/banner.py.template";
            bannerTemplate = pkgs.substituteAll {
              project_name = pname;
              file_path = banner_file;
              inherit banner_class org repo;
              tag = version;
              pescio_space = space;
              arch_role = archRole;
              hexagonal_layer = layer;
              python_version = pythonMajorMinorVersion;
              nixpkgs_release = nixpkgsRelease;
              src = bannerTemplateFile;
            };

            entrypointTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/entrypoint.sh.template";
            entrypointTemplate = pkgs.substituteAll {
              arch_role = archRole;
              hexagonal_layer = layer;
              nixpkgs_release = nixpkgsRelease;
              inherit homepage maintainers org python repo version;
              pescio_space = space;
              python_version = pythonMajorMinorVersion;
              pythoneda_shared_pythonlang_banner =
                pythoneda-shared-pythonlang-banner;
              pythoneda_shared_pythonlang_domain =
                pythoneda-shared-pythonlang-domain;
              src = entrypointTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              hypothesis
              pytest
              pytest-asyncio
              pythoneda-shared-git-github
              pythoneda-shared-git-shared
              pythoneda-shared-pythonlang-banner
              pythoneda-shared-pythonlang-domain
              stringtemplate3
            ];

            # pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              find $sourceRoot -type d -exec chmod 777 {} \;
              cp ${pyprojectToml} $sourceRoot/pyproject.toml
              cp ${bannerTemplate} $sourceRoot/${banner_file}
              cp ${entrypointTemplate} $sourceRoot/entrypoint.sh
            '';

            postPatch = ''
              substituteInPlace /build/$sourceRoot/entrypoint.sh \
                --replace "@SOURCE@" "$out/bin/${entrypoint}.sh" \
                --replace "@PYTHONPATH@" "$PYTHONPATH:$out/lib/python${pythonMajorMinorVersion}/site-packages" \
                --replace "@CUSTOM_CONTENT@" "" \
                --replace "@ENTRYPOINT@" "$out/lib/python${pythonMajorMinorVersion}/site-packages/${package}/application/${entrypoint}.py" \
                --replace "@BANNER@" "$out/bin/banner.sh"
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist $out/bin
              cp dist/${wheelName} $out/dist
              cp /build/$sourceRoot/entrypoint.sh $out/bin/${entrypoint}.sh
              chmod +x $out/bin/${entrypoint}.sh
              echo '#!/usr/bin/env sh' > $out/bin/banner.sh
              echo "export PYTHONPATH=$PYTHONPATH" >> $out/bin/banner.sh
              echo "${python}/bin/python $out/lib/python${pythonMajorMinorVersion}/site-packages/${banner_file} \$@" >> $out/bin/banner.sh
              chmod +x $out/bin/banner.sh
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = poccac-default;
          poccac-default = pythoneda-sandbox-poccac-python312;
          pythoneda-sandbox-poccac-python38 = shared.app-for {
            package = self.packages.${system}.pythoneda-sandbox-poccac-python38;
            inherit entrypoint;
          };
          pythoneda-sandbox-poccac-python39 = shared.app-for {
            package = self.packages.${system}.pythoneda-sandbox-poccac-python39;
            inherit entrypoint;
          };
          pythoneda-sandbox-poccac-python310 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-sandbox-poccac-python310;
            inherit entrypoint;
          };
          pythoneda-sandbox-poccac-python311 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-sandbox-poccac-python311;
            inherit entrypoint;
          };
          pythoneda-sandbox-poccac-python312 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-sandbox-poccac-python312;
            inherit entrypoint;
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-sandbox-poccac-default;
          pythoneda-sandbox-poccac-default = pythoneda-sandbox-poccac-python312;
          pythoneda-sandbox-poccac-python38 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-poccac-python38;
            python = pkgs.python38;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-poccac-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-poccac-python39;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-poccac-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-poccac-python310;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-poccac-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-poccac-python311;
            python = pkgs.python311;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-poccac-python312 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-poccac-python312;
            python = pkgs.python312;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = pythoneda-sandbox-poccac-default;
          pythoneda-sandbox-poccac-default = pythoneda-sandbox-poccac-python312;
          pythoneda-sandbox-poccac-python38 = pythoneda-sandbox-poccac-for {
            python = pkgs.python38;
            pythoneda-shared-git-github =
              pythoneda-shared-git-github.packages.${system}.pythoneda-shared-git-github-python38;
            pythoneda-shared-git-shared =
              pythoneda-shared-git-shared.packages.${system}.pythoneda-shared-git-shared-python38;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            stringtemplate3 =
              stringtemplate3.packages.${system}.stringtemplate3-python38;
          };
          pythoneda-sandbox-poccac-python39 = pythoneda-sandbox-poccac-for {
            python = pkgs.python39;
            pythoneda-shared-git-github =
              pythoneda-shared-git-github.packages.${system}.pythoneda-shared-git-github-python39;
            pythoneda-shared-git-shared =
              pythoneda-shared-git-shared.packages.${system}.pythoneda-shared-git-shared-python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            stringtemplate3 =
              stringtemplate3.packages.${system}.stringtemplate3-python39;
          };
          pythoneda-sandbox-poccac-python310 = pythoneda-sandbox-poccac-for {
            python = pkgs.python310;
            pythoneda-shared-git-github =
              pythoneda-shared-git-github.packages.${system}.pythoneda-shared-git-github-python310;
            pythoneda-shared-git-shared =
              pythoneda-shared-git-shared.packages.${system}.pythoneda-shared-git-shared-python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            stringtemplate3 =
              stringtemplate3.packages.${system}.stringtemplate3-python310;
          };
          pythoneda-sandbox-poccac-python311 = pythoneda-sandbox-poccac-for {
            python = pkgs.python311;
            pythoneda-shared-git-github =
              pythoneda-shared-git-github.packages.${system}.pythoneda-shared-git-github-python311;
            pythoneda-shared-git-shared =
              pythoneda-shared-git-shared.packages.${system}.pythoneda-shared-git-shared-python311;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            stringtemplate3 =
              stringtemplate3.packages.${system}.stringtemplate3-python311;
          };
          pythoneda-sandbox-poccac-python312 = pythoneda-sandbox-poccac-for {
            python = pkgs.python312;
            pythoneda-shared-git-github =
              pythoneda-shared-git-github.packages.${system}.pythoneda-shared-git-github-python312;
            pythoneda-shared-git-shared =
              pythoneda-shared-git-shared.packages.${system}.pythoneda-shared-git-shared-python312;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            stringtemplate3 =
              stringtemplate3.packages.${system}.stringtemplate3-python312;
          };
        };
      });
}
