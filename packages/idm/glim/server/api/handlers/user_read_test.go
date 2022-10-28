package handlers

import (
	"net/http"
	"testing"
)

func TestUserRead(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)
	plainUserToken, _ := getUserTokens("saul", h, e, settings)

	everybodyInfo := `[{"uid":1,"username":"admin","name":"","firstname":"LDAP","lastname":"administrator","email":"","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":2,"username":"search","name":"","firstname":"Read-Only","lastname":"Account","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":true,"locked":false},{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}]`

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "search user can list everybody's information",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: everybodyInfo,
		},
		{
			name:             "manager user can list everybody's information",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: everybodyInfo,
		},
		{
			name:             "plain user can only see her own info",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodGet,
			secret:           plainUserToken,
			expectedBodyJSON: `{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}`,
		},
		{
			name:             "manager user can see a plainuser account info",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}`,
		},
		{
			name:             "search user can see a plainuser account info",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/3",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}`,
		},
		{
			name:             "uid must be an integer",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/users/pepe",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"uid param should be a valid integer"}`,
		},
		{
			name:             "search user can't see non-existent account",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/3000",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"user not found"}`,
		},
		{
			name:             "manager user can't see non-existent account",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/3000",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"user not found"}`,
		},
		{
			name:             "plainuser can't see non-existent account",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/3000",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"user not found"}`,
		},
		{
			name:             "search user can't get uid from non-existent username",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/non-existent/uid",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"user not found"}`,
		},
		{
			name:             "manager user can't get uid from non-existent account",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/users/non-existent/uid",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"user not found"}`,
		},
		{
			name:             "search user can get uid from username",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/saul/uid",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"uid":3}`,
		},
		{
			name:             "manager user can get uid from username",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/saul/uid",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"uid":3}`,
		},
		{
			name:             "plainuser user can get uid from username",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/users/saul/uid",
			reqMethod:        http.MethodGet,
			secret:           plainUserToken,
			expectedBodyJSON: `{"uid":3}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
