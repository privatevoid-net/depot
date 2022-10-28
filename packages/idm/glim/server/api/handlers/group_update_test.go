package handlers

import (
	"net/http"
	"testing"
)

func TestGroupUpdate(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "uid not found in token",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQifQ.SQ0P6zliTGQiAdTi2DjCDeht0n2FjYdPGV7JgOx0TRY",
			expectedBodyJSON: `{"message":"wrong token or missing info in token claims"}`,
		},
		{
			name:             "non-existent manager user can't update account info",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjEwMDB9.amq5OV7gU7HUrn5YA8sbs2cXMRFeYHTmXm6bhXJ9PDg",
			expectedBodyJSON: `{"message":"wrong user attempting to update group"}`,
		},
		{
			name:             "group not found",
			expResCode:       http.StatusNotFound,
			reqURL:           "/v1/groups/100",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"group not found"}`,
		},
		{
			name:             "group devel can be created without members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group can be created without members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "managers", "description": "Managers"}`,
			expectedBodyJSON: `{"gid":2,"name":"managers","description":"Managers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group name can't be duplicated",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups/2",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel"}`,
			expectedBodyJSON: `{"message":"group name cannot be duplicated"}`,
		},
		{
			name:             "can update description",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"description": "Devs"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Devs","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "can replace all members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"members": "saul", "replace": true}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Devs","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "can add a member",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodPut,
			secret:           adminToken,
			reqBodyJSON:      `{"members": "kim"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Devs","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
