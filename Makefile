.PHONY: run build android clean test fmt lint setup

# Run locally (desktop)
run:
	go run .

# Build desktop binary
build:
	go build -o zrokapp.exe .

# Build Android APK (requires fyne tool + Android SDK)
android:
	fyne package -os android -appID com.zrokapp -name "Zrok Mobile"

# Run tests
test:
	go test ./...

# Clean
clean:
	rm -f zrokapp.exe
	rm -f ZrokMobile.apk

# Format
fmt:
	go fmt ./...

# Lint
lint:
	go vet ./...

# Install fyne CLI tool (first-time)
setup:
	go install fyne.io/fyne/v2/cmd/fyne@latest
