if [[ "$TRAVIS_OS_NAME" = osx ]]; then
    eval `opam config env`
    make
    make test
else
    bash -ex ./.travis-docker.sh
fi