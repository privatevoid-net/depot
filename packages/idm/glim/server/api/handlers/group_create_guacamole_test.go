package handlers

import (
	"net/http"
	"testing"
)

func TestGroupGuacamoleCreate(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, true)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "group can be created with Guacamole settings",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "guac_config_protocol": "vnc", "guac_config_parameters": "host=192.168.1.131"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"vnc","guac_config_parameters":"host=192.168.1.131"}`,
		},
		{
			name:             "group can't be created with missing Guacamole settings",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "guac_config_parameters": "host=192.168.1.131"}`,
			expectedBodyJSON: `{"message":"Apache Guacamole config protocol is required"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
