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

package ldap

import (
	"fmt"
	"strings"
	"time"

	"github.com/dchest/validator"
)

func GetDomain(domain string) string {
	const defaultDomain string = "dc=example,dc=org"

	if !validator.IsValidDomain(domain) {
		fmt.Printf("%s [Glim] ⇨ ldap domain does not contain a valid domain, using example.org...\n", time.Now().Format(time.RFC3339))
		return defaultDomain
	}

	ldapDomain := ""
	domainParts := strings.Split(domain, ".")
	for i, part := range domainParts {
		ldapDomain += fmt.Sprintf("dc=%s", part)
		if len(domainParts) != i+1 {
			ldapDomain += ","
		}
	}
	return ldapDomain
}
