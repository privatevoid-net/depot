package handlers

import (
	"net/http"
	"testing"
)

func TestGroupRead(t *testing.T) {
	// Setup
	h, e, settings := testSetup(t, false)
	defer testCleanUp()

	// Log in with admin, search and/or plain user and get tokens
	adminToken, _ := getUserTokens("admin", h, e, settings)
	searchToken, _ := getUserTokens("search", h, e, settings)
	plainUserToken, _ := getUserTokens("saul", h, e, settings)

	everybodyInfo := `[{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""},{"gid":2,"name":"managers","description":"Managers","members":[{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}]`

	// Test cases
	testCases := []RestTestCase{
		{
			name:             "group devel can be created",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "devel", "description": "Developers", "members":"saul"}`,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "group managers can be created",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodPost,
			secret:           adminToken,
			reqBodyJSON:      `{"name": "managers", "description": "Managers", "members":"kim"}`,
			expectedBodyJSON: `{"gid":2,"name":"managers","description":"Managers","members":[{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "search user can list all groups",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: everybodyInfo,
		},
		{
			name:             "manager user can list all groups",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: everybodyInfo,
		},
		{
			name:             "plain user can't list all groups",
			expResCode:       http.StatusUnauthorized,
			reqURL:           "/v1/groups",
			reqMethod:        http.MethodGet,
			secret:           plainUserToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
		{
			name:       "non-existent group returns 404",
			expResCode: http.StatusNotFound,
			reqURL:     "/v1/groups/3",
			reqMethod:  http.MethodGet,
			secret:     adminToken,
		},
		{
			name:             "manager user can see a single group info by its gid",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "readonly user can see a single group info by its gid",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}`,
		},
		{
			name:             "plain user can't get info of a group which is a member of",
			expResCode:       http.StatusUnauthorized,
			reqURL:           "/v1/groups/1",
			reqMethod:        http.MethodGet,
			secret:           plainUserToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
		{
			name:       "can't get gid from a non-existent group's name",
			expResCode: http.StatusNotFound,
			reqURL:     "/v1/groups/wrong/gid",
			reqMethod:  http.MethodGet,
			secret:     adminToken,
		},
		{
			name:             "manager user can get gid from a group's name",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/devel/gid",
			reqMethod:        http.MethodGet,
			secret:           adminToken,
			expectedBodyJSON: `{"gid":1}`,
		},
		{
			name:             "radonly user can get gid from a group's name",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/groups/managers/gid",
			reqMethod:        http.MethodGet,
			secret:           searchToken,
			expectedBodyJSON: `{"gid":2}`,
		},
		{
			name:             "plain user can't get gid of a group which is a member of",
			expResCode:       http.StatusUnauthorized,
			reqURL:           "/v1/groups/devel/gid",
			reqMethod:        http.MethodGet,
			secret:           plainUserToken,
			expectedBodyJSON: `{"message":"user has no proper permissions"}`,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
