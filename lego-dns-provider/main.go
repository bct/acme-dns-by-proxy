package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/go-acme/lego/v5/providers/dns"
	"log"
	"os"
)

func runProvider(providerName, operation, domain, token, keyAuth string) error {
	provider, err := dns.NewDNSChallengeProviderByName(providerName)
	if err != nil {
		return err
	}

	ctx := context.Background()
	switch operation {
	case "present":
		err := provider.Present(ctx, domain, "", keyAuth)
		if err != nil {
			return err
		}
	case "cleanup":
		err := provider.CleanUp(ctx, domain, "", keyAuth)
		if err != nil {
			return err
		}
	default:
		return fmt.Errorf("unrecognized operation %v", operation)
	}

	return nil
}

func main() {
	flag.Parse()

	// we accept the same arguments as the "External Program" provider, in RAW mode.
	// see: https://go-acme.github.io/lego/dns/exec/#commands
	origArgs := flag.Args()

	// ignore "--" in the argument list.
	// lego RAW mode adds this in; it's irrelevant since we don't accept any arguments anyhow.
	args := make([]string, 0, len(origArgs))
	for _, arg := range origArgs {
		if arg != "--" {
			args = append(args, arg)
		}
	}

	if len(args) != 5 {
		fmt.Printf(`usage:
		%s PROVIDER present DOMAIN TOKEN RECORD
		%s PROVIDER cleanup DOMAIN TOKEN RECORD
`, os.Args[0], os.Args[0])
		os.Exit(1)
	}

	// https://go-acme.github.io/lego/dns/index.html
	providerName := args[0]

	// "present" or "cleanup"
	operation := args[1]

	// your-domain.example.
	domain := args[2]

	// not used for DNS-01 challenges?
	token := args[3]

	// an opaque string
	keyAuth := args[4]

	err := runProvider(providerName, operation, domain, token, keyAuth)
	if err != nil {
		log.Fatal(err)
	}
}
