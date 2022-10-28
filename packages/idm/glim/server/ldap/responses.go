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
	b64 "encoding/base64"

	ber "github.com/go-asn1-ber/asn1-ber"
)

// Every response has the message ID
func responseHeader(messageID int64) *ber.Packet {
	r := ber.Encode(
		ber.ClassUniversal,
		ber.TypeConstructed,
		ber.TagSequence,
		nil,
		"LDAP Response")

	// Message ID
	r.AppendChild(
		ber.NewInteger(
			ber.ClassUniversal,
			ber.TypePrimitive,
			ber.TagInteger,
			messageID,
			"MessageId"))

	return r
}

func encodeResponseType(t int) *ber.Packet {
	return ber.Encode(
		ber.ClassApplication,
		ber.TypeConstructed,
		ber.Tag(t),
		nil,
		protocolOps[t])
}

func encodeResultCode(code int64) *ber.Packet {
	return ber.NewInteger(
		ber.ClassUniversal,
		ber.TypePrimitive,
		ber.TagEnumerated,
		code,
		"Result Code")
}

func encodeOctetString(value string, description string) *ber.Packet {
	return ber.NewString(
		ber.ClassUniversal,
		ber.TypePrimitive,
		ber.TagOctetString,
		value,
		description)
}

func decodeBase64(base64 string) ([]byte, error) {
	decoded, err := b64.StdEncoding.DecodeString(base64)
	if err != nil {
		return nil, err
	}

	return decoded, nil
}

func encodeOctetBinaryString(value []byte, description string) *ber.Packet {
	binaryString := ber.Encode(ber.ClassUniversal, ber.TypePrimitive, ber.TagOctetString, nil, description)
	binaryString.Value = value
	binaryString.Data.Write(value)
	binaryString.ByteValue = value
	return binaryString
}

func encodeExtendedResponse(messageID int64, resultCode int64, name string, value string) *ber.Packet {
	// LDAP Message envelope
	r := responseHeader(messageID)

	// Response packet
	bp := encodeResponseType(ExtendedResponse)
	bp.AppendChild(encodeResultCode(resultCode))
	bp.AppendChild(encodeOctetString("", "MatchedDN"))
	bp.AppendChild(encodeOctetString("", "DiagnosticMessage"))
	r.AppendChild(bp)
	if name != "" {
		r.AppendChild(ber.NewString(
			ber.ClassContext,
			ber.TypePrimitive,
			ber.TagEnumerated, // responseName    [10] LDAPOID OPTIONAL 10 = TagEnumerated
			name,
			""))
	}

	if value != "" {
		r.AppendChild(ber.NewString(
			ber.ClassContext,
			ber.TypePrimitive,
			ber.TagEmbeddedPDV, // responseValue    [11] OCTET STRING OPTIONAL 11 = TagEmbeddedPDV
			value,
			""))
	}

	return r
}

func encodeBindResponse(messageID int64, resultCode int64, msg string) *ber.Packet {
	// LDAP Message envelope
	r := responseHeader(messageID)

	// Response packet
	bp := encodeResponseType(BindResponse)
	bp.AppendChild(encodeResultCode(resultCode))
	bp.AppendChild(encodeOctetString("", "MatchedDN"))
	bp.AppendChild(encodeOctetString(msg, "DiagnosticMessage"))
	r.AppendChild(bp)
	return r
}

func encodeSearchResultEntry(messageID int64, values map[string][]string, objectName string) *ber.Packet {
	// LDAP Message envelope
	r := responseHeader(messageID)

	// Attributes
	a := ber.NewSequence("attributes")
	for k, v := range values {
		al := ber.NewSequence("PartialAttributeList")
		al.AppendChild(encodeOctetString(k, "PartialAttributeType"))
		vs := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSet, nil, "PartialAttributeValues")
		for _, value := range v {
			if k == "jpegPhoto" || k == "jpegphoto" {
				jpeg, err := decodeBase64(value)
				if err == nil {
					vs.AppendChild(encodeOctetBinaryString(jpeg, "PartialAttributeValue"))
				}
			} else {
				vs.AppendChild(encodeOctetString(value, "PartialAttributeValue"))
			}
		}
		al.AppendChild(vs)
		a.AppendChild(al)
	}

	// Response packet
	bp := encodeResponseType(SearchResultEntry)
	bp.AppendChild(encodeOctetString(objectName, "objectName"))
	bp.AppendChild(a)
	r.AppendChild(bp)
	return r
}

func encodeControls(params searchResultDoneParams) *ber.Packet {

	controls := ber.Encode(ber.ClassContext, ber.TypeConstructed, ber.TagEOC, nil, "Controls")

	control := ber.NewSequence("control")
	control.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimitive, ber.TagOctetString, "1.2.840.113556.1.4.319", "controlType"))
	control.AppendChild(ber.NewBoolean(ber.ClassUniversal, ber.TypePrimitive, ber.TagBoolean, params.criticality, "criticality"))

	controlValue := ber.Encode(ber.ClassUniversal, ber.TypePrimitive, ber.TagOctetString, nil, "controlValue")
	searchControlValue := ber.NewSequence("searchControlValue")
	searchControlValue.AppendChild(ber.NewInteger(ber.ClassUniversal, ber.TypePrimitive, ber.TagInteger, 0, "size"))
	cookie := ber.Encode(ber.ClassUniversal, ber.TypePrimitive, ber.TagOctetString, params.cookie, "cookie")
	searchControlValue.AppendChild(cookie)
	controlValue.AppendChild(searchControlValue)
	control.AppendChild(controlValue)

	controls.AppendChild(control)
	return controls
}

type searchResultDoneParams struct {
	messageID    int64
	resultCode   int64
	msg          string
	paging       bool
	totalResults int64
	criticality  bool
	cookie       string
}

func encodeSearchResultDone(params searchResultDoneParams) *ber.Packet {
	// LDAP Message envelope
	r := responseHeader(params.messageID)

	// Response packet
	bp := encodeResponseType(SearchResultDone)
	bp.AppendChild(encodeResultCode(params.resultCode))
	bp.AppendChild(encodeOctetString("", "MatchedDN"))
	bp.AppendChild(encodeOctetString(params.msg, "DiagnosticMessage"))

	// Add response packet to LDAP Message
	r.AppendChild(bp)

	// Append controls to LDAP Message
	if params.paging {
		r.AppendChild(encodeControls(params))
	}
	return r
}
