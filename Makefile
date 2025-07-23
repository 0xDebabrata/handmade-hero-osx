.PHONY: build

build:
	@echo "building"
	mkdir -p build
	clang -g -framework Appkit -o build/handmade code/main.mm
