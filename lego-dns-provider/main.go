package main

import (
	"context"
	"crypto"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/go-acme/lego/v5/acme"
	"github.com/go-acme/lego/v5/challenge/dns01"
	"github.com/go-acme/lego/v5/providers/dns"
)

// You'll need a user or account type that implements acme.User
type Account struct {
	Email        string
	Registration *acme.ExtendedAccount
	key          crypto.Signer
}

func (u *Account) GetEmail() string {
	return u.Email
}

func (u *Account) GetRegistration() *acme.ExtendedAccount {
	return u.Registration
}

func (u *Account) GetPrivateKey() crypto.Signer {
	return u.key
}

func main() {
	flag.Parse()

	// see: https://go-acme.github.io/lego/dns/exec/#commands
	args := flag.Args()
	if len(args) != 4 {
		fmt.Printf(`usage:
		%s PROVIDER present FQDN RECORD 
		%s PROVIDER cleanup FQDN RECORD 
`, os.Args[0], os.Args[0])
		os.Exit(1)
	}

	providerName := args[0]
	operation := args[1]

	domain := args[2]
	keyAuth := args[3]

	provider, err := dns.NewDNSChallengeProviderByName(providerName)
	if err != nil {
		log.Fatal(err)
	}

	ctx := context.Background()

	info := dns01.GetChallengeInfo(ctx, domain, keyAuth)
	if err != nil {
		log.Fatal(err)
	}

	switch operation {
	case "present":
		err := provider.Present(ctx, info.Domain(), "", keyAuth)
		if err != nil {
			log.Fatal(err)
		}
	case "cleanup":
		err := provider.CleanUp(ctx, info.Domain(), "", keyAuth)
		if err != nil {
			log.Fatal(err)
		}
	default:
		log.Fatalf("unrecognized operation %v", operation)
	}
}
