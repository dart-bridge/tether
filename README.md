# Tether
_Bi-directional messaging abstraction_

---

### Abstract
Dart is a multi purpose language. It can run in a web browser, on servers, even on mobile phones
and micro processors! But if we want to communicate between these devices and processes we're still
forced to conform to common data transfer protocols.

Tether is a project that originated as the flagship feature of the
[Bridge Framework](https://github.com/dart-bridge/framework), but is now available as a standalone
package for anyone to use.

### Use Cases
The Tether system defines its own JSON based protocol, so it doesn't play very nice with others.
Both sides of the communication must use the Tether (or at least implement the protocol).

Tether really shines when the different devices or processes share the same codebase. It can
register functions to break down and rebuild data structures, but both sides must have the
same functions registered for that to work.

Platforms where Tether can be used include:

* WebSockets
* Isolates
* Shared memory
* Or any other bi-directional packet exchange system you can think of!

### Connection
The Tethers connect using _Anchors_, which are implementations of the different transport platforms.
For the Tether connection session to be established, one side must be considered a `master`, and the
other a `slave`. This is only important during the handshake process, where one party must be the one
dictating what session identifier to assign to the tethers. For a server/client set up, the server
must be the `master` to be able to handle multiple sessions.

> An `Anchor` is a _pending_ connection to _another_ `Anchor`.

At a high level, it's easy to create a tether from an anchor:

```dart
// On "master" side
final tether = new Tether.masterAnchor(anchor);

// On "slave" side
final tether = new Tether.slaveAnchor(anchor);
```

You can also easily create tethers from predefined anchor implementations via constructors like this:

```dart
main() {
  final tether = new Tether.spawnIsolate(isolate);
}

isolate(_) {
  final tether = new Tether.connectIsolate(_);
}
```

Each Tether can be disconnected and reconnected multiple times; note these methods of reacting to
changes in the connection:

```dart
// Whether or not the Tether is connected RIGHT NOW. This does
// not ensure connection here on out.
tether.isConnected;

// A future to wait for the NEXT TIME the connection is established.
// If the connection is already established, this future
// will complete immediately.
tether.onConnection;

// A stream that will send a ping every time a connection has
// been established. Note that this is a broadcast stream, and
// that you should use [onConnection] for the first connection.
tether.onConnectionEstablished;

// The same as [onConnectionEstablished] but for when the connection
// is lost.
tether.onConnectionLost;
```

### Usage
When two tethers has been connected to each other we can start sending data through. We do this by
listening for, and sending to, different keys:

```dart
// Side A
tether.listen('someKey', (String message) {
  print(message);
});

// Side B
tether.send('someKey', 'My message!'); // prints "My message!" on side A
```

We can send and receive maps and lists without any configuration:

```dart
// Side A
tether.listen('someKey', (List<String> messages) {
  messages.forEach(print);
});

// Side B
tether.send('someKey', ['a', 'b', 'c']);
```

Both sides can listen and send:

```dart
// Side A
tether.listen('a', print);
tether.send('b', 'from a');

// Side B
tether.listen('b', print);
tether.send('a', 'from b');
```

### Full example
```dart
import 'package:tether/tether.dart';

main() async {
  final tether = new Tether.spawnIsolate(slave);

  handler([_]) {
    tether.listen('greet', (String name) {
      return "Heeeeere's $name!";
    });
  }

  handler(await tether.onConnection);
  tether.onConnectionEstablished.listen(handler);
}

slave(ports) async {
  final tether = new Tether.connectIsolate(ports);

  handler([_]) async {
    print(await tether.send('greet', 'Johnny'));

    tether.close();
  }

  handler(await tether.onConnection);
  tether.onConnectionEstablished.listen(handler);
}
```


