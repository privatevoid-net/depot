package ldap

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/doncicuto/glim/types"
	ber "github.com/go-asn1-ber/asn1-ber"
	"github.com/google/uuid"
)

func searchSize(p *ber.Packet, searchLimit int, pagedResultSize int64) (int, *ServerError) {
	limit := 0
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagInteger {
		return 0, &ServerError{
			Msg:  "wrong search size definition",
			Code: ProtocolError,
		}
	}

	size, err := ber.ParseInt64(p.ByteValue)
	if err != nil {
		return 0, &ServerError{
			Msg:  "could not parse search size",
			Code: Other,
		}
	}

	if size < pagedResultSize {
		limit = int(pagedResultSize)
	} else {
		limit = int(size)
	}

	return limit, nil
}

func searchTimeLimit(p *ber.Packet) (int64, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagInteger {
		return 0, &ServerError{
			Msg:  "wrong search time limit definition",
			Code: ProtocolError,
		}
	}

	timeLimit, err := ber.ParseInt64(p.ByteValue)
	if err != nil {
		return 0, &ServerError{
			Msg:  "could not parse search time limit",
			Code: Other,
		}
	}

	return timeLimit, nil
}

func searchTypesOnly(p *ber.Packet) (bool, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagBoolean {
		return false, &ServerError{
			Msg:  "wrong types only definition",
			Code: ProtocolError,
		}
	}

	t := p.Value.(bool)
	return t, nil
}

func searchFilter(p *ber.Packet) (string, *ServerError) {
	filter, err := decodeFilters(p)
	if err != nil {
		return "", &ServerError{
			Msg:  "wrong search filter definition",
			Code: ProtocolError,
		}
	}
	return filter, nil
}

func decodeAssertionValue(p *ber.Packet) (string, *ServerError) {
	filter := ""
	if p.Tag == ber.TagOctetString {
		filter += fmt.Sprintf("%v", p.Value)
	}
	// WORKAROUND: We're having a problem with filters including asterisks
	// If we ask for *Cabrerizo* BER request is removing the second asterisk
	// so as a workaround we're using two asterisks to avoid missing results
	if p.Tag == ber.TagSequence && len(p.Children) == 1 {
		filter += fmt.Sprintf("=*%v*", p.Children[0].Data)
	}
	return filter, nil
}

func decodeSubstringFilter(p *ber.Packet) (string, *ServerError) {
	filter := "("

	if p.ClassType != ber.ClassContext ||
		p.TagType != ber.TypeConstructed && p.Tag != ber.TagOctetString {
		return "", &ServerError{
			Msg:  "wrong search filter definition",
			Code: ProtocolError,
		}
	}

	for _, f := range p.Children {
		df, err := decodeAssertionValue(f)

		if err != nil {
			return "", &ServerError{
				Msg:  "wrong search filter definition",
				Code: ProtocolError,
			}
		}
		filter += df
	}

	filter += ")"
	return filter, nil
}

func decodeFilters(p *ber.Packet) (string, *ServerError) {
	filter := ""

	if p.ClassType != ber.ClassContext ||
		((p.TagType != ber.TypeConstructed && p.Tag != ber.TagEOC) &&
			(p.TagType != ber.TypePrimitive && p.Tag != ber.TagObjectDescriptor && p.Tag != ber.TagSequence)) {
		return "", &ServerError{
			Msg:  "wrong search filter definition",
			Code: ProtocolError,
		}
	}

	switch p.Tag {
	case FilterAnd:
		filter += "(&"
		for _, f := range p.Children {
			df, err := decodeFilters(f)
			if err != nil {
				return "", &ServerError{
					Msg:  "wrong search filter definition",
					Code: ProtocolError,
				}
			}
			filter += df
		}
		filter += ")"

	case FilterOr:
		filter += "(|"

		for _, f := range p.Children {
			df, err := decodeFilters(f)
			if err != nil {
				return "", &ServerError{
					Msg:  "wrong search filter definition",
					Code: ProtocolError,
				}
			}
			filter += df
		}
		filter += ")"

	case FilterNot:
		filter += "(!"

		for _, f := range p.Children {
			df, err := decodeFilters(f)
			if err != nil {
				return "", &ServerError{
					Msg:  "wrong search filter definition",
					Code: ProtocolError,
				}
			}
			filter += df
		}
		filter += ")"
	case FilterEquality:
		if len(p.Children) != 2 {
			return "", &ServerError{
				Msg:  "wrong search filter definition",
				Code: ProtocolError,
			}
		}
		filter = fmt.Sprintf("(%v=%v)", p.Children[0].Value, p.Children[1].Value)

	case FilterSubstrings:
		df, err := decodeSubstringFilter(p)
		if err != nil {
			return "", &ServerError{
				Msg:  "wrong search filter definition",
				Code: ProtocolError,
			}
		}
		filter += df

	case FilterPresent:
		filter = fmt.Sprintf("(%v=*)", p.Data)
	default:
		printLog(fmt.Sprintf("substring %v, %v", p.Tag, p.TagType))
	}

	return filter, nil
}

func searchAttributes(p *ber.Packet) (string, *ServerError) {
	var attributes []string

	// &{{0 32 16} <nil> []  [] }
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypeConstructed ||
		p.Tag != ber.TagSequence {
		return "", &ServerError{
			Msg:  "wrong attributes definition",
			Code: ProtocolError,
		}
	}

	if len(p.Children) == 0 {
		return "ALL", nil
	}

	for _, att := range p.Children {
		attributes = append(attributes, att.Value.(string))
	}

	return strings.Join(attributes, " "), nil
}

func baseObject(p *ber.Packet) (string, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagOctetString {
		return "", &ServerError{
			Msg:  "wrong search base object definition",
			Code: ProtocolError,
		}
	}
	return p.Data.String(), nil
}

func searchScope(p *ber.Packet) (int64, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagEnumerated {
		return 0, &ServerError{
			Msg:  "wrong search scope definition",
			Code: ProtocolError,
		}
	}

	scope, err := ber.ParseInt64(p.ByteValue)
	if err != nil {
		return 0, &ServerError{
			Msg:  "could not parse search scope",
			Code: Other,
		}
	}

	if scope != BaseObject && scope != SingleLevel && scope != WholeSubtree {
		return 0, &ServerError{
			Msg:  "wrong search scope option",
			Code: ProtocolError,
		}
	}

	return scope, nil
}

// HandleSearchRequest - TODO comment
func HandleSearchRequest(message *Message, settings types.LDAPSettings) ([]*ber.Packet, error) {

	// Defined in https://www.rfc-editor.org/rfc/rfc4511#section-4.5.1
	var offset = 0
	var cookie = ""
	var totalResults int64 = 0
	var nResults int = 0
	var users []*ber.Packet = nil
	var groups []*ber.Packet = nil

	var r []*ber.Packet
	id := message.ID
	p := message.Request

	// Paging
	if message.Paging && message.PagedResultsCookie != "" {
		val, found, err := settings.KV.Get(message.PagedResultsCookie)
		if err != nil {
			p := encodeSearchResultDone(searchResultDoneParams{
				messageID:    id,
				resultCode:   UnwillingToPerform,
				msg:          "could not find cookie in KV",
				paging:       message.PagedResultsSize > 0,
				totalResults: 0,
				criticality:  message.PagedResultsCriticality,
				cookie:       cookie,
			})
			r = append(r, p)
			return r, errors.New("KV not working correctly")
		}

		if found {
			cookie = message.PagedResultsCookie
			offset, err = strconv.Atoi(val)
			if err != nil {
				p := encodeSearchResultDone(searchResultDoneParams{
					messageID:    id,
					resultCode:   UnwillingToPerform,
					msg:          "could not get offset from KV",
					paging:       message.PagedResultsSize > 0,
					totalResults: 0,
					criticality:  message.PagedResultsCriticality,
					cookie:       cookie,
				})
				r = append(r, p)
				return r, errors.New("KV not working correctly")
			}
		}
	}

	b, err := baseObject(p[0])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search base object: %s", b))

	//Check if base object is valid
	reg, _ := regexp.Compile(fmt.Sprintf("%s$", settings.Domain))
	if !reg.MatchString(b) {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   NoSuchObject,
			msg:          "",
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New("wrong settings.Domain")
	}

	s, err := searchScope(p[1])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})

		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search scope: %s", scopes[s]))

	// p[2] represents derefAliases which are not currently supported by Glim

	n, err := searchSize(p[3], settings.SizeLimit, message.PagedResultsSize)
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search maximum number of entries to be returned (0 - No limit restriction): %d", n))

	l, err := searchTimeLimit(p[4])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search maximum time limit (0 - No limit restriction): %d", l))

	t, err := searchTypesOnly(p[5])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search show types only: %t", t))

	f, err := searchFilter(p[6])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	printLog(fmt.Sprintf("search filter: %s", f))

	a, err := searchAttributes(p[7])
	if err != nil {
		p := encodeSearchResultDone(searchResultDoneParams{
			messageID:    id,
			resultCode:   err.Code,
			msg:          err.Msg,
			paging:       message.PagedResultsSize > 0,
			totalResults: 0,
			criticality:  message.PagedResultsCriticality,
			cookie:       cookie,
		})
		r = append(r, p)
		return r, errors.New(err.Msg)
	}
	attrs := make(map[string]string)
	for _, a := range strings.Split(a, " ") {
		attrs[a] = a
	}
	printLog(fmt.Sprintf("search attributes: %s", a))

	/* RFC 4511 - The results of the Search operation are returned as zero or more
	    SearchResultEntry and/or SearchResultReference messages, followed by
		a single SearchResultDone message */

	regBase, _ := regexp.Compile(fmt.Sprintf("^ou=users,%s$", settings.Domain))

	if (b == settings.Domain && strings.Contains(f, "objectClass=*")) || regBase.MatchString(strings.ToLower(b)) {
		if (f == "(objectclass=*)" && !message.Paging) || (f == "(objectclass=*)" && message.Paging && offset == 0) {
			ouUsers := fmt.Sprintf("ou=Users,%s", settings.Domain)
			values := map[string][]string{
				"objectClass": {"organizationalUnit", "top"},
				"ou":          {"Users"},
			}
			e := encodeSearchResultEntry(id, values, ouUsers)
			r = append(r, e)
		}

		params := userQueryParams{
			db:             settings.DB,
			filter:         f,
			originalFilter: f,
			attributes:     a,
			messageID:      id,
			domain:         settings.Domain,
			limit:          n,
			offset:         offset,
		}

		users, err, nResults, totalResults = getUsersFromDB(params)
		if err != nil {
			return r, errors.New(err.Msg)
		}
		r = append(r, users...)
	}

	regBase, _ = regexp.Compile(fmt.Sprintf("^uid=([A-Za-z.0-9-]+),ou=users,%s$", settings.Domain))
	if regBase.MatchString(strings.ToLower(b)) {
		matches := regBase.FindStringSubmatch(strings.ToLower(b))
		if matches != nil {
			params := userQueryParams{
				db:             settings.DB,
				filter:         fmt.Sprintf("uid=%s", matches[1]),
				originalFilter: f,
				attributes:     a,
				messageID:      id,
				domain:         settings.Domain,
				limit:          n,
				offset:         offset,
			}

			users, err, nResults, totalResults = getUsersFromDB(params)
			if err != nil {
				return r, errors.New(err.Msg)
			}

			r = append(r, users...)
		}
	}

	regBase, _ = regexp.Compile(fmt.Sprintf("^ou=groups,%s$", settings.Domain))
	if (b == settings.Domain && strings.Contains(f, "objectClass=*")) || regBase.MatchString(strings.ToLower(b)) {
		if (f == "(objectclass=*)" && !message.Paging) || (f == "(objectclass=*)" && message.Paging && offset == 0) {
			ouGroups := fmt.Sprintf("ou=Groups,%s", settings.Domain)
			values := map[string][]string{
				"objectClass": {"organizationalUnit", "top"},
				"ou":          {"Groups"},
			}
			e := encodeSearchResultEntry(id, values, ouGroups)
			r = append(r, e)
		}

		params := groupQueryParams{
			db:             settings.DB,
			filter:         f,
			originalFilter: f,
			attributes:     a,
			id:             id,
			domain:         settings.Domain,
			limit:          n,
			offset:         offset,
			guacamole:      settings.Guacamole,
		}

		groups, err, nResults, totalResults = getGroupsFromDB(params)
		if err != nil {
			return r, errors.New(err.Msg)
		}
		r = append(r, groups...)
	}

	regBase, _ = regexp.Compile(fmt.Sprintf("^cn=([A-Za-z.0-9-]+),ou=groups,%s$", settings.Domain))
	if regBase.MatchString(strings.ToLower(b)) {
		matches := regBase.FindStringSubmatch(strings.ToLower(b))
		if matches != nil {

			params := groupQueryParams{
				db:             settings.DB,
				filter:         fmt.Sprintf("cn=%s", matches[1]),
				originalFilter: f,
				attributes:     a,
				id:             id,
				domain:         settings.Domain,
				limit:          n,
				offset:         offset,
				guacamole:      settings.Guacamole,
			}

			groups, err, nResults, totalResults = getGroupsFromDB(params)
			if err != nil {
				return r, errors.New(err.Msg)
			}
			r = append(r, groups...)
		}
	}

	// Paging
	if message.Paging {
		// More results?
		if offset+nResults < int(totalResults) {
			// Create a cookie and store current offset
			if cookie == "" {
				cookie = uuid.New().String()
			}

			err := settings.KV.Set(cookie, fmt.Sprintf("%d", offset+nResults), time.Second*3600)
			if err != nil {
				p := encodeSearchResultDone(searchResultDoneParams{
					messageID:    id,
					resultCode:   UnwillingToPerform,
					msg:          "KV not working correctly 1",
					paging:       message.PagedResultsSize > 0,
					totalResults: 0,
					criticality:  message.PagedResultsCriticality,
					cookie:       cookie,
				})
				r = append(r, p)
				return r, errors.New("KV not working correctly")
			}
		} else {
			if cookie != "" {
				err := settings.KV.Delete(cookie)
				if err != nil {
					p := encodeSearchResultDone(searchResultDoneParams{
						messageID:    id,
						resultCode:   UnwillingToPerform,
						msg:          "KV not working correctly 2",
						paging:       message.PagedResultsSize > 0,
						totalResults: 0,
						criticality:  message.PagedResultsCriticality,
						cookie:       cookie,
					})
					r = append(r, p)
					return r, errors.New("KV not working correctly")
				}
			}
			cookie = ""
		}
	}

	d := encodeSearchResultDone(searchResultDoneParams{
		messageID:    id,
		resultCode:   Success,
		msg:          "",
		paging:       message.PagedResultsSize > 0,
		totalResults: totalResults,
		criticality:  message.PagedResultsCriticality,
		cookie:       cookie,
	})
	r = append(r, d)
	return r, nil
}
