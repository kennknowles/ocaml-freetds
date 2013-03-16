# Hacking the build into Travis-CI "C" environment
# based on http://blog.mlin.net/2013/02/testing-ocaml-projects-on-travis-ci.html
# but using binary packages from http://opam.ocamlpro.com/doc/Quick_Install.html

export OPAM_PACKAGES='ocamlfind'

# Install OCaml
sudo apt-get update -qq
sudo apt-get install -qq ocaml

# Install opam
echo "deb http://www.recoil.org/~avsm/ wheezy main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install opam

opam init --auto-setup
eval `opam config -env`
popd

# Install any ocaml packages
opam install "${OPAM_PACKAGES}"

# Install freetds
sudo apt-get install freetds

