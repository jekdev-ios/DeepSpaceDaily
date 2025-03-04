.PHONY: build clean

# Default target
all: build

# Build the project
build:
	@echo "Building DeepSpaceDaily..."
	@./build.sh

# Clean the build directory
clean:
	@echo "Cleaning build directory..."
	@rm -rf ~/Library/Developer/Xcode/DerivedData/DeepSpaceDaily-*

# Run the app in the simulator
run: build
	@echo "Running DeepSpaceDaily in simulator..."
	@xcrun simctl launch booted spaceNewsApp.DeepSpaceDaily

# Help command
help:
	@echo "DeepSpaceDaily Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  make build    - Build the project"
	@echo "  make clean    - Clean the build directory"
	@echo "  make run      - Build and run the app in the simulator"
	@echo "  make help     - Show this help message"
	@echo "" 