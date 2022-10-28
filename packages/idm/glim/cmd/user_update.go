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

func UpdateUserCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update",
		Short: "Update Glim user account",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			var trueValue = true
			var falseValue = false

			url := viper.GetString("server")
			jsonOutput := viper.GetBool("json")

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				return err
			}

			// Get uid and username
			uid := viper.GetUint("uid")
			username := viper.GetString("username")

			if uid == 0 && username == "" {
				return fmt.Errorf("you must specify either the user account id or a username")
			}

			client := RestClient(token.AccessToken)
			if uid == 0 && username != "" {
				uid, err = getUIDFromUsername(client, username, url)
				if err != nil {
					return err
				}
			}

			// Validate email
			email := viper.GetString("email")
			if email != "" {
				if _, err := mail.ParseAddress(email); err != nil {
					return fmt.Errorf("email should have a valid format")
				}
			}

			// Check if both manager and readonly have been set
			manager := viper.GetBool("manager")
			readonly := viper.GetBool("readonly")
			if manager && readonly {
				return fmt.Errorf("a Glim account cannot be both manager and readonly at the same time")
			}

			// Check if both remove and replace flags have been set
			replace := viper.GetBool("replace")
			remove := viper.GetBool("remove")
			if replace && remove {
				return fmt.Errorf("replace and remove flags are mutually exclusive")
			}

			jpegPhoto := ""
			jpegPhotoPath := viper.GetString("jpeg-photo")
			if jpegPhotoPath != "" {
				photo, err := JPEGToBase64(jpegPhotoPath)
				if err != nil {
					return fmt.Errorf("could not convert JPEG photo to Base64 - %v", err)
				}
				jpegPhoto = *photo
			}

			userBody := models.JSONUserBody{
				Username:     username,
				Name:         strings.Join([]string{viper.GetString("firstname"), viper.GetString("lastname")}, " "),
				GivenName:    viper.GetString("firstname"),
				Surname:      viper.GetString("lastname"),
				Email:        viper.GetString("email"),
				SSHPublicKey: viper.GetString("ssh-public-key"),
				MemberOf:     viper.GetString("groups"),
				JPEGPhoto:    jpegPhoto,
			}

			if viper.GetBool("manager") {
				userBody.Manager = &trueValue
				userBody.Readonly = &falseValue
			}

			if viper.GetBool("readonly") {
				userBody.Manager = &falseValue
				userBody.Readonly = &trueValue
			}

			if viper.GetBool("lock") {
				userBody.Locked = &trueValue
			}

			if viper.GetBool("unlock") {
				userBody.Locked = &falseValue
			}

			if viper.GetBool("plainuser") {
				userBody.Manager = &falseValue
				userBody.Readonly = &falseValue
			}

			if replace {
				userBody.ReplaceMembersOf = true
			}

			if remove {
				userBody.RemoveMembersOf = true
			}

			// Rest API authentication
			endpoint := fmt.Sprintf("%s/v1/users/%d", url, uid)
			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetBody(userBody).
				SetError(&types.APIError{}).
				Put(endpoint)

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			printCmdMessage(cmd, "User updated", jsonOutput)
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
	cmd.Flags().StringP("ssh-public-key", "k", "", "SSH Public Key")
	cmd.Flags().StringP("jpeg-photo", "j", "", "path to avatar file (jpg, png)")
	cmd.Flags().StringP("groups", "g", "", "comma-separated list of group names. ")
	cmd.Flags().Bool("manager", false, "Glim manager account?")
	cmd.Flags().Bool("readonly", false, "Glim readonly account?")
	cmd.Flags().Bool("plainuser", false, "Glim plain user account. User can read and modify its own user account information but not its group membership.")
	cmd.Flags().Bool("replace", false, "replace groups with those specified with -g. Groups are appended to those that the user is a member of by default")
	cmd.Flags().Bool("remove", false, "remove group membership with those specified with -g.")
	cmd.Flags().Bool("lock", false, "lock account (cannot log in)")
	cmd.Flags().Bool("unlock", false, "unlock account (can log in)")
	cmd.Flags().UintP("uid", "i", 0, "user account id")
	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	return cmd
}
