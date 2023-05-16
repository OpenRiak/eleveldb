.PHONY: check clean compile cover dialyzer get-deps test xref
REBAR ?= rebar3

all: compile

check: test dialyzer xref

get-deps:
	$(REBAR) get-deps

compile: get-deps
	$(REBAR) compile

clean:
	$(REBAR) clean

cover: test
	$(REBAR) cover

test: compile
	$(REBAR) as test do eunit

dialyzer:
	$(REBAR) dialyzer

xref:
	$(REBAR) xref
