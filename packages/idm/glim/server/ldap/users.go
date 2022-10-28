package ldap

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/doncicuto/glim/models"
	ber "github.com/go-asn1-ber/asn1-ber"
	"gorm.io/gorm"
)

type userQueryParams struct {
	db             *gorm.DB
	filter         string
	originalFilter string
	attributes     string
	messageID      int64
	domain         string
	limit          int
	offset         int
}

func userEntry(user models.User, attributes string, domain string) map[string][]string {
	attrs := make(map[string]string)
	for _, a := range strings.Split(attributes, " ") {
		attrs[a] = a
	}

	_, operational := attrs["+"]

	values := map[string][]string{}

	_, ok := attrs["structuralObjectClass"]
	if ok || operational {
		values["structuralObjectClass"] = []string{"inetOrgPerson"}
	}

	_, ok = attrs["entryUUID"]
	if ok || operational {
		values["entryUUID"] = []string{*user.UUID}
	}

	_, ok = attrs["creatorsName"]
	if ok || operational {
		creator := *user.CreatedBy
		createdBy := ""
		if creator == "admin" {
			createdBy = fmt.Sprintf("cn=admin,%s", domain)
		} else {
			createdBy = fmt.Sprintf("uid=%s,ou=Users,%s", creator, domain)
		}
		values["creatorsName"] = []string{createdBy}
	}

	_, ok = attrs["createTimestamp"]
	if ok || operational {
		values["createTimestamp"] = []string{user.CreatedAt.Format("20060102150405Z")}
	}

	_, ok = attrs["creatorsName"]
	if ok || operational {
		modifier := *user.UpdatedBy
		updatedBy := ""
		if modifier == "admin" {
			updatedBy = fmt.Sprintf("cn=admin,%s", domain)
		} else {
			updatedBy = fmt.Sprintf("uid=%s,ou=Users,%s", modifier, domain)
		}
		values["modifiersName"] = []string{updatedBy}
	}

	_, ok = attrs["modifyTimestamp"]
	if ok || operational {
		values["modifyTimestamp"] = []string{user.UpdatedAt.Format("20060102150405Z")}
	}

	_, ok = attrs["objectClass"]
	if attributes == "ALL" || ok || operational {
		values["objectClass"] = []string{"top", "person", "inetOrgPerson", "organizationalPerson", "ldapPublicKey", "posixAccount"}
	}

	if attributes == "ALL" || attrs["uid"] != "" || attrs["inetOrgPerson"] != "" || operational {
		if user.Username != nil {
			values["uid"] = []string{*user.Username}
		}
	}

	if attributes == "ALL" || attrs["cn"] != "" || attrs["inetOrgPerson"] != "" || operational {
		if user.GivenName != nil && user.Surname != nil {
			values["cn"] = []string{*user.Name}
		}
	}

	_, ok = attrs["sn"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.Surname != nil {
			values["sn"] = []string{*user.Surname}
		}
	}

	_, ok = attrs["givenName"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.GivenName != nil {
			values["givenName"] = []string{*user.GivenName}
		}
	}

	_, ok = attrs["mail"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.Email != nil {
			values["mail"] = []string{*user.Email}
		}
	}

	_, ok = attrs["SshPublicKey"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.SSHPublicKey != nil {
			values["SshPublicKey"] = []string{*user.SSHPublicKey}
		}
	}

	_, ok = attrs["jpegPhoto"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.JPEGPhoto != nil {
			values["jpegPhoto"] = []string{*user.JPEGPhoto}
		}
	}

	_, ok = attrs["jpegphoto"]
	if attributes == "ALL" || ok || attrs["inetOrgPerson"] != "" || operational {
		if user.JPEGPhoto != nil {
			values["jpegphoto"] = []string{*user.JPEGPhoto}
		}
	}
	_, ok = attrs["memberof"]
	if attributes == "ALL" || ok {
		groups := []string{}
		for _, memberOf := range user.MemberOf {
			groups = append(groups, fmt.Sprintf("cn=%s,ou=Groups,dc=example,dc=org", *memberOf.Name))
		}

		values["memberof"] = groups
	}

	_, ok = attrs["memberOf"]
	if attributes == "ALL" || ok {
		groups := []string{}
		for _, memberOf := range user.MemberOf {
			groups = append(groups, fmt.Sprintf("cn=%s,ou=Groups,dc=example,dc=org", *memberOf.Name))
		}

		_, ok = attrs["memberof"]
		if attributes == "ALL" || ok {
			delete(values, "memberof")
		}
		values["memberOf"] = groups
	}

	_, ok = attrs["entryDN"]
	if ok || operational {
		if user.Username != nil {
			values["entryDN"] = []string{fmt.Sprintf("uid=%s,ou=Users,%s", *user.Username, domain)}
		}
	}

	_, ok = attrs["subschemaSubentry"]
	if ok || operational {
		values["subschemaSubentry"] = []string{"cn=Subschema"}
	}

	_, ok = attrs["hasSubordinates"]
	if ok || operational {
		values["hasSubordinates"] = []string{"FALSE"}
	}

	return values
}

func getUsersFromDB(params userQueryParams) ([]*ber.Packet, *ServerError, int, int64) {
	var r []*ber.Packet
	users := []models.User{}

	params.db = params.db.Preload("MemberOf").Model(&models.User{})
	analyzeUsersCriteria(params.db, params.filter, false, "", 0)

	allResults := params.db.Find(&users)
	if allResults.Error != nil {
		return nil, &ServerError{
			Msg:  "could not retrieve information from database",
			Code: Other,
		}, 0, 0
	}
	totalResults := allResults.RowsAffected

	if params.limit > 0 {
		params.db.Limit(params.limit)
	}

	params.db.Offset(params.offset)

	err := params.db.Find(&users).Error
	if err != nil {
		return nil, &ServerError{
			Msg:  "could not retrieve information from database",
			Code: Other,
		}, 0, 0
	}

	filterGroup, _ := regexp.Compile(fmt.Sprintf("member[oO]f=cn=([A-Za-z.0-9-]+),ou=Groups,%s", params.domain))
	matches := []string{}
	if filterGroup.MatchString(params.originalFilter) {
		matches = filterGroup.FindAllString(params.originalFilter, -1)
	}

	for _, user := range users {
		if *user.Username != "admin" && !*user.Readonly {
			if len(matches) > 0 {
			GroupsLoop:
				for _, group := range user.MemberOf {
					for _, match := range matches {
						if fmt.Sprintf("memberOf=cn=%s,ou=Groups,%s", *group.Name, params.domain) == match || fmt.Sprintf("memberof=cn=%s,ou=Groups,%s", *group.Name, params.domain) == match {
							dn := fmt.Sprintf("uid=%s,ou=Users,%s", *user.Username, params.domain)
							values := userEntry(user, params.attributes, params.domain)
							e := encodeSearchResultEntry(params.messageID, values, dn)
							r = append(r, e)
							break GroupsLoop
						}
					}
				}
			} else {
				dn := fmt.Sprintf("uid=%s,ou=Users,%s", *user.Username, params.domain)
				values := userEntry(user, params.attributes, params.domain)
				e := encodeSearchResultEntry(params.messageID, values, dn)
				r = append(r, e)
			}
		}

	}

	return r, nil, len(users), totalResults
}

func analyzeUsersCriteria(db *gorm.DB, filter string, boolean bool, booleanOperator string, index int) {
	if boolean {

		re := regexp.MustCompile(`\(\|(.*)\)|\(\&(.*)\)|\(\!(.*)\)|\(([a-zA-Z=\ \.*]*)\)*`)
		submatchall := re.FindAllString(filter, -1)

		for index, element := range submatchall {
			element = strings.TrimPrefix(element, "(")
			element = strings.TrimSuffix(element, ")")
			analyzeUsersCriteria(db, element, false, booleanOperator, index)
		}

	} else {
		switch {
		case strings.HasPrefix(filter, "(") && strings.HasSuffix(filter, ")"):
			element := strings.TrimPrefix(filter, "(")
			element = strings.TrimSuffix(element, ")")
			analyzeUsersCriteria(db, element, false, "", 0)

		case strings.HasPrefix(filter, "&"):
			element := strings.TrimPrefix(filter, "&")
			analyzeUsersCriteria(db, element, true, "and", 0)

		case strings.HasPrefix(filter, "|"):
			element := strings.TrimPrefix(filter, "|")
			analyzeUsersCriteria(db, element, true, "or", 0)

		case strings.HasPrefix(filter, "!"):
			element := strings.TrimPrefix(filter, "!")
			analyzeUsersCriteria(db, element, true, "not", 0)

		case strings.HasPrefix(filter, "uid="):
			element := strings.TrimPrefix(filter, "uid=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("username LIKE ?", element)
				} else {
					db.Or("username LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("username = ?", element)
				} else {
					db.Or("username = ?", element)
				}
			}

		case strings.HasPrefix(filter, "mail="):
			element := strings.TrimPrefix(filter, "mail=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("email LIKE ?", element)
				} else {
					db.Or("email LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("email = ?", element)
				} else {
					db.Or("email = ?", element)
				}
			}

		case strings.HasPrefix(filter, "email="):
			element := strings.TrimPrefix(filter, "email=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("email LIKE ?", element)
				} else {
					db.Or("email LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("email = ?", element)
				} else {
					db.Or("email = ?", element)
				}
			}

		case strings.HasPrefix(filter, "sn="):
			element := strings.TrimPrefix(filter, "sn=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("surname LIKE ?", element)
				} else {
					db.Or("surname LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("surname = ?", element)
				} else {
					db.Or("surname = ?", element)
				}
			}

		case strings.HasPrefix(filter, "givenName="):
			element := strings.TrimPrefix(filter, "givenName=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("given_name LIKE ?", element)
				} else {
					db.Or("given_name LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("given_name = ?", element)
				} else {
					db.Or("given_name = ?", element)
				}
			}

		case strings.HasPrefix(filter, "cn="):
			element := strings.TrimPrefix(filter, "cn=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("name LIKE ?", element)
				} else {
					db.Or("name LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("name = ?", element)
				} else {
					db.Or("name = ?", element)
				}
			}

		case strings.HasPrefix(filter, "SshPublicKey="):
			element := strings.TrimPrefix(filter, "SshPublicKey=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("ssh_public_key LIKE ?", element)
				} else {
					db.Or("ssh_public_key LIKE ?", element)
				}
			} else {
				if index == 0 {
					db.Where("ssh_public_key = ?", element)
				} else {
					db.Or("ssh_public_key = ?", element)
				}
			}
		case strings.HasPrefix(filter, "jpegPhoto="):
			element := strings.TrimPrefix(filter, "jpegPhoto=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("jpeg_photo LIKE ?", element)
				} else {
					db.Or("jpeg_photo LIKE ?", element)
				}
			} else {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("jpeg_photo = ?", element)
				} else {
					db.Or("jpeg_photo = ?", element)
				}
			}
		}

	}
}
