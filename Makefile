all: build

build:
	@jbuilder build @install

clean:
	@jbuilder clean
	@$(RM) **/.merlin

install:
	@jbuilder install

test:
	@jbuilder runtest

.PHONY: all build clean install test
