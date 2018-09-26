all: build

build:
	@jbuilder build @install @test

clean:
	@jbuilder clean
	@$(RM) **/.merlin

install:
	@jbuilder install

test:
	@jbuilder runtest --force

doc:
	@jbuilder build @doc

.PHONY: all build clean install test doc
