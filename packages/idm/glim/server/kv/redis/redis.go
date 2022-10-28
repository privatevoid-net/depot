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

package redis

import (
	"context"
	"net"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
)

// Store implements kv.Store for Redis
type Store struct {
	DB *redis.Client
}

var ctx = context.Background()

// NewRedisStore creates a new connection with Redis
func NewRedisStore(host string, port int, password string, dbIndex int) (Store, error) {
	options := redis.Options{}
	options.Addr = net.JoinHostPort(host, strconv.Itoa(port))
	options.DB = dbIndex
	if password != "" {
		options.Password = password
	}

	s := Store{}
	rdb := redis.NewClient(&options)

	err := rdb.Set(ctx, "key", "value", 0).Err()
	if err != nil {
		return s, err
	}

	s.DB = rdb
	return s, nil
}

// Get a value from our key-value store
func (s Store) Get(k string) (v string, found bool, err error) {
	val, err := s.DB.Get(ctx, k).Result()

	if err != nil {
		if err == redis.Nil {
			return "", false, nil
		}
		return "", false, err
	}
	return val, true, nil
}

// Set a value for a given key
func (s Store) Set(k string, v string, expiration time.Duration) error {
	_, err := s.DB.SetNX(ctx, k, v, expiration).Result()
	return err
}

// Delete given key
func (s Store) Delete(k string) error {
	_, err := s.DB.SetNX(ctx, k, "", 1).Result()
	return err
}

// Close will terminate a connection with Redis
func (s Store) Close() error {
	return s.DB.Close()
}
