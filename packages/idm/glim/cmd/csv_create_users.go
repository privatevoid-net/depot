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
	"net/mail"
	"os"
	"path/filepath"
	"strings"

	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func CsvCreateUsersCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create users from a CSV file",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			// json output?
			jsonOutput := viper.GetBool("json")
			messages := []string{}

			// Read and open file
			users, err := readUsersFromCSV(jsonOutput, "username,firstname,lastname,email,password,ssh_public_key,jpeg_photo,manager,readonly,locked,groups")
			if err != nil {
				return err
			}

			if len(users) == 0 {
				return fmt.Errorf("no users where found in CSV file")
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

			for _, user := range users {
				username := *user.Username
				// Validate email
				email := *user.Email
				if email != "" {
					if _, err := mail.ParseAddress(email); err != nil {
						messages = append(messages, fmt.Sprintf("%s: skipped, email should have a valid format\n", username))
						continue
					}
				}
				// Check if both manager and readonly has been set
				manager := *user.Manager
				readonly := *user.Readonly
				if manager && readonly {
					messages = append(messages, fmt.Sprintf("%s: skipped, cannot be both manager and readonly at the same time\n", username))
					continue
				}

				password := *user.Password
				locked := *user.Locked || password == ""

				// JpegPhoto
				jpegPhoto := ""
				jpegPhotoPath := *user.JPEGPhoto
				if jpegPhotoPath != "" {
					photo, err := JPEGToBase64(jpegPhotoPath)
					if err != nil {
						messages = append(messages, fmt.Sprintf("%s: skipped, could not convert JPEG photo to Base64 %v\n", username, err))
						continue
					}
					jpegPhoto = *photo
				}

				resp, err := client.R().
					SetHeader("Content-Type", "application/json").
					SetBody(models.JSONUserBody{
						Username:     username,
						Password:     password,
						Name:         strings.Join([]string{*user.GivenName, *user.Surname}, " "),
						GivenName:    *user.GivenName,
						Surname:      *user.Surname,
						Email:        *user.Email,
						SSHPublicKey: *user.SSHPublicKey,
						MemberOf:     *user.Groups,
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
					messages = append(messages, fmt.Sprintf("%s: skipped, %v", username, resp.Error().(*types.APIError).Message))
					continue
				}
				messages = append(messages, fmt.Sprintf("%s: successfully created", username))
			}

			printCSVMessages(cmd, messages, jsonOutput)
			if !jsonOutput {
				printCmdMessage(cmd, "Create from CSV finished!", jsonOutput)
			}

			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	cmd.Flags().StringP("file", "f", "", "path to CSV file, use README to know more about the format")
	cmd.MarkFlagRequired("file")
	return cmd
}
