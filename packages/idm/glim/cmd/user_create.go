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
	"fmt"
	"io"
	"net/mail"
	"os"
	"path/filepath"
	"strings"

	"github.com/Songmu/prompter"
	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// NewUserCmd - TODO comment
func NewUserCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create a Glim user account",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			// json output?
			jsonOutput := viper.GetBool("json")

			// Validate email
			email := viper.GetString("email")
			if email != "" {
				if _, err := mail.ParseAddress(email); err != nil {
					return fmt.Errorf("email should have a valid format")
				}
			}

			// Check if both manager and readonly has been set
			manager := viper.GetBool("manager")
			readonly := viper.GetBool("readonly")

			if manager && readonly {
				return fmt.Errorf("a Glim account cannot be both manager and readonly at the same time")
			}

			plainuser := viper.GetBool("plainuser")
			if plainuser {
				manager = false
				readonly = false
			}

			// Prompt for password if needed
			password := viper.GetString("password")
			passwordStdin := viper.GetBool("password-stdin")
			locked := viper.GetBool("lock")

			if password == "" && !passwordStdin && !locked {
				password = prompter.Password("Password")
				if password == "" {
					return fmt.Errorf("password required")
				}
				confirmPassword := prompter.Password("Confirm password")
				if password != confirmPassword {
					return fmt.Errorf("passwords don't match")
				}
			} else {
				switch {
				case password != "" && !passwordStdin:
					fmt.Println("WARNING! Using --password via the CLI is insecure. Use --password-stdin.")

				case password != "" && passwordStdin:
					return fmt.Errorf("--password and --password-stdin are mutually exclusive")

				case passwordStdin:
					// Reference: https://flaviocopes.com/go-shell-pipes/
					info, err := os.Stdin.Stat()
					if err != nil {
						return fmt.Errorf("can't read from stdin")
					}

					if info.Mode()&os.ModeCharDevice != 0 {
						return fmt.Errorf("expecting password from stdin using a pipe")
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
					if password == "" {
						locked = true
					}
				}
			}

			// Glim server URL
			url := viper.GetString("server")
			endpoint := fmt.Sprintf("%s/v1/users", url)

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				return err
			}

			// Rest API authentication
			client := RestClient(token.AccessToken)

			// JpegPhoto
			jpegPhoto := ""
			jpegPhotoPath := viper.GetString("jpeg-photo")
			if jpegPhotoPath != "" {
				photo, err := JPEGToBase64(jpegPhotoPath)
				if err != nil {
					return fmt.Errorf("could not convert JPEG photo to Base64 - %v", err)
				}
				jpegPhoto = *photo
			}

			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetBody(models.JSONUserBody{
					Username:     viper.GetString("username"),
					Password:     password,
					Name:         strings.Join([]string{viper.GetString("firstname"), viper.GetString("lastname")}, " "),
					GivenName:    viper.GetString("firstname"),
					Surname:      viper.GetString("lastname"),
					Email:        viper.GetString("email"),
					SSHPublicKey: viper.GetString("ssh-public-key"),
					MemberOf:     viper.GetString("groups"),
					JPEGPhoto:    jpegPhoto,
					Manager:      &manager,
					Readonly:     &readonly,
					Locked:       &locked,
				}).
				SetError(&types.APIError{}).
				Post(endpoint)

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			printCmdMessage(cmd, "User created", jsonOutput)
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.Flags().StringP("username", "u", "", "username")
	cmd.Flags().StringP("firstname", "f", "", "first name")
	cmd.Flags().StringP("lastname", "l", "", "last name")
	cmd.Flags().StringP("email", "e", "", "email")
	cmd.Flags().StringP("password", "p", "", "password")
	cmd.Flags().StringP("ssh-public-key", "k", "", "SSH Public Key")
	cmd.Flags().StringP("jpeg-photo", "j", "", "path to avatar file (jpg, png)")
	cmd.Flags().StringP("groups", "g", "", "comma-separated list of groups that we want the new user account to be a member of")
	cmd.Flags().Bool("password-stdin", false, "take the password from stdin")
	cmd.Flags().Bool("manager", false, "Glim manager account?")
	cmd.Flags().Bool("readonly", false, "Glim readonly account?")
	cmd.Flags().Bool("plainuser", false, "Glim plain user account. User can read and modify its own user account information but not its group membership.")
	cmd.Flags().Bool("lock", false, "lock account (no password will be set, user cannot log in)")
	cmd.Flags().Bool("unlock", false, "unlock account (can log in)")
	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	cmd.MarkFlagRequired("username")

	return cmd
}
