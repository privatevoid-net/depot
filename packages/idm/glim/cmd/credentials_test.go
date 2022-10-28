package cmd

import (
	"errors"
	"os"
	"testing"

	"github.com/doncicuto/glim/types"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestAuthTokenPath(t *testing.T) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("could not get user home dir - %v", err)
	}
	path := homeDir + "/.glim/accessToken.json"

	tokenPath, err := AuthTokenPath()
	if err != nil {
		t.Fatalf("could not get AuthTokenPath - %v", err)
	}

	assert.Equal(t, path, tokenPath)
}

func TestReadCredentials(t *testing.T) {
	tokenPath, err := AuthTokenPath()
	if err != nil {
		t.Fatalf("could not get AuthTokenPath - %v", err)
	}

	t.Run("can't read token from non-existent file", func(t *testing.T) {
		os.Remove(tokenPath)
		_, err = readCredentials()
		assert.Equal(t, errors.New("could not read file containing auth token. Please, log in again"), err)
	})

	t.Run("can't read token from invalid JSON file", func(t *testing.T) {
		os.Remove(tokenPath)

		wrongJsonObject := []byte("wrong{}\n")
		err := os.WriteFile(tokenPath, wrongJsonObject, 0644)
		if err != nil {
			t.Fatalf("could not write token file - %v", err)
		}
		_, err = readCredentials()
		assert.Equal(t, errors.New("could not get credentials from stored file"), err)
	})

	t.Run("can read token from valid file", func(t *testing.T) {
		os.Remove(tokenPath)

		json := []byte("{\"token_type\":\"Bearer\",\"expires_in\":3600,\"expires_on\":1664698795,\"access_token\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE2NjQ2OTg3OTUsImlhdCI6MTY2NDY5NTE5NSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiYjEwMjVmOGEtODgwNC00MDEyLThlZWYtN2E5MjU4MDY0Y2U5IiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjF9.ycuAQ-gtWu5k0ggTpbXRP_Y4VzEwjtvXFeMXSHItGIU\",\"refresh_token\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiYjEwMjVmOGEtODgwNC00MDEyLThlZWYtN2E5MjU4MDY0Y2U5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxNjY0OTU0Mzk1LCJpYXQiOjE2NjQ2OTUxOTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6IjkxMzcwNWEyLThmOGEtNGJlMC04ZGJjLTE1MjdmMWU0NjBlYyIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.YFr7KfmR1xyIbkAjxB_EyyXWKIV0CbTGTMlYgoE8AhQ\"}\n")
		err := os.WriteFile(tokenPath, json, 0644)
		if err != nil {
			t.Fatalf("could not write token file - %v", err)
		}
		token, err := readCredentials()
		expectToken := types.TokenAuthentication{TokenType: "Bearer", ExpiresIn: 3600, ExpiresOn: 1664698795, Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE2NjQ2OTg3OTUsImlhdCI6MTY2NDY5NTE5NSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiYjEwMjVmOGEtODgwNC00MDEyLThlZWYtN2E5MjU4MDY0Y2U5IiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjF9.ycuAQ-gtWu5k0ggTpbXRP_Y4VzEwjtvXFeMXSHItGIU", RefreshToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiYjEwMjVmOGEtODgwNC00MDEyLThlZWYtN2E5MjU4MDY0Y2U5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxNjY0OTU0Mzk1LCJpYXQiOjE2NjQ2OTUxOTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6IjkxMzcwNWEyLThmOGEtNGJlMC04ZGJjLTE1MjdmMWU0NjBlYyIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.YFr7KfmR1xyIbkAjxB_EyyXWKIV0CbTGTMlYgoE8AhQ"}}
		assert.Equal(t, nil, err)
		assert.Equal(t, expectToken, *token)
	})
}

func TestDeleteCredentials(t *testing.T) {
	tokenPath, err := AuthTokenPath()
	if err != nil {
		t.Fatalf("could not get AuthTokenPath - %v", err)
	}

	//Can't delete credentials from non-existent file
	t.Run("can't delete credentials from non-existent file", func(t *testing.T) {
		os.Remove(tokenPath)
		err = DeleteCredentials()
		assert.NotNil(t, err)
	})

	//Can delete credentials
	t.Run("can delete credentials from non-existent file", func(t *testing.T) {
		os.Remove(tokenPath)
		json := []byte("{}")
		err := os.WriteFile(tokenPath, json, 0644)
		if err != nil {
			t.Fatalf("could not write token file - %v", err)
		}
		err = DeleteCredentials()
		assert.Nil(t, err)
	})
}

func TestRefresh(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())
	url := "http://127.0.0.1:50002"

	// Launch testing server
	go func() {
		e.Start(":50002")
	}()

	waitForTestServer(t, ":50002")

	// Get token path
	tokenPath, err := AuthTokenPath()
	if err != nil {
		t.Fatalf("could not get AuthTokenPath - %v", err)
	}

	t.Run("token is empty", func(t *testing.T) {
		os.Remove(tokenPath)
		_, err := refresh(url, "")
		if err != nil {
			assert.Contains(t, err.Error(), "could not parse token, you may have to log in again")
		}
	})

	t.Run("token can't be refreshed", func(t *testing.T) {
		os.Remove(tokenPath)
		_, err := refresh(url, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpYXQiOjE2NTE1MzI4MjMsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6ImQ5OGQ0YTA2LTYyOGMtNGNjZC05M2YxLWY5NjNhNmQ0YWU0OSIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.T7FIZembax4xD3zozT_9fbEeWsPbJAmG4VkLFl1Fsmk")
		if err != nil {
			assert.Contains(t, err.Error(), "refresh token usage without log in exceeded")
		}
	})

	t.Run("token can be refreshed", func(t *testing.T) {
		os.Remove(tokenPath)
		token, err := refresh(url, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.ssYmxVciETD6LIKVfK_43Ka0Q79TAE4fdbNpjO-TpvA")
		if err != nil {
			assert.Contains(t, err.Error(), "refresh token usage without log in exceeded")
		} else {
			assert.NotNil(t, token)
		}
	})
}

func TestNeedsRefresh(t *testing.T) {
	t.Run("needs refresh", func(t *testing.T) {
		needsRefreshToken := types.TokenAuthentication{ExpiresOn: 1349284436}
		needs := NeedsRefresh(&needsRefreshToken)
		assert.Equal(t, true, needs)
	})

	t.Run("doesnt need refresh", func(t *testing.T) {
		notNeededRefreshToken := types.TokenAuthentication{ExpiresOn: 2295969236}
		needs := NeedsRefresh(&notNeededRefreshToken)
		assert.Equal(t, false, needs)
	})
}

func TestAmIManager(t *testing.T) {
	t.Run("I am not manager", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCIsInVpZCI6MX0.NZND2mvAGLd-7mCirt-zQj2VyXBnB9C31AAeaERsnMQ"}}
		manager := AmIManager(&token)
		assert.Equal(t, false, manager)
	})

	t.Run("I am manager", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.ssYmxVciETD6LIKVfK_43Ka0Q79TAE4fdbNpjO-TpvA"}}
		manager := AmIManager(&token)
		assert.Equal(t, true, manager)
	})
}

func TestAmIReadonly(t *testing.T) {
	t.Run("I am not readonly", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCIsInVpZCI6MX0.NZND2mvAGLd-7mCirt-zQj2VyXBnB9C31AAeaERsnMQ"}}
		readonly := AmIReadonly(&token)
		assert.Equal(t, false, readonly)
	})

	t.Run("I am readonly", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6dHJ1ZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.VarBBQt_ChlIeKgZs-QG7WFoTRROjsZDAqKoYQOMzsg"}}
		readonly := AmIReadonly(&token)
		assert.Equal(t, true, readonly)
	})
}

func TestAmIPlainUser(t *testing.T) {
	t.Run("I am not plain user", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.ssYmxVciETD6LIKVfK_43Ka0Q79TAE4fdbNpjO-TpvA"}}
		plainuser := AmIPlainUser(&token)
		assert.Equal(t, false, plainuser)
	})

	t.Run("I am plain user", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCIsInVpZCI6MX0.NZND2mvAGLd-7mCirt-zQj2VyXBnB9C31AAeaERsnMQ"}}
		plainuser := AmIPlainUser(&token)
		assert.Equal(t, true, plainuser)
	})
}

func TestWhichIsMyTokenUID(t *testing.T) {
	t.Run("can't get uid", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCJ9.tcNlFfMuRjsDg2rbg6HUqCIORW6NQr-6XlFTir_Ok7E"}}
		_, err := WhichIsMyTokenUID(&token)
		if err != nil {
			assert.Contains(t, err.Error(), "could not parse access token. Please try to log in again")
		}
	})

	t.Run("can get uid", func(t *testing.T) {
		token := types.TokenAuthentication{Tokens: types.Tokens{AccessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOTQ4YzYyYzYtMTZlZC00OWQ4LWI0YjEtY2IyZTUwZDhjMjQ5IiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoxOTgwNDM2NDM2LCJpYXQiOjE2NjQ3MTE2NTUsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6Ijg1YjkyZmU2LWRjYmYtNDcwNy1hZmJiLTlkYWMwOWJkOGY0ZiIsIm1hbmFnZXIiOmZhbHNlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCIsInVpZCI6MX0.NZND2mvAGLd-7mCirt-zQj2VyXBnB9C31AAeaERsnMQ"}}
		uid, err := WhichIsMyTokenUID(&token)
		if err != nil {
			assert.Contains(t, err.Error(), "could not parse access token. Please try to log in again")
		} else {
			assert.Equal(t, uint(1), uid)
		}
	})
}
