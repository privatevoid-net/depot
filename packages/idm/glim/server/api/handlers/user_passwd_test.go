package handlers

import (
	"net/http"
	"testing"
)

func TestUserPasswd(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "uid not in path",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users//passwd",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"required user uid"}`,
		},
		{
			name:             "uid not found in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users/5/passwd",
			reqMethod:        http.MethodPost,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQifQ.SQ0P6zliTGQiAdTi2DjCDeht0n2FjYdPGV7JgOx0TRY",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "uid param must be an integer",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/users/none/passwd",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"uid param should be a valid integer"}`,
		},
		{
			name:             "manager claim missing in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/users/5/passwd",
			reqMethod:        http.MethodPost,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjF9.j1lc0cK-KtsI5qI6Vpws6mc4RMSwWL-fuobIujGfJYo",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "only managers can change other users passwords",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/5/passwd",
			reqMethod:        http.MethodPost,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"only managers can change other users passwords"}`,
		},
		{
			name:             "the old password must be provided",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/2/passwd",
			reqMethod:        http.MethodPost,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"the old password must be provided"}`,
		},
		{
			name:             "user not found",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/50000/passwd",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"wrong username or password"}`,
		},
		{
			name:             "wrong old password",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/2/passwd",
			reqMethod:        http.MethodPost,
			secret:           searchToken,
			reqBodyJSON:      `{"old_password": "wrong"}`,
			expectedBodyJSON: `{"message":"wrong old password"}`,
		},
		{
			name:             "empty password not allowed",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/2/passwd",
			reqMethod:        http.MethodPost,
			secret:           searchToken,
			reqBodyJSON:      `{"old_password": "test", "password": ""}`,
			expectedBodyJSON: `{"message":"the new password must be provided"}`,
		},
		{
			name:        "same passwords are ok",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/users/2/passwd",
			reqMethod:   http.MethodPost,
			secret:      searchToken,
			reqBodyJSON: `{"old_password": "test", "password": "test"}`,
		},
		{
			name:        "new password set",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/users/2/passwd",
			reqMethod:   http.MethodPost,
			secret:      searchToken,
			reqBodyJSON: `{"old_password": "test", "password": "new"}`,
		},
		{
			name:        "check new password is valid",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/users/2/passwd",
			reqMethod:   http.MethodPost,
			secret:      searchToken,
			reqBodyJSON: `{"old_password": "new", "password": "another"}`,
		},
		{
			name:             "manager must provide new password",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/users/2/passwd",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"the new password must be provided"}`,
		},
		{
			name:        "manager can change any password",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/users/2/passwd",
			reqMethod:   http.MethodPost,
			secret:      adminToken,
			reqBodyJSON: `{"password": "new"}`,
		},
		{
			name:        "check new password is valid",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/users/2/passwd",
			reqMethod:   http.MethodPost,
			secret:      searchToken,
			reqBodyJSON: `{"old_password": "new", "password": "another"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
