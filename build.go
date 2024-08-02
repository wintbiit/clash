package main

import (
	"bufio"
	"io"
	"log"
	"net/http"
	"os"
	"path"
	"strings"
)

const (
	CaddyMainRawFileUrl = "https://raw.githubusercontent.com/caddyserver/caddy/master/cmd/caddy/main.go"
	CaddyMainPluginLine = 35
)

func main() {
	os.Mkdir("out", 0o755)

	mainFile := saveMainFile()
	defer mainFile.Close()

	modules := scanModules()
	insertModules(mainFile, modules)
}

func scanModules() []string {
	modules, err := os.Open("modules")
	if err != nil {
		log.Fatal(err)
	}

	defer modules.Close()

	moduleNames := make([]string, 0)

	scanner := bufio.NewScanner(modules)
	for scanner.Scan() {
		mod := scanner.Text()
		mod = strings.TrimSpace(mod)
		moduleNames = append(moduleNames, mod)
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	return moduleNames
}

func saveMainFile() *os.File {
	mainFile, err := os.OpenFile(path.Join("out", "main.go"), os.O_CREATE|os.O_TRUNC|os.O_RDWR, 0o644)
	if err != nil {
		log.Fatal(err)
	}

	resp, err := http.Get(CaddyMainRawFileUrl)
	if err != nil {
		log.Fatal(err)
	}

	defer resp.Body.Close()

	_, err = io.Copy(mainFile, resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	return mainFile
}

func insertModules(f *os.File, modules []string) {
	_, err := f.Seek(0, 0)
	if err != nil {
		log.Fatal(err)
	}

	// insert modules after the plugin line
	lines := make([]string, 0)
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		lines = append(lines, line)
		if len(lines) == CaddyMainPluginLine {
			for _, mod := range modules {
				lines = append(lines, "\t_ \""+mod+"\"")
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	_, err = f.Seek(0, 0)

	if err != nil {
		log.Fatal(err)
	}

	f.Truncate(0)

	for _, line := range lines {
		_, err = f.WriteString(line + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}
}
