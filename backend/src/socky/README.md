# Socky

App-agnostic WebSocket layer. One persistent connection per client, domain events multiplexed over named channels.

## Channel keys

A channel key is `"<namespace>:<local_key>"`, e.g. `"antrikan:chnl_9K2f"`. Socky never interprets the key. The namespace's resolver decides whether a user may subscribe; the local key's meaning is up to the owning app.

## Authorization

Each app registers a resolver at boot:

```crystal
Socky::ChannelAuthorizer.register_resolver("antrikan") do |user, local_key|
  channel = Antrikan::Channel.get_by_hashed_id(local_key)
  !!channel && Antrikan::ChannelHelper.user_can_access?(user, channel)
end
```

`register_resolver` raises on duplicate namespace. `can_access?` splits on the first `:`, dispatches to the resolver, returns `false` for unknown namespaces or malformed keys.

## Publishing

Domain code calls `Socky::Broadcaster.publish` and never touches `Socky::Hub` directly:

```crystal
Socky::Broadcaster.publish("antrikan:#{channel.hashed_id}", payload_json)
```

`publish` does a Redis `PUBLISH` to `socky:channel:<channel_key>`. Every process running `start_subscriber` receives it and hands it to `Hub.deliver_locally`, which no-ops when there are no local subscribers.

## Client contract

Handshake (JWT as subprotocol because browsers can't set `Authorization` on WS):

```js
const ws = new WebSocket("wss://api.example.com/ws", ["bearer", jwtToken]);
```

Control frames:

```js
ws.send(JSON.stringify({ type: "subscribe", payload: { channel_ids: ["antrikan:chnl_9K2f"] } }));
ws.send(JSON.stringify({ type: "unsubscribe", payload: { channel_ids: ["antrikan:chnl_9K2f"] } }));
```

On `(re)connect`, subscribe then fetch current state via REST to reconcile missed updates:

```js
ws.onopen = () => {
  ws.send(JSON.stringify({ type: "subscribe", payload: { channel_ids: myChannelIds } }));
  refetchSnapshot();
};
```

## Boot

`Broadcaster.start_subscriber` is called once per process (e.g. from `src/antrikan/app.cr`). It spawns a fiber that blocks on Redis `PSUBSCRIBE`, respawns on error with a 5s backoff. The `antrikan` resolver is registered in the same file.

## Handler chain

`Socky::Handler` sits in `Marten::Server.handlers` between `Handlers::Error` and `Handlers::Middleware` (see `src/patches/marten.cr`). Non-WS requests fall through to Marten's normal stack.

## Heartbeat

Each `Socky::Connection` pings every 30s and closes with `CloseCode::AbnormalClosure` if no pong arrives within 45s. Closing fires `on_close` which calls `Hub.disconnect`.

## Files

| File | Class | Role |
|------|-------|------|
| `handler.cr` | `Socky::Handler` | `/ws` upgrade, JWT auth, delegates to `HTTP::WebSocketHandler` |
| `connection.cr` | `Socky::Connection` | subscribe/unsubscribe frames, heartbeat, subscription bookkeeping |
| `hub.cr` | `Socky::Hub` / `Socky::Hub::Room` | in-process room-based fan-out, mutex-protected |
| `channel_authorizer.cr` | `Socky::ChannelAuthorizer` | namespace-registered resolvers, `can_access?` |
| `broadcaster.cr` | `Socky::Broadcaster` | Redis pub/sub: `publish` + `start_subscriber` |
| `app.cr` | `Socky::App` | Marten app config, requires all socky files |
