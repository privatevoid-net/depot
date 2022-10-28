package handlers

import (
	"net/http"
	"testing"
)

func TestIsUpdater(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)
	plainUserToken, _ := getUserTokens("saul", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "uid not found in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodPut,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQifQ.SQ0P6zliTGQiAdTi2DjCDeht0n2FjYdPGV7JgOx0TRY",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "readonly claim not in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodPut,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwic3ViIjoiYXBpLmdsaW0uY2xpZW50IiwidWlkIjoxfQ.eDcXE_IFDAMuvExWiEyQBhJeujL7F7tRrIqKxV6E9rM",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "manager claim not in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodPut,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjF9.j1lc0cK-KtsI5qI6Vpws6mc4RMSwWL-fuobIujGfJYo",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "plain user can't update other's account",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/4",
			reqMethod:        http.MethodPut,
			secret:           plainUserToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
		{
			name:             "readonly user can't update accounts",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/4",
			reqMethod:        http.MethodPut,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
		{
			name:       "plain user can update its own account",
			expResCode: http.StatusOK,
			reqURL:     "/v1/users/3",
			reqMethod:  http.MethodPut,
			secret:     plainUserToken,
		},
		{
			name:       "manager can update",
			expResCode: http.StatusOK,
			reqURL:     "/v1/users/4",
			reqMethod:  http.MethodPut,
			secret:     adminToken,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
