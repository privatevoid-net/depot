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

package cmd

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/doncicuto/glim/server/kv/badgerdb"
	"github.com/doncicuto/glim/server/kv/redis"
	"github.com/doncicuto/glim/server/ldap"
	"github.com/doncicuto/glim/types"

	"github.com/doncicuto/glim/server/api"
	"github.com/doncicuto/glim/server/db"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// serverCmd represents the server command
var serverStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a Glim server",
	Run: func(_ *cobra.Command, _ []string) {
		// Check if API secret is present in env variable
		apiSecret := viper.GetString("api-secret")
		if apiSecret == "" {
			fmt.Printf("%s [Glim] ⇨ could not find required api secret. Exiting now...\n", time.Now().Format(time.RFC3339))
			os.Exit(1)
		}

		tlscert := viper.GetString("tlscert")
		tlskey := viper.GetString("tlskey")

		_, errCert := os.Stat(tlscert)
		_, errKey := os.Stat(tlskey)

		if os.IsNotExist(errCert) && os.IsNotExist(errKey) {
			var config = certConfig{}

			fmt.Println("Oh, I can't find your certificates and private keys, don't worry I'll create some for you.")

			// organization cannot be empty
			ca := viper.GetString("autocert-ca")
			if ca == "" {
				fmt.Println("CA name cannot be empty")
				os.Exit(1)
			}
			config.CA = ca

			// organization cannot be empty
			organization := viper.GetString("autocert-org")
			if organization == "" {
				fmt.Println("Organization name cannot be empty")
				os.Exit(1)
			}
			config.Organization = organization

			// address list cannot be empty
			hosts := strings.Split(viper.GetString("autocert-hosts"), ",")
			if len(hosts) == 0 {
				fmt.Println("Please specify a comma-separated list of hosts and/or IP addresses to be added to certificates")
				os.Exit(1)
			}
			config.Hosts = hosts

			path := viper.GetString("autocert-path")
			err := os.MkdirAll(path, 0755)
			if err != nil {
				fmt.Println("Could not create selected directory for certificates path")
				os.Exit(1)
			}
			config.OutputPath = path

			// years should be greater than 0
			years := viper.GetInt("autocert-years")
			if years < 1 {
				fmt.Println("Certificate should be valid for at least 1 year")
				os.Exit(1)
			}
			config.Years = years

			// create our certificates signed by our fake CA
			err = generateSelfSignedCerts(&config)
			if err != nil {
				fmt.Printf("Could not generate our certificates. Error: %v\n", err)
			}
		} else {
			// Check if certificate file path exists
			if _, err := os.Stat(tlscert); os.IsNotExist(err) {
				fmt.Printf("%s [Glim] ⇨ Certificate file %s cannot be found. Exiting now...\n", time.Now().Format(time.RFC3339), tlscert)
				os.Exit(1)
			}

			// Check if private key file path exists
			if _, err := os.Stat(tlskey); os.IsNotExist(err) {
				fmt.Printf("%s [Glim] ⇨ Private key file %s cannot be found. Exiting now...\n", time.Now().Format(time.RFC3339), tlskey)
				os.Exit(1)
			}
		}

		// Database
		dbName := viper.GetString("sqlite-db")
		sqlLog := viper.GetBool("log-sql")
		useSqlite := true

		postgresPort := viper.GetInt("postgres-port")
		if viper.GetString("postgres-host") != "" {
			useSqlite = false
			dbName = viper.GetString("postgres-db")
			if postgresPort <= 0 || postgresPort > 65535 {
				fmt.Printf("%s [Glim] ⇨ wrong PostgreSQL port. Exiting now...\n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
		}

		postgresSSLRootCa := viper.GetString("postgres-root-ca")
		if postgresSSLRootCa != "" {
			if _, err := os.Stat(postgresSSLRootCa); os.IsNotExist(err) {
				if err != nil {
					fmt.Printf("%s [Glim] ⇨ can't find PostgreSQL Root CA pem file. Exiting now...\n", time.Now().Format(time.RFC3339))
					os.Exit(1)
				}
			}
		}

		postgresSSLClientCert := viper.GetString("postgres-client-cert")
		if postgresSSLRootCa != "" {
			if _, err := os.Stat(postgresSSLRootCa); os.IsNotExist(err) {
				if err != nil {
					fmt.Printf("%s [Glim] ⇨ can't find PostgreSQL client certificate file. Exiting now...\n", time.Now().Format(time.RFC3339))
					os.Exit(1)
				}
			}
		}

		postgresSSLClientKey := viper.GetString("postgres-client-key")
		if postgresSSLRootCa != "" {
			if _, err := os.Stat(postgresSSLRootCa); os.IsNotExist(err) {
				if err != nil {
					fmt.Printf("%s [Glim] ⇨ can't find PostgreSQL client private key file. Exiting now...\n", time.Now().Format(time.RFC3339))
					os.Exit(1)
				}
			}
		}

		var dbInit = types.DBInit{
			AdminPasswd:           viper.GetString("initial-admin-passwd"),
			SearchPasswd:          viper.GetString("initial-search-passwd"),
			Users:                 viper.GetString("initial-users"),
			DefaultPasswd:         viper.GetString("initial-users-password"),
			UseSqlite:             useSqlite,
			PostgresHost:          viper.GetString("postgres-host"),
			PostgresPort:          postgresPort,
			PostgresDatabase:      viper.GetString("postgres-db"),
			PostgresUser:          viper.GetString("postgres-user"),
			PostgresPassword:      viper.GetString("postgres-password"),
			PostgresSSLRootCA:     postgresSSLRootCa,
			PostgresSSLClientCert: postgresSSLClientCert,
			PostgresSSLClientKey:  postgresSSLClientKey,
		}

		database, err := db.Initialize(dbName, sqlLog, dbInit)
		if err != nil {
			fmt.Printf("%s [Glim] ⇨ could not connect to database. %v. Exiting now...\n", time.Now().Format(time.RFC3339), err)
			os.Exit(1)
		}
		defer func() {
			fmt.Printf("%s [Glim] ⇨ closing connection to database...\n", time.Now().Format(time.RFC3339))
		}()
		fmt.Printf("%s [Glim] ⇨ connected to database...\n", time.Now().Format(time.RFC3339))

		// Key-value store for JWT tokens storage
		var blacklist types.Store

		badgerKV := viper.GetString("badgerdb-store")
		redisHost := viper.GetString("redis-host")

		if redisHost != "" {
			redisPort := viper.GetInt("redis-port")
			if redisPort <= 0 || redisPort > 65535 {
				fmt.Printf("%s [Glim] ⇨ wrong Redis port. Exiting now...\n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
			redisPassword := viper.GetString("redis-password")
			redisDBIndex := viper.GetInt("redis-db-index")

			blacklist, err = redis.NewRedisStore(redisHost, redisPort, redisPassword, redisDBIndex)
			if err != nil {
				fmt.Printf("%s [Glim] ⇨ could not operate with Redis store. Exiting now...\n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
		} else {
			blacklist, err = badgerdb.NewBadgerStore(badgerKV)
			if err != nil {
				fmt.Printf("%s [Glim] ⇨ could not connect to Badger key-value store. Exiting now...\n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
		}

		defer func() {
			fmt.Printf("%s [Glim] ⇨ closing connection to key-value store...\n", time.Now().Format(time.RFC3339))
			blacklist.Close()
		}()
		fmt.Printf("%s [Glim] ⇨ connected to key-value store...\n", time.Now().Format(time.RFC3339))

		restAddress := viper.GetString("api-addr")

		if viper.GetBool("guacamole") {
			fmt.Printf("%s [Glim] ⇨ enabled support for Apache Guacamole...\n", time.Now().Format(time.RFC3339))
		}
		// Preparing API server settings
		apiSettings := types.APISettings{
			DB:                 database,
			KV:                 blacklist,
			TLSCert:            tlscert,
			TLSKey:             tlskey,
			Address:            restAddress,
			APISecret:          apiSecret,
			AccessTokenExpiry:  viper.GetUint("api-access-token-expiry-time"),
			RefreshTokenExpiry: viper.GetUint("api-refresh-token-expiry-time"),
			MaxDaysWoRelogin:   viper.GetInt("api-max-days-relogin"),
			Guacamole:          viper.GetBool("guacamole"),
		}

		ldapAddress := viper.GetString("ldap-addr")
		ldapSizeLimit := viper.GetInt("ldap-size-limit")
		domain := viper.GetString("ldap-domain")

		// Preparing LDAP server settings
		ldapSettings := types.LDAPSettings{
			KV:          blacklist,
			DB:          database,
			TLSDisabled: viper.GetBool("ldap-no-tls"),
			TLSCert:     tlscert,
			TLSKey:      tlskey,
			Address:     ldapAddress,
			Domain:      ldap.GetDomain(domain),
			SizeLimit:   ldapSizeLimit,
			Guacamole:   viper.GetBool("guacamole"),
		}

		// get current PID and store it in glim.pid at our tmp directory
		pid := os.Getpid()
		pidFile := filepath.FromSlash(fmt.Sprintf("%s/glim.pid", os.TempDir()))
		err = ioutil.WriteFile(pidFile, []byte(strconv.Itoa(pid)), 0644)
		if err != nil {
			fmt.Printf("%s [Glim] ⇨ could not store PID in glim.pid. Exiting now...\n", time.Now().Format(time.RFC3339))
			os.Exit(1)
		}

		// Create channels to recieve termination signals and
		// communicate shutdown to servers
		ch := make(chan os.Signal, 1)
		apiShutdownChannel := make(chan bool)
		ldapShutdownChannel := make(chan bool)
		// We listen for the following signals
		signal.Notify(ch, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

		// Start go routines for both REST and LDAP servers...
		// and add them to a waitgroup
		wg := new(sync.WaitGroup)
		wg.Add(1)
		go api.Server(wg, apiShutdownChannel, apiSettings)
		wg.Add(1)
		go ldap.Server(wg, ldapShutdownChannel, ldapSettings)

		// Blocking wait for server stop signal
		<-ch

		// Send a signal to shutdown both servers
		apiShutdownChannel <- true
		ldapShutdownChannel <- true

		// Wait for both servers to finish
		wg.Wait()
	},
}

func init() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
		os.Exit(1)
	}
	path := fmt.Sprintf("%s/.glim", homeDir)

	defaultCertPEMFilePath := filepath.Join(homeDir, ".glim", "server.pem")
	defaultCertKeyFilePath := filepath.Join(homeDir, ".glim", "server.key")
	defaultDbPath := filepath.Join(homeDir, ".glim", "glim.db")

	// LDAP Server
	serverStartCmd.Flags().Bool("ldap-no-tls", false, "Don't use TLS with LDAP server")
	serverStartCmd.Flags().String("ldap-addr", ":1636", "LDAP server address and port (format: <ip:port>)")
	serverStartCmd.Flags().Int("ldap-size-limit", 500, "LDAP server maximum number of entries that should be returned from the search")
	serverStartCmd.Flags().String("ldap-domain", "example.org", "LDAP domain")

	// REST API
	serverStartCmd.Flags().String("api-addr", ":1323", "REST API server address and port (format: <ip:port>)")
	serverStartCmd.Flags().String("api-secret", "", "API secret string to be used with JWT tokens")
	serverStartCmd.Flags().Uint("api-access-token-expiry-time", 3600, "access token refresh expiry time in seconds")
	serverStartCmd.Flags().Uint("api-refresh-token-expiry-time", 259200, "refresh token refresh expiry time in seconds")
	serverStartCmd.Flags().Int("api-max-days-relogin", 7, "number of days that we can use refresh tokens without log in again")

	// TLS
	serverStartCmd.Flags().String("tlscert", defaultCertPEMFilePath, "TLS server certificate path")
	serverStartCmd.Flags().String("tlskey", defaultCertKeyFilePath, "TLS server private key path")
	serverStartCmd.Flags().String("autocert-ca", "Acme Co Fake CA", "Name for our fake CA for auto-generated certificates")
	serverStartCmd.Flags().String("autocert-org", "Glim Fake Organization, Inc", "organization name for Glim's auto-generated certificates")
	serverStartCmd.Flags().String("autocert-hosts", "127.0.0.1, localhost", "comma-separated list of hosts and IP addresses to be added to Glim's auto-generated certificate")
	serverStartCmd.Flags().String("autocert-path", path, "filesystem path where Glim's auto-generated certificates and private keys files will be created")
	serverStartCmd.Flags().Int("autocert-years", 1, "number of years that we want Glim's auto-generated to be valid.")

	// Badger
	serverStartCmd.Flags().String("badgerdb-store", "/tmp/kv", "directory path for BadgerDB KV store")

	// SQLite
	serverStartCmd.Flags().String("sqlite-db", defaultDbPath, "path of the file containing SQLite Glim's database")

	// Postgres
	serverStartCmd.Flags().String("postgres-host", "", "PostgreSQL server address")
	serverStartCmd.Flags().Int("postgres-port", 5432, "PostgreSQL server port")
	serverStartCmd.Flags().String("postgres-user", "postgres", "PostgreSQL user")
	serverStartCmd.Flags().String("postgres-password", "", "PostgreSQL password")
	serverStartCmd.Flags().String("postgres-db", "glim", "name for Glim's database to be stored in PostgreSQL")
	serverStartCmd.Flags().String("postgres-root-ca", "", "path of the file containing PostgreSQL CA pem file")
	serverStartCmd.Flags().String("postgres-client-cert", "", "path of the file containing PostgreSQL client certificate pem file")
	serverStartCmd.Flags().String("postgres-client-key", "", "path of the file containing PostgreSQL client key file")

	// Redis
	serverStartCmd.Flags().String("redis-host", "", "Redis server address")
	serverStartCmd.Flags().Int("redis-port", 6379, "Redis server port")
	serverStartCmd.Flags().String("redis-password", "", "Redis password")
	serverStartCmd.Flags().Int("redis-db-index", 0, "Redis db numeric index")

	// Initial passwords, users...
	serverStartCmd.Flags().String("initial-admin-passwd", "", "initial password for the admin account")
	serverStartCmd.Flags().String("initial-search-passwd", "", "initial password for the search account")
	serverStartCmd.Flags().String("initial-users", "", "comma-separated lists of usernames to be added when server starts")
	serverStartCmd.Flags().String("initial-users-password", "glim", "default password for your initial users")

	// Debug
	serverStartCmd.Flags().Bool("log-sql", false, "enable SQL queries logging")

	// Apache Guacamole
	serverStartCmd.Flags().Bool("guacamole", false, "enable Apache Guacamole support")

	viper.BindPFlags(serverStartCmd.Flags())
}
