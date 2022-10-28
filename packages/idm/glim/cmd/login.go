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
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/Songmu/prompter"
	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

/*
LoginCmd
*/
func LoginCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "login",
		Short: `Log in to a Glim Server`,
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {

			username := viper.GetString("username")
			password := viper.GetString("password")
			passwordStdin := viper.GetBool("password-stdin")

			if username == "" {
				username = prompter.Prompt("Username", "")
				if username == "" {
					return errors.New("non-null username required")
				}
			}

			if !cmd.Flags().Changed("password") {
				if !passwordStdin {
					password = prompter.Password("Password")
					if password == "" {
						return errors.New("password required")
					}
				}
			} else {
				fmt.Println("WARNING! Using --password via the CLI is insecure. Use --password-stdin.")
			}

			if passwordStdin {
				if password != "" {
					return errors.New("--password and --password-stdin are mutually exclusive")
				} else {
					// Reference: https://flaviocopes.com/go-shell-pipes/
					info, err := os.Stdin.Stat()
					if err != nil {
						return errors.New("can't read from stdin")
					}

					if info.Mode()&os.ModeCharDevice != 0 {
						return errors.New("expecting password from stdin using a pipe")
					}

					reader := bufio.NewReader(os.Stdin)
					var output []rune

					for {
						input, _, err := reader.ReadRune()
						if err != nil && err == io.EOF {
							break
						}
						output = append(output, input)
					}

					password = strings.TrimSuffix(string(output), "\n")
				}
			}

			// Glim server URL
			url := viper.GetString("server")

			// Rest API authentication
			client := RestClient("")

			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetBody(types.Credentials{
					Username: username,
					Password: password,
				}).
				SetError(&types.APIError{}).
				Post(fmt.Sprintf("%s/v1/login", url))

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			// Authenticated, let's store tokens in $HOME/.glim/accessToken.json
			tokenFile, err := AuthTokenPath()
			if err != nil {
				return fmt.Errorf("%v", err)
			}

			f, err := os.OpenFile(tokenFile, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0600)
			if err != nil {
				return fmt.Errorf("could not create file to store auth token: %v", err)
			}
			defer f.Close()

			if _, err := f.WriteString(resp.String()); err != nil {
				return fmt.Errorf("could not store credentials in our local fs: %v", err)
			}

			fmt.Fprintf(cmd.OutOrStdout(), "Login succeeded\n")
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.Flags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.Flags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.Flags().StringP("username", "u", "", "Username")
	cmd.Flags().StringP("password", "p", "", "Password")
	cmd.Flags().Bool("password-stdin", false, "Take the password from stdin")

	return cmd
}

func init() {
	loginCmd := LoginCmd()
	rootCmd.AddCommand(loginCmd)
}
