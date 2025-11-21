{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }:
		let
			supportedSystems = nixpkgs.lib.platforms.all;
			devShells = 
				nixpkgs.lib.genAttrs supportedSystems (system: 
				let
					pkgs = import nixpkgs { inherit system; };
					inherit (pkgs) stdenv;
				in 
				{
					default = pkgs.mkShell {
						buildInputs = [
							pkgs.elixir
							pkgs.watchman
							# pkgs.inotify-tools
						];

						shellHook = ''
							echo "Elixir version: $(elixir --version)"
						'';
					};
				}
			);
		in
		let
			supportedSystems = nixpkgs.lib.platforms.all;
			packages = {};
		in
		{
			inherit devShells packages;
		};
}
