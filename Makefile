all: build

build:
	@jbuilder build @install

clean:
	@jbuilder clean
	@$(RM) **/.merlin

install:
	@jbuilder install

test:
	@jbuilder runtest --force

.PHONY: all build clean install test
