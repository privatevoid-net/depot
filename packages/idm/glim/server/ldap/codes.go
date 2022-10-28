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

// Operation codes defined in RFC 4511
// BindRequest = 0
const (
	BindRequest           = 0
	BindResponse          = 1
	UnbindRequest         = 2
	SearchRequest         = 3
	SearchResultEntry     = 4
	SearchResultDone      = 5
	ModifyRequest         = 6
	ModifyResponse        = 7
	AddRequest            = 8
	AddResponse           = 9
	DelRequest            = 10
	DelResponse           = 11
	ModifyDNRequest       = 12
	ModifyDNResponse      = 13
	CompareRequest        = 14
	CompareResponse       = 15
	AbandonRequest        = 16
	SearchResultReference = 19
	ExtendedRequest       = 23
	ExtendedResponse      = 24
	IntermediateResponse  = 25
)

var protocolOps = map[int]string{
	0:  "BindRequest",
	1:  "BindResponse",
	2:  "UnbindRequest",
	3:  "SearchRequest",
	4:  "SearchResultEntry",
	5:  "SearchResultDone",
	6:  "ModifyRequest",
	7:  "ModifyResponse",
	8:  "AddRequest",
	9:  "AddResponse",
	10: "DelRequest",
	11: "DelResponse",
	12: "ModifyDNRequest",
	13: "ModifyDNResponse",
	14: "CompareRequest",
	15: "CompareResponse",
	16: "AbandonRequest",
	19: "SearchResultReference",
	23: "ExtendedRequest",
	24: "ExtendedResponse",
	25: "IntermediateResponse",
}

// LDAP result codes defined in RFC 4511
// See: https://tools.ietf.org/html/rfc4511#page-18
const (
	Success                      = 0
	OperationsError              = 1
	ProtocolError                = 2
	TimeLimitExceeded            = 3
	SizeLimitExceeded            = 4
	CompareFalse                 = 5
	CompareTrue                  = 6
	AuthMethodNotSupported       = 7
	StrongerAuthRequired         = 8
	Referral                     = 10
	AdminLimitExceeded           = 11
	UnavailableCriticalExtension = 12
	ConfidentialityRequired      = 13
	SaslBindInProgress           = 14
	NoSuchAttribute              = 16
	UndefinedAttributeType       = 17
	InappropriateMatching        = 18
	ConstraintViolation          = 19
	AttributeOrValueExists       = 20
	InvalidAttributeSyntax       = 21
	NoSuchObject                 = 32
	AliasProblem                 = 33
	InvalidDNSyntax              = 34
	AliasDereferencingProblem    = 36
	InappropriateAuthentication  = 48
	InvalidCredentials           = 49
	InsufficientAccessRights     = 50
	Busy                         = 51
	Unavailable                  = 52
	UnwillingToPerform           = 53
	LoopDetect                   = 54
	NamingViolation              = 64
	ObjectClassViolation         = 65
	NotAllowedOnNonLeaf          = 66
	NotAllowedOnRDN              = 67
	EntryAlreadyExists           = 68
	ObjectClassModsProhibited    = 69
	AffectsMultipleDSAs          = 71
	Other                        = 80
)

// Authentication Choices defined in RFC 4511
const (
	Simple = 0
	Sasl   = 3
)

// Version3 - Supported LDAP Protocol version 3
const Version3 = 3

// WhoamIOID - OID defined for whoami in RFC 4532
const WhoamIOID = "1.3.6.1.4.1.4203.1.11.3"

// Scopes defined in RFC 4511
const (
	BaseObject   = 0
	SingleLevel  = 1
	WholeSubtree = 2
)

var scopes = map[int64]string{
	0: "baseObject",
	1: "singleLevel",
	2: "wholeSubtree",
}

//
const (
	FilterAnd             = 0
	FilterOr              = 1
	FilterNot             = 2
	FilterEquality        = 3
	FilterSubstrings      = 4
	FilterGreaterOrEqual  = 5
	FilterLessOrEqual     = 6
	FilterPresent         = 7
	FilterApproxMatch     = 8
	FilterExtensibleMatch = 9
)
