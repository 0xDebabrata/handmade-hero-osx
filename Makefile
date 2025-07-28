.PHONY: build run

build:
	@echo "building"
	mkdir -p build
	clang -g -framework Appkit -framework GameController -o build/handmade code/main.mm

run:
	@./build/handmade
