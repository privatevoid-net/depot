#!/bin/bash

test_description="Test service + ctl SSL interaction"

config="`pwd`/config/ssl-basic_auth"

. lib/test-lib.sh

test_ipfs_init
test_cluster_init "$config"

test_expect_success "prerequisites" '
    test_have_prereq IPFS && test_have_prereq CLUSTER
'

test_expect_success "ssl interaction fails with bad credentials" '
    id=`cluster_id`
    { test_must_fail ipfs-cluster-ctl --no-check-certificate --basic-auth "testuser:badpass" id; } | grep -A1 "401" | grep -i "unauthorized"
'

test_expect_success "ssl interaction succeeds" '
    id=`cluster_id`
    ipfs-cluster-ctl --no-check-certificate --basic-auth "testuser:testpass" id | egrep -q "$id"
'

test_clean_ipfs
test_clean_cluster

test_done
