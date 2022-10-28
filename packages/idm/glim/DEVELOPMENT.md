# Development Notes

## Swagger - OpenAPI documentation

In order to generate Swagger documentation, I've to run `swag init -g server/api/server.go -o docs/api` and then `go build` and re-run the server.

Currently `swag` doesn't support OpenAPI v3 so authentication with JWT tokens is not directly supported. As explained in [https://stackoverflow.com/questions/32910065/how-can-i-represent-authorization-bearer-token-in-a-swagger-spec-swagger-j](https://stackoverflow.com/questions/32910065/how-can-i-represent-authorization-bearer-token-in-a-swagger-spec-swagger-j) we may login putting Bearer before our token and then we can try our endpoints.

Related: [https://github.com/swaggo/swag/issues/709](https://github.com/swaggo/swag/issues/709)

## Vulnerability checks

```bash
govulncheck ./...
```
