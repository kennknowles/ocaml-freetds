if [ $TRAVIS_OS_NAME = osx ]; then
    brew unlink python
    brew install ocaml opam
    opam init --auto-setup
    eval `opam config env`
    opam pin add -yn "$PACKAGE" .
    opam install -y depext
    opam depext -y "$PACKAGE"
    opam install --deps-only -y "$PACKAGE"
    opam install -y "$EXTRA_DEPS"
else
    wget https://raw.githubusercontent.com/ocaml/ocaml-travisci-skeleton/master/.travis-docker.sh
fi
