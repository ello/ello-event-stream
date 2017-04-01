<img src="http://d324imu86q1bqn.cloudfront.net/uploads/user/avatar/641/large_Ello.1000x1000.png" width="200px" height="200px" />

# Ello.EventStream (WIP)

Library for reading and writing to the Ello event stream.

Ello uses the AWS Kinesis service to publish events for multiple services to
consume. Events are published as Apach Avro serialized OCF files.

This library is a common library that can be used by our Elixir applications
to both publish to and read from the event stream.

## Usage

Add as a dependency (and ensure started if < Elixir 1.4):

```elixir
{:ello_event_stream, github: "ello/ello-event-stream"},
```

### Reading/Consuming an event stream

By default no consumers are started. Starting the Reader will start a
supervision tree for the given stream name in the `:ello_event_stream` app.

Each shard will be processed serially and passed to the consumer function.

The consumer function is passed in as a `{Module, :function}` tuple and must
be a function which receives a single argument which is an
`%Ello.EventStream.Event{}`. The consumer function should return `:ok` if
the event was successfully processed or skipped, otherwise the shard will stop
processing events.

The consumer may choose to spawn more processes to handle each event if desired.

```elixir
Ello.EventStream.read("stream-name", {MyApp, :process}, opts)
```



## License
Released under the [MIT License](/LICENSE.txt)

## Code of Conduct
Ello was created by idealists who believe that the essential nature of all
human beings is to be kind, considerate, helpful, intelligent, responsible, and
respectful of others. To that end, we will be enforcing
[the Ello rules](https://ello.co/wtf/policies/rules/) within all of our open
source projects. If you don’t follow the rules, you risk being ignored, banned,
or reported for abuse.
