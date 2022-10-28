package handlers

import (
	"net/http"
	"testing"
)

func TestGroupGuacamoleRead(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, true)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "Guacamole group can be created",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "members":"saul", "guac_config_protocol":"vnc", "guac_config_parameters":"host=localhost"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"vnc","guac_config_parameters":"host=localhost"}`,
		},
		{
			name:             "readonly user can see a Guacamole group detail by its gid",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"vnc","guac_config_parameters":"host=localhost"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
