package handlers

import (
	"net/http"
	"testing"
)

func TestGroupGuacamoleUpdate(t *testing.T) {
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
			name:             "group devel Guacamole settings can be updated",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "guac_config_protocol": "ssh", "guac_config_parameters": "host=localhost"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"ssh","guac_config_parameters":"host=localhost"}`,
		},
		{
			name:             "group can be created without Guacamole settings",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "admin", "description": "Admins"}`,
			expectedBodyJSON: `{"gid":2,"name":"admin","description":"Admins","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group devel Guacamole settings can't be updated without protocol",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups/2",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"guac_config_parameters": "host=localhost"}`,
			expectedBodyJSON: `{"message":"Apache Guacamole config protocol is required"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
