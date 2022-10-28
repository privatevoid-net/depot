package handlers

import (
	"net/http"
	"testing"
)

func TestGroupCreate(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "only a valid manager can create a group",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           searchToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},

		{
			name:             "non-existent manager user can't create group",
			expResCode:       http.StatusForbidden,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcGkuZ2xpbS5zZXJ2ZXIiLCJleHAiOjE5NzcyNDUzOTksImlhdCI6MTY2MTYyNjA3MSwiaXNzIjoiYXBpLmdsaW0uc2VydmVyIiwianRpIjoiZTdiZmYzMjQtMzJmOC00MTNlLTgyNmYtNzc5Mzk5NDBjOTZkIiwibWFuYWdlciI6dHJ1ZSwicmVhZG9ubHkiOmZhbHNlLCJzdWIiOiJhcGkuZ2xpbS5jbGllbnQiLCJ1aWQiOjEwMDB9.amq5OV7gU7HUrn5YA8sbs2cXMRFeYHTmXm6bhXJ9PDg",
			expectedBodyJSON: `{"message":"wrong user attempting to create group"}`,
		},
		{
			name:             "group name is required",
			expResCode:       http.StatusNotAcceptable,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			expectedBodyJSON: `{"message":"required group name"}`,
		},
		{
			name:             "group can be created without members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group name already exits",
			expResCode:       http.StatusBadRequest,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers"}`,
			expectedBodyJSON: `{"message":"group already exists"}`,
		},
		{
			name:             "group can be created with existent members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "lawyers", "description": "Lawyers", "members":"saul,kim"}`,
			expectedBodyJSON: `{"gid":2,"name":"lawyers","description":"Lawyers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group can be created with non-existent members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "dealers", "description": "Dealers", "members":"walter"}`,
			expectedBodyJSON: `{"gid":3,"name":"dealers","description":"Dealers","guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group can be created with existent and non-existent members",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "fixers", "description": "Fixers", "members":"walter,mike"}`,
			expectedBodyJSON: `{"gid":4,"name":"fixers","description":"Fixers","members":[{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
