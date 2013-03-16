# Hacking the build into Travis-CI "C" environment
# based on http://blog.mlin.net/2013/02/testing-ocaml-projects-on-travis-ci.html
# but tried using binary packages from http://opam.ocamlpro.com/doc/Quick_Install.html
# they seem to be down at the moment and maybe we only need ocaml-findlib that debian does have...

export OPAM_PACKAGES='ocamlfind'

# Install OCaml
sudo apt-get update -qq
sudo apt-get install -qq ocaml

# Install ocaml-findlib
sudo apt-get install -qq ocaml-findlib

# Install opam
#echo "deb http://www.recoil.org/~avsm/ wheezy main" | sudo tee -a /etc/apt/sources.list
#sudo apt-get update
#sudo apt-get install opam
#opam init --auto-setup
#eval `opam config -env`
#popd

# Install any ocaml packages
#opam install "${OPAM_PACKAGES}"

# Install freetds
sudo apt-get install freetds

