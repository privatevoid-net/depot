/*
Copyright © 2022 Miguel Ángel Álvarez Cabrerizo <mcabrerizo@sologitops.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package badgerdb

import (
	"log"
	"os"
	"runtime"
	"time"

	"github.com/dgraph-io/badger"
)

// Store implements kv.Store for BadgerDB
type Store struct {
	DB *badger.DB
}

// NewBadgerStore creates a new connection with BadgerDB
func NewBadgerStore(path string) (Store, error) {
	s := Store{}
	// Key-value store for JWT tokens storage
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		err := os.MkdirAll(path, 0755)
		if err != nil {
			log.Fatal("Could not create directory for BadgerDB KV store")
		}
	}
	options := badger.DefaultOptions(path)
	options.Logger = nil

	// In Windows: To avoid "Value log truncate required to run DB. This might result in
	// data loss" we add the options.Truncate = true
	// Reference: https://discuss.dgraph.io/t/lock-issue-on-windows-on-exposed-api/6316.
	if runtime.GOOS == "windows" {
		options.Truncate = true
	}

	db, err := badger.Open(options)
	if err != nil {
		return s, err
	}

	s.DB = db
	return s, nil
}

// Get a value from our key-value store
func (s Store) Get(k string) (v string, found bool, err error) {
	var valCopy []byte
	err = s.DB.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(k))
		if err != nil {
			return err
		}

		valCopy, err = item.ValueCopy(nil)
		if err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		if err == badger.ErrKeyNotFound {
			return "", false, nil
		}
		return "", false, err
	}
	return string(valCopy), true, nil
}

// Set a value for a given key
func (s Store) Set(k string, v string, expiration time.Duration) error {
	err := s.DB.Update(func(txn *badger.Txn) error {
		e := badger.NewEntry([]byte(k), []byte(v)).WithTTL(expiration)
		err := txn.SetEntry(e)
		return err
	})
	return err
}

// Delete given key
func (s Store) Delete(k string) error {
	err := s.DB.Update(func(txn *badger.Txn) error {
		err := txn.Delete([]byte(k))
		return err
	})
	return err
}

// Close will terminate a connection with BadgerDB
func (s Store) Close() error {
	return s.DB.Close()
}
