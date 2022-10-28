package handlers

import (
	"net/http"
	"testing"
)

func TestLogin(t *testing.T) {

	testCases := []RestTestCase{
		{
			name:        "Login succesful saul",
			expResCode:  http.StatusOK,
			reqURL:      "/v1/login",
			reqBodyJSON: `{"username": "saul", "password": "test"}`,
			reqMethod:   http.MethodPost,
		},
		{
			name:        "Login succesful kim",
			expResCode:  http.StatusOK,
			reqURL:      "/v1/login",
			reqBodyJSON: `{"username": "kim", "password": "test"}`,
			reqMethod:   http.MethodPost,
		},
		{
			name:        "Wrong password mike",
			expResCode:  http.StatusUnauthorized,
			reqURL:      "/v1/login",
			reqBodyJSON: `{"username": "mike", "password": "boooo"}`,
			reqMethod:   http.MethodPost,
		},
		{
			name:        "User doesn't exist walter",
			expResCode:  http.StatusUnauthorized,
			reqURL:      "/v1/login",
			reqBodyJSON: `{"username": "walter", "password": "boooo"}`,
			reqMethod:   http.MethodPost,
		},
		{
			name:        "No JSON body",
			expResCode:  http.StatusUnauthorized,
			reqURL:      "/v1/login",
			reqBodyJSON: `""`,
			reqMethod:   http.MethodPost,
		},
	}

	// New SQLite test database
	db, err := newTestDatabase()
	if err != nil {
		t.Fatalf("could not initialize db - %v", err)
	}
	defer removeDatabase()

	// New BadgerDB test key-value storage
	kv, err := newTestKV()
	if err != nil {
		t.Fatalf("could not initialize kv - %v", err)
	}
	defer removeKV()

	settings := testSettings(db, kv)
	e := EchoServer(settings)

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
