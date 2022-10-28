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

package types

import (
	"time"

	"gorm.io/gorm"
)

// Tokens - TODO comment
type Tokens struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// TokenAuthentication - TODO comment
type TokenAuthentication struct {
	TokenType string  `json:"token_type"`
	ExpiresIn float64 `json:"expires_in"`
	ExpiresOn int64   `json:"expires_on"`
	Tokens
}

type LoginBody struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type APISettings struct {
	DB                 *gorm.DB
	KV                 Store
	TLSCert            string
	TLSKey             string
	Address            string
	APISecret          string
	AccessTokenExpiry  uint
	RefreshTokenExpiry uint
	MaxDaysWoRelogin   int
	Guacamole          bool
}

type LDAPSettings struct {
	DB          *gorm.DB
	KV          Store
	TLSDisabled bool
	TLSCert     string
	TLSKey      string
	Address     string
	Domain      string
	SizeLimit   int
	Guacamole   bool
}

type Credentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// RefreshToken - TODO comment
type RefreshToken struct {
	Token string `json:"refresh_token"`
}

type APIError struct {
	Message string `json:"message"`
}

type DBInit struct {
	UseSqlite             bool
	PostgresHost          string
	PostgresPort          int
	PostgresUser          string
	PostgresPassword      string
	PostgresDatabase      string
	PostgresSSLRootCA     string
	PostgresSSLClientCert string
	PostgresSSLClientKey  string
	AdminPasswd           string
	SearchPasswd          string
	Users                 string
	DefaultPasswd         string
}

type ErrorResponse struct {
	Message string `json:"message"`
}

type Store interface {
	// Set a value for a given key
	Set(k string, v string, expiration time.Duration) error
	// Get a value from our key-value store
	Get(k string) (v string, found bool, err error)
	// Delete a key
	Delete(k string) (err error)
	// Close a connection with our key-value store
	Close() error
}

type GuacamoleSupport struct {
	Enabled bool `json:"guac_enabled"`
}
