# Hacking the build into Travis-CI "C" environment
# based on http://blog.mlin.net/2013/02/testing-ocaml-projects-on-travis-ci.html
# but tried using binary packages from http://opam.ocamlpro.com/doc/Quick_Install.html
# they seem to be down at the moment and maybe we only need ocaml-findlib that debian does have...

if [ $TRAVIS_OS_NAME = osx ]; then
    brew unlink python
    brew install ocaml opam
fi

# Setup opam
opam init --auto-setup
eval `opam config env`

# Install OCaml dependencies
opam pin add -yn freetds .
opam install -y depext
opam depext -y freetds
opam install --deps-only -y freetds
