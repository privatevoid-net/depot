package handlers

import (
	"net/http"
	"testing"
)

func TestGuacamoleDisabled(t *testing.T) {

	testCases := []RestTestCase{
		{
			name:             "Login succesful saul",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/guacamole",
			reqMethod:        http.MethodGet,
			expectedBodyJSON: `{"guac_enabled":false}`,
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

func TestGuacamoleEnabled(t *testing.T) {

	testCases := []RestTestCase{
		{
			name:             "Login succesful saul",
			expResCode:       http.StatusOK,
			reqURL:           "/v1/guacamole",
			reqMethod:        http.MethodGet,
			expectedBodyJSON: `{"guac_enabled":true}`,
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
	settings.Guacamole = true
	e := EchoServer(settings)

	for _, tc := range testCases {
		runTests(t, tc, e)
	}
}
