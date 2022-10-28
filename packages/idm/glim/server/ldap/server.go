/*
Copyright © 2022 Miguel Ángel Álvarez Cabrerizo <mcabrerizo@sologitops.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ldap

import (
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"os"
	"strings"
	"sync"

	"github.com/doncicuto/glim/types"
	ber "github.com/go-asn1-ber/asn1-ber"
	"github.com/labstack/gommon/log"
)

//Settings - TODO comment

func printLog(msg string) {
	log.SetHeader("${time_rfc3339} [LDAP] ⇨")
	log.Print(msg)
}

func handleConnection(c net.Conn, settings types.LDAPSettings) {
	defer c.Close()

	var username = ""
	remoteAddress := c.RemoteAddr().String()
	printLog(fmt.Sprintf("serving LDAPS connection from %s", remoteAddress))
L:
	for {
		p, err := ber.ReadPacket(c)
		if err != nil {
			if err == io.EOF || err == io.ErrUnexpectedEOF {
				printLog(fmt.Sprintf("connection closed by client %s", remoteAddress))
				break
			}
			fmt.Println("Error", err)
			break
		}
		message, err := DecodeMessage(p)
		if err != nil {
			printLog(err.Error())
			break
		}

		switch message.Op {
		case BindRequest:
			printLog(fmt.Sprintf("bind requested by client: %s", remoteAddress))
			p, n, err := HandleBind(message, settings, remoteAddress)
			username = n
			if err != nil {
				printLog(err.Error())
			}
			_, err = c.Write(p.Bytes())
			if err != nil {
				printLog(err.Error())
			}
		case ExtendedRequest:
			p, err := HandleExtRequest(message, username)
			if err != nil {
				printLog(err.Error())
			}
			_, err = c.Write(p.Bytes())
			if err != nil {
				printLog(err.Error())
			}
		case SearchRequest:
			printLog(fmt.Sprintf("search requested by client %s", remoteAddress))
			p, err := HandleSearchRequest(message, settings)
			if err != nil {
				printLog(err.Error())
			}
			for i := 0; i < len(p); i++ {
				_, err = c.Write(p[i].Bytes())
				if err != nil {
					printLog(err.Error())
				}
			}
		case UnbindRequest:
			printLog(fmt.Sprintf("unbind requested by client: %s", remoteAddress))
		default:
			printLog(fmt.Sprintf("operation %d not supported requested by client %s", message.Op, remoteAddress))
			for i := 0; i < len(message.Request); i++ {
				fmt.Println(message.Request[i])
			}
			p, err := HandleUnsupportedOperation(message)
			if err != nil {
				printLog(err.Error())
			}
			_, err = c.Write(p.Bytes())
			if err != nil {
				printLog(err.Error())
			}
			break L
		}
	}
}

func waitForShutdown(l net.Listener, ch chan bool) {
	for range ch {
		log.SetHeader("${time_rfc3339} [Glim] ⇨")
		log.Printf("shutting down LDAPS server...")
		l.Close()
		return
	}
}

// Server - TODO comment
func Server(wg *sync.WaitGroup, shutdownChannel chan bool, settings types.LDAPSettings) {
	defer wg.Done()
	addr, ok := os.LookupEnv("LDAP_SERVER_ADDRESS")
	if !ok {
		addr = settings.Address
	}

	var err error
	var l net.Listener

	if settings.TLSDisabled {
		// Start TCP listener
		l, err = net.Listen("tcp", addr)
		if err != nil {
			log.SetHeader("${time_rfc3339} [Glim] ⇨")
			log.Fatal("")
			return
		}
		log.SetHeader("${time_rfc3339} [Glim] ⇨")
		log.Printf("starting LDAP server in address %s...", addr)
		defer l.Close()
	} else {
		// Load server certificate and private key
		cer, err := tls.LoadX509KeyPair(settings.TLSCert, settings.TLSKey)
		if err != nil {
			log.SetHeader("${time_rfc3339} [Glim] ⇨")
			log.Fatal("could not load server certificate and private key pair")
			return
		}

		// Start TLS listener
		config := &tls.Config{Certificates: []tls.Certificate{cer}}
		l, err = tls.Listen("tcp", addr, config)
		if err != nil {
			log.SetHeader("${time_rfc3339} [Glim] ⇨")
			log.Fatal("")
			return
		}
		log.SetHeader("${time_rfc3339} [Glim] ⇨")
		log.Printf("starting LDAPS server in address %s...", addr)
		defer l.Close()
	}

	// Handle LDAP connections in a for loop
	for {
		// Wait for shutdown signals and close our TLS listener
		// TODO: In a future revision we could wait for servers
		// termination before closing our listener
		go waitForShutdown(l, shutdownChannel)

		// Accept new connections
		c, err := l.Accept()
		if err != nil {
			if !strings.Contains(err.Error(), "use of closed network connection") {
				log.SetHeader("${time_rfc3339} [Glim] ⇨")
				log.Printf("an error occurred accepting connections...")
			}
			return
		}

		// Handle our server connection
		go handleConnection(c, settings)
	}
}
