
BIN=./bin

# go
install_go:
	$(BIN)/install-go

uninstall_go:
	sudo rm -frv /usr/local/go

go: uninstall_go install_go
