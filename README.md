# In-Memory Key-Value Store

A small in-memory key-value store implemented in Erlang and exposed through an HTTP REST API using [Cowboy](https://github.com/ninenines/cowboy).

The project implements the core operations required by the assignment: setting a value for a key, retrieving a value, and removing a key.

## Features

- Store a value under a key.
- Retrieve the value associated with a key.
- Remove a key and its value.
- Return `404 Not Found` when a requested key does not exist.
- Return `503 Service Unavailable` when a storage operation times out.
- Provide a health-check endpoint.
- Handle concurrent requests through a dedicated Erlang process that owns the in-memory map.
- Include EUnit tests for map and storage behaviour.

## Requirements

- Erlang/OTP
- Rebar3

Cowboy is declared as a Rebar3 dependency and is fetched during the build.

## Build

From the repository root, run:

```shell
rebar3 compile
```

## Run the tests

Run the EUnit test suite:

```shell
rebar3 eunit
```

The current test suite contains 12 test cases covering map operations, setting and getting values, overwriting values, missing keys, clearing keys, independent store instances, timeout behaviour, process termination detection, and concurrent writes to different keys.
The HTTP endpoints have been tested manually; automated HTTP integration tests are not currently included.

## Start the application

Start the Rebar3 shell from the repository root:

```shell
rebar3 shell
```

Then run the following Erlang command:

```erlang
memory_store_app:start().
```

This function starts Cowboy and its dependencies, creates the in-memory storage process, and starts the HTTP listener.

The HTTP server listens on port `8080`.

To check that the server is responding, open `http://localhost:8080/health` or run:

```shell
curl http://localhost:8080/health
```

Expected response body:

```text
ok
```

## HTTP API

All key-value endpoints use the `/store/:key` path, where `:key` is the key to operate on. The API accepts and returns plain text; it does not use JSON.

### Health check

**Request**

```http
GET /health
```

**Success response**

- Status: `200 OK`
- Content type: `text/plain`
- Body: `ok`

### Retrieve a value

**Request**

```http
GET /store/name
```

If the key exists, the server returns `200 OK` with a plain-text body containing the key and value:

```text
key=name
value=John
```

If the key does not exist, the server returns `404 Not Found` with body `Not Found`.

If the storage operation times out, the server returns `503 Service Unavailable` with body `Service Unavailable`.

### Set a value

**Request**

```http
PUT /store/name
Content-Type: text/plain

John
```

The request body is stored as the value associated with the key `name`.

On success, the server returns `204 No Content` with an empty response body. If the storage operation times out, it returns `503 Service Unavailable`.

Example using `curl`:

```shell
curl -i -X PUT http://localhost:8080/store/name \
  -H "Content-Type: text/plain" \
  --data "John"
```

### Remove a value

**Request**

```http
DELETE /store/name
```

If the key exists and is removed, the server returns `204 No Content`.

If the key does not exist, the server returns `404 Not Found` with body `Not Found`.

If the storage operation times out, the server returns `503 Service Unavailable`.

Example using `curl`:

```shell
curl -i -X DELETE http://localhost:8080/store/name
```

### Unsupported methods

Methods other than `GET`, `PUT`, and `DELETE` on `/store/:key` return `405 Method Not Allowed`. The response includes an `Allow` header listing the supported methods.

## Timeout behaviour

Storage operations invoked through the HTTP API use a default timeout of **5 seconds**. This timeout is not configurable through the REST API.

If an operation does not return a response within the timeout, the HTTP handler returns `503 Service Unavailable`. A timeout does not necessarily mean that the operation was not executed: the storage process may still process a request after the caller has stopped waiting for its response.

## Design

The storage process owns an Erlang map and handles one message at a time. HTTP handlers send operations to this process rather than modifying the map directly. This serializes storage operations and avoids concurrent writes to the same in-memory state.

Each storage request includes a unique reference. The caller waits for a reply containing that reference, so a response can be matched to the corresponding request. The storage API provides default timeouts of 5,000 milliseconds and also exposes Erlang functions that accept an explicit timeout; the HTTP API uses the default timeout.

## Limitations and possible improvements

- **No OTP supervision for the storage process:** the storage process is started directly. Unexpected termination is not automatically recovered, and its state is not restored.
- **Plain-text response format:** the `GET` response uses `key=...` and `value=...` rather than JSON. Values containing newlines can make this format ambiguous.
- **Request body handling:** the `PUT` handler currently assumes that `cowboy_req:read_body/1` returns `{ok, Body, Req}`. Alternative outcomes are not explicitly handled.
- **No explicit application-level body size limit:** the application does not define its own maximum request-body size.
- **Text values:** request bodies are converted to Erlang character lists; the API does not define a contract for arbitrary binary data.
- **No automated HTTP integration tests:** HTTP behaviour has been checked manually, while the automated tests focus on the map and storage process.