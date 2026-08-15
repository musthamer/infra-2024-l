# TCP Protocol Specification

## Version

- Current version: V1

## Frame Format

Request:

VERSION|COMMAND|JOB_ID|PAYLOAD

Response:

ACK|VERSION|JOB_ID|STATUS
or
ERR|VERSION|JOB_ID|ERROR

## Commands

- PING
  - Request: V1|PING|<job_id>|-
  - Response: ACK|V1|<job_id>|PONG

- ENQUEUE_EMAIL
  - Request: V1|ENQUEUE_EMAIL|<job_id>|<base64_payload>
  - Response: ACK|V1|<job_id>|QUEUED

## Validation Rules

- VERSION must equal V1.
- JOB_ID must match: [A-Za-z0-9_-]{8,64}
- Unknown command -> ERR
- Malformed frame -> ERR
- Invalid payload -> ERR

## Payload (decoded)

For login simulation:

- type=login;email=<email>;session=<session_id>;ts=<unix_ts>

## Security Rules

- No eval of network input.
- Strict validation before DB write.
- Errors are generic, no credential leakage.
