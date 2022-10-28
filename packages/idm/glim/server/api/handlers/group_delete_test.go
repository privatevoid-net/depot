package handlers

import (
	"net/http"
	"testing"
)

func TestGroupDelete(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "only a valid manager can delete a group",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodDelete,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
		{
			name:             "gid param should be a valid integer",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups/wrong",
			reqMethod:        http.MethodDelete,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"gid param should be a valid integer"}`,
		},
		{
			name:             "group not found",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/groups/1000",
			reqMethod:        http.MethodDelete,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"group not found"}`,
		},
		{
			name:             "create group",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:       "group can be deleted",
			expResCode: http.StatusNoContent,
			reqURL:     "/v1/groups/1",
			reqMethod:  http.MethodDelete,
			secret:     adminToken,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
