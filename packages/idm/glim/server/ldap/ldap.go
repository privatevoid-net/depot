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
	"errors"
	"fmt"

	ber "github.com/go-asn1-ber/asn1-ber"
)

// Message - TODO comment
type Message struct {
	ID                      int64
	Op                      int64
	Request                 []*ber.Packet
	Paging                  bool
	PagedResultsSize        int64
	PagedResultsCookie      string
	PagedResultsCriticality bool
}

func messageID(p *ber.Packet) (int64, error) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagInteger ||
		len(p.Children) != 0 {
		return 0, errors.New("wrong message id definition")
	}

	id, err := ber.ParseInt64(p.ByteValue)
	if err != nil {
		return 0, errors.New("could not parse message id")
	}

	return id, nil
}

func protocolOp(p *ber.Packet) (int64, error) {
	if p.ClassType != ber.ClassApplication {
		return 0, errors.New("wrong protocol operation definition")
	}

	return int64(p.Tag), nil
}

func protocolVersion(p *ber.Packet) (int64, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagInteger ||
		len(p.Children) != 0 {
		return 0, &ServerError{
			Msg:  "wrong protocol version definition",
			Code: ProtocolError,
		}
	}

	v, err := ber.ParseInt64(p.ByteValue)
	if err != nil {
		return 0, &ServerError{
			Msg:  "could not parse protocol version",
			Code: Other,
		}
	}

	if v != Version3 {
		return 0, &ServerError{
			Msg:  "historical protocol version requested, use LDAPv3 instead",
			Code: ProtocolError,
		}
	}
	return v, nil
}

func requestName(p *ber.Packet) (string, *ServerError) {
	if p.ClassType != ber.ClassContext ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagEOC {
		return "", &ServerError{
			Msg:  "wrong extended request name definition",
			Code: ProtocolError,
		}
	}
	return p.Data.String(), nil
}

func control(p *ber.Packet, message *Message) error {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypeConstructed ||
		p.Tag != ber.TagSequence ||
		len(p.Children) < 2 {
		return errors.New("wrong ASN.1 Envelope for Control")
	}

	controlType := p.Children[0].Value.(string)

	//https://www.ietf.org/rfc/rfc2696.txt
	if controlType == "1.2.840.113556.1.4.319" {
		message.Paging = true
		npIndex := 1
		pagedResults := ""
		if p.Children[1].Tag == ber.TagBoolean {
			message.PagedResultsCriticality = p.Children[1].Value.(bool)
			pagedResults = "pagedResults critical control found"
			npIndex = 2
		} else {
			message.PagedResultsCriticality = false
			pagedResults = "pagedResults control found"
		}

		np := ber.DecodePacket(p.Children[npIndex].Data.Bytes())
		if len(np.Children) == 2 {
			message.PagedResultsSize = np.Children[0].Value.(int64)
			message.PagedResultsCookie = np.Children[1].Value.(string)
			printLog(fmt.Sprintf("%s: size=%d cookie=%s ", pagedResults, message.PagedResultsSize, message.PagedResultsCookie))
		}
		return nil
	}

	return nil
}

func controls(p *ber.Packet, message *Message) error {
	if p.ClassType != ber.ClassContext ||
		p.TagType != ber.TypeConstructed ||
		p.Tag != ber.TagEOC ||
		len(p.Children) < 1 {
		return errors.New("wrong ASN.1 Envelope for Controls")
	}

	for _, item := range p.Children {
		control(item, message)
	}

	return nil
}

//DecodeMessage - TODO comment
func DecodeMessage(p *ber.Packet) (*Message, error) {
	message := new(Message)

	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypeConstructed ||
		p.Tag != ber.TagSequence ||
		len(p.Children) < 2 {
		return nil, errors.New("wrong ASN.1 Envelope")
	}

	id, err := messageID(p.Children[0])
	if err != nil {
		return nil, err
	}
	message.ID = id

	op, err := protocolOp(p.Children[1])
	if err != nil {
		return nil, err
	}
	message.Op = op

	message.Request = p.Children[1].Children

	// Check if we have controls https://www.rfc-editor.org/rfc/rfc4511#section-4.1.11
	if len(p.Children) == 3 {
		controls(p.Children[2], message)
	}

	return message, nil
}
