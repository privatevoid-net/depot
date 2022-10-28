package handlers

import (
	"net/http"
	"testing"
)

func TestServer(t *testing.T) {
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

	// Test cases
	testCases := []RestTestCase{
		{
			name:       "invalid token",
			expResCode: http.StatusUnauthorized,
			reqURL:     "/v1/groups",
			reqMethod:  http.MethodPost,
			secret:     "wrong secret",
		},
		{
			name:       "not found",
			expResCode: http.StatusNotFound,
			reqURL:     "/groups",
			reqMethod:  http.MethodGet,
		},
	}

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
