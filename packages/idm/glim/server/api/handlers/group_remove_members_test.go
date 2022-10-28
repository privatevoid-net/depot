package handlers

import (
	"net/http"
	"testing"
)

func TestGroupRemoveMembers(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "group can be created with members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "members": "saul,kim,mike"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group id is required",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups//members",
			reqMethod:        http.MethodDelete,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"required group gid"}`,
		},
		{
			name:        "success even if user was not a member",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/groups/1/members",
			reqMethod:   http.MethodDelete,
			secret:      adminToken,
			reqBodyJSON: `{"members": "saul,walter"}`,
		},
		{
			name:        "remove mike from group",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/groups/1/members",
			reqMethod:   http.MethodDelete,
			secret:      adminToken,
			reqBodyJSON: `{"members": "mike"}`,
		},
		{
			name:             "only kim in group",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:        "delete all members",
			expResCode:  http.StatusNoContent,
			reqURL:      "/v1/groups/1/members",
			reqMethod:   http.MethodDelete,
			secret:      adminToken,
			reqBodyJSON: `{"members": "saul,kim,mike"}`,
		},
		{
			name:             "group is empty",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
