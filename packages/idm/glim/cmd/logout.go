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
	"os"
	"path/filepath"

	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func LogoutCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "logout [flags] [SERVER]",
		Short: "Log out from a Glim server",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, _ []string) error {
			var token *types.TokenAuthentication
			url := viper.GetString("server")

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				return err
			}

			// Logout
			client := RestClient("")

			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetBody(fmt.Sprintf(`{"refresh_token":"%s"}`, token.RefreshToken)).
				SetError(&types.APIError{}).
				Delete(fmt.Sprintf("%s/v1/login/refresh_token", url))

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			// Remove credentials file
			err = DeleteCredentials()
			if err != nil {
				return err
			}

			fmt.Fprintf(cmd.OutOrStdout(), "Removing login credentials\n")
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.Flags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.Flags().String("server", "https://127.0.0.1:1323", "glim REST API server address")

	return cmd
}

func init() {
	logoutCmd := LogoutCmd()
	rootCmd.AddCommand(logoutCmd)
}
