# HomePlace Link dependency

The canonical HomePlace Link roadmap and future schemas live in the HomePlace
server repository. Mobile code must not create an incompatible copy.

The first client slice expects an unauthenticated endpoint:

`GET /api/link/info`

It must return a stable server ID, a human-readable server name, and the minimum
and maximum supported protocol versions. The Android client currently accepts
protocol version 1.

The server roadmap also reserves pairing, approval, WebSocket, file transfer,
command, and device event endpoints. As of this repository foundation, those
endpoints are documented but not implemented in the checked HomePlace server.
Pairing, registration, presence, and test notification delivery therefore
remain blocked on a versioned server contract.

Test fixtures in this repository are client examples only. When the server
publishes canonical schemas, replace these examples with generated or released
protocol artifacts and contract-test both applications against them.
