package handlers

import (
	"fmt"
	"net/http"
	"testing"
)

func TestRefresh(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin user and get tokens
	adminToken, refreshToken := getUserTokens("admin", h, e, settings)
	_, plainUserRefreshToken := getUserTokens("saul", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "Bad request expired token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpYXQiOjE2NjEyNzM2MjMsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6ImQ5OGQ0YTA2LTYyOGMtNGNjZC05M2YxLWY5NjNhNmQ0YWU0OSIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.1DZfzMDf2jtaVQBFXOmimFpdauuBdoTFcF2N-BNc0sg"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"could not parse token, you may have to log in again"}`,
		},
		{
			name:             "Bad request uid not found in token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpYXQiOjE2NjEyNzM2MjMsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6ImQ5OGQ0YTA2LTYyOGMtNGNjZC05M2YxLWY5NjNhNmQ0YWU0OSIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50In0.ifF_FxTdMbzVoAesbIPayKnm9W9KF3jbiAAIILah7JY"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"uid not found in token"}`,
		},
		{
			name:             "Bad request jti not found in token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpYXQiOjE2NjEyNzM2MjMsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.mP8ZCNtI6_tx8JnFSzq--ossC9aUUh584vchAfLq0Dw"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"jti not found in token"}`,
		},
		{
			name:             "Bad request access jti not found in token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjI3NzE1MzI4MjMsImlhdCI6MTY2MTI3MzYyMywiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZDk4ZDRhMDYtNjI4Yy00Y2NkLTkzZjEtZjk2M2E2ZDRhZTQ5IiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjF9.5j3Sfwks_4fRtRgcZYVU-sGmBpvClSP9nWxhlKCXCNU"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"access jti not found in token"}`,
		},
		{
			name:             "Bad request access iat not found in token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpc3MiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJqdGkiOiJkOThkNGEwNi02MjhjLTRjY2QtOTNmMS1mOTYzYTZkNGFlNDkiLCJtYW5hZ2VyIjp0cnVlLCJyZWFkb25seSI6ZmFsc2UsInN1YiI6ImFwaS5nbGltLmNsaWVudCIsInVpZCI6MX0.4TaxwUmi5riq90RRCzvg7CsrBJHxLcbmYalSSmCQULM"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"iat not found in token"}`,
		},
		{
			name:             "Unauthorized expired refresh token",
			expResCode:       http.StatusUnauthorized,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      `{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhanRpIjoiOGE1NDM4ZTItMTIxYy00M2U2LWFlZjUtMTU4OWIxMTk2YTBmIiwiYXVkIjoiYXBpLmdsaW0uc2VydmVyIiwiZXhwIjoyNzcxNTMyODIzLCJpYXQiOjE2NTE1MzI4MjMsImlzcyI6ImFwaS5nbGltLnNlcnZlciIsImp0aSI6ImQ5OGQ0YTA2LTYyOGMtNGNjZC05M2YxLWY5NjNhNmQ0YWU0OSIsIm1hbmFnZXIiOnRydWUsInJlYWRvbmx5IjpmYWxzZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.T7FIZembax4xD3zozT_9fbEeWsPbJAmG4VkLFl1Fsmk"}`,
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"refresh token usage without log in exceeded"}`,
		},
		{
			name:       "user deleted",
			expResCode: http.StatusNoContent,
			reqURL:     "/v1/users/3",
			reqMethod:  http.MethodDelete,
			secret:     adminToken,
		},
		{
			name:             "Bad request invalid uid found in token",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      fmt.Sprintf(`{"refresh_token": "%s"}`, plainUserRefreshToken),
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"invalid uid found in token"}`,
		},
		{
			name:        "Refreshed token successful",
			expResCode:  http.StatusOK,
			reqURL:      "/v1/login/refresh_token",
			reqBodyJSON: fmt.Sprintf(`{"refresh_token": "%s"}`, refreshToken),
			reqMethod:   http.MethodPost,
		},
		{
			name:             "Unauthorized refresh token blacklisted",
			expResCode:       http.StatusUnauthorized,
			reqURL:           "/v1/login/refresh_token",
			reqBodyJSON:      fmt.Sprintf(`{"refresh_token": "%s"}`, refreshToken),
			reqMethod:        http.MethodPost,
			expectedBodyJSON: `{"message":"token no longer valid"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
