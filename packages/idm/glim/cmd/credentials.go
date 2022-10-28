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
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"github.com/doncicuto/glim/types"
	"github.com/golang-jwt/jwt"
)

/*
AuthTokenPath gets the path where Glim's JWT access token is stored
Returns a string containing the file path inside user's home directory
*/
func AuthTokenPath() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}

	glimPath := fmt.Sprintf("%s/.glim", homeDir)
	if _, err := os.Stat(glimPath); os.IsNotExist(err) {
		err = os.MkdirAll(glimPath, 0700)
		if err != nil {
			return "", fmt.Errorf("could not create .glim in your home directory: %v", err)
		}
	}

	tokenPath := fmt.Sprintf("%s/accessToken.json", glimPath)
	return tokenPath, nil
}

/*
readCredentials read and parse token stored in path retrieved from AuthTokenPath
Returns a pointer to the token or error
*/
func readCredentials() (*types.TokenAuthentication, error) {
	var token types.TokenAuthentication

	tokenFile, err := AuthTokenPath()
	if err != nil {
		return nil, err
	}

	f, err := os.Open(tokenFile)
	if err != nil {
		return nil, errors.New("could not read file containing auth token. Please, log in again")
	}
	defer f.Close()

	byteValue, _ := ioutil.ReadAll(f)
	if err := json.Unmarshal(byteValue, &token); err != nil {
		return nil, errors.New("could not get credentials from stored file")
	}

	return &token, nil
}

/*
DeleteCredentials deletes the file containing credentials
*/

func DeleteCredentials() error {
	tokenFile, err := AuthTokenPath()
	if err != nil {
		return err
	}

	if err := os.Remove(tokenFile); err != nil {
		return err
	}
	return nil
}

/*
refresh contact Glim REST API to retrieve new access and refresh tokens
refresh needs the server's REST API url address and current refresh token string
*/
func refresh(url string, rt string) (*types.TokenAuthentication, error) {
	// Rest API authentication
	client := RestClient(rt)

	// Query refresh token
	resp, err := client.R().
		SetHeader("Content-Type", "application/json").
		SetBody(types.RefreshToken{
			Token: rt,
		}).
		SetError(&types.APIError{}).
		Post(fmt.Sprintf("%s/v1/login/refresh_token", url))

	if err != nil {
		return nil, fmt.Errorf("can't connect with Glim: %v", err)
	}

	if resp.IsError() {
		return nil, fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
	}
	// Authenticated, let's store tokens in $HOME/.glim/accessToken.json
	tokenFile, err := AuthTokenPath()
	if err != nil {
		return nil, fmt.Errorf("could not guess auth token path")
	}

	f, err := os.OpenFile(tokenFile, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		return nil, fmt.Errorf("could not create file to store auth token")
	}
	defer f.Close()

	if _, err := f.WriteString(resp.String()); err != nil {
		return nil, fmt.Errorf("could not store credentials in our local fs")
	}
	token, err := readCredentials()
	return token, err
}

/*
GetCredentials parses file with token and get new tokens if refresh
is needed
*/
func GetCredentials(url string) (*types.TokenAuthentication, error) {
	// Read credentials from file
	token, err := readCredentials()
	if err != nil {
		return nil, err
	}

	// Check expiration and get new token
	if NeedsRefresh(token) {
		token, err = refresh(url, token.RefreshToken)
		if err != nil {
			return nil, err
		}
	}

	return token, nil
}

/*
NeedsRefresh check if token needs to be refreshed
*/
func NeedsRefresh(token *types.TokenAuthentication) bool {
	// Check expiration
	now := time.Now()
	expiration := time.Unix(token.ExpiresOn, 0)
	return expiration.Before(now)
}

/*
AmIManager parses access token and checks if admin property is set to true
*/
func AmIManager(token *types.TokenAuthentication) bool {
	claims := make(jwt.MapClaims)
	jwt.ParseWithClaims(token.AccessToken, claims, nil)

	manager, ok := claims["manager"].(bool)
	if !ok {
		fmt.Println("Could not parse access token. Please try to log in again")
		os.Exit(1)
	}

	return manager
}

/*
AmIReadonly parses access token and checks if readonly property is set to true
*/
func AmIReadonly(token *types.TokenAuthentication) bool {
	claims := make(jwt.MapClaims)
	jwt.ParseWithClaims(token.AccessToken, claims, nil)

	readonly, ok := claims["readonly"].(bool)
	if !ok {
		fmt.Println("Could not parse access token. Please try to log in again")
		os.Exit(1)
	}

	return readonly
}

/*
AmIPlainUser parses access token and checks if manager and/or readonly properties are set to true
A plain user has both manager and readonly properties set to false
*/
func AmIPlainUser(token *types.TokenAuthentication) bool {
	return !AmIManager(token) && !AmIReadonly(token)
}

/*
WhichIsMyTokenUID parses access token and gets uid claim/property
*/
func WhichIsMyTokenUID(token *types.TokenAuthentication) (uint, error) {
	claims := make(jwt.MapClaims)
	jwt.ParseWithClaims(token.AccessToken, claims, nil)

	// Extract access token jti
	uid, ok := claims["uid"].(float64)
	if !ok {
		return 0, fmt.Errorf("could not parse access token. Please try to log in again")
	}

	return uint(uid), nil
}
