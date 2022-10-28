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

// Copyright 2019 Meter, Inc.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// This project is based in part off of src/crypto/tls/generate_cert.go, a file
// available in the Go source code. The license for that file is available here:

// Copyright (c) 2009 The Go Authors. All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:

//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package cmd

import (
	"bytes"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"math/big"
	"net"
	"time"
)

type cert struct {
	Private *pem.Block
	Public  *pem.Block

	PrivateBytes []byte
	PublicBytes  []byte
}

// Config stores information to be used in our certificate generation requests
type certConfig struct {
	CA           string
	Organization string
	Hosts        []string
	OutputPath   string
	Years        int
}

func writeCert(c *cert, path string, filename string) error {
	pubkey := fmt.Sprintf("%s/%s.pem", path, filename)
	if err := ioutil.WriteFile(pubkey, c.PublicBytes, 0644); err != nil {
		return err
	}
	fmt.Printf("⇨ Certificate file: %s.pem\n", filename)

	privkey := fmt.Sprintf("%s/%s.key", path, filename)
	if err := ioutil.WriteFile(privkey, c.PrivateBytes, 0600); err != nil {
		return err
	}
	fmt.Printf("⇨ Private key file: %s.key\n", filename)

	return nil
}

func genCert(leaf *x509.Certificate, parent *x509.Certificate, key *ecdsa.PrivateKey, caPrivKey *ecdsa.PrivateKey) (*cert, error) {
	cert := new(cert)
	derBytes, err := x509.CreateCertificate(rand.Reader, leaf, parent, &key.PublicKey, caPrivKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create certificate: %v", err)
	}
	cert.Public = &pem.Block{Type: "CERTIFICATE", Bytes: derBytes}
	buf := new(bytes.Buffer)
	if err := pem.Encode(buf, cert.Public); err != nil {
		return nil, fmt.Errorf("failed to write data to cert.pem: %v", err)
	}
	cert.PublicBytes = make([]byte, buf.Len())
	copy(cert.PublicBytes, buf.Bytes())
	buf.Reset()

	b, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		return nil, fmt.Errorf("unable to marshal ECDSA private key: %v", err)
	}
	cert.Private = &pem.Block{Type: "EC PRIVATE KEY", Bytes: b}
	if err := pem.Encode(buf, cert.Private); err != nil {
		return nil, fmt.Errorf("failed to encode key data: %v", err)
	}
	cert.PrivateBytes = make([]byte, buf.Len())
	copy(cert.PrivateBytes, buf.Bytes())
	return cert, nil
}

// Generate rootCA, server and client certificate
func generateSelfSignedCerts(config *certConfig) error {
	serialNumberLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		return fmt.Errorf("failed to generate serial number: %v", err)
	}
	notBefore := time.Now()
	notAfter := notBefore.AddDate(config.Years, 0, 0)

	rootTemplate := x509.Certificate{
		IsCA:                  true,
		SerialNumber:          serialNumber,
		Subject:               pkix.Name{Organization: []string{config.CA}},
		NotBefore:             notBefore,
		NotAfter:              notAfter,
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageClientAuth},
		BasicConstraintsValid: true,
	}

	serverSerialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		log.Fatalf("failed to generate serial number: %v", err)
	}
	serverTemplate := x509.Certificate{
		IsCA:                  false,
		SerialNumber:          serverSerialNumber,
		Subject:               pkix.Name{Organization: []string{config.Organization}},
		NotBefore:             notBefore,
		NotAfter:              notAfter,
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
	}

	clientSerialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		log.Fatalf("failed to generate serial number: %v", err)
	}
	clientTemplate := x509.Certificate{
		IsCA:                  false,
		SerialNumber:          clientSerialNumber,
		Subject:               pkix.Name{Organization: []string{config.Organization}},
		NotBefore:             notBefore,
		NotAfter:              notAfter,
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth},
		BasicConstraintsValid: true,
	}

	for _, h := range config.Hosts {
		if ip := net.ParseIP(h); ip != nil {
			serverTemplate.IPAddresses = append(serverTemplate.IPAddresses, ip)
			clientTemplate.IPAddresses = append(clientTemplate.IPAddresses, ip)
		} else {
			serverTemplate.DNSNames = append(serverTemplate.DNSNames, h)
			clientTemplate.DNSNames = append(clientTemplate.DNSNames, h)
		}
	}

	fmt.Println("\nCreating a CA certificate file and private key file...")
	caPrivKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return err
	}
	rootCA, err := genCert(&rootTemplate, &rootTemplate, caPrivKey, caPrivKey)
	if err != nil {
		return err
	}
	if err = writeCert(rootCA, config.OutputPath, "ca"); err != nil {
		return err
	}

	fmt.Println("\nCreating a server certificate file and private key file...")
	serverPrivKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return err
	}
	server, err := genCert(&serverTemplate, &rootTemplate, serverPrivKey, caPrivKey)
	if err != nil {
		return err
	}
	if err = writeCert(server, config.OutputPath, "server"); err != nil {
		return err
	}

	fmt.Println("\nCreating a client certificate file and private key file...")
	clientPrivKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return err
	}
	client, err := genCert(&clientTemplate, &rootTemplate, clientPrivKey, caPrivKey)
	if err != nil {
		return err
	}
	if err = writeCert(client, config.OutputPath, "client"); err != nil {
		return err
	}

	fmt.Printf("\nFinished! All your certificates and keys should be at %s\n", config.OutputPath)

	return nil
}
