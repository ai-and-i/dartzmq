part of 'zeromq.dart';

/// Pair class containing two values [first] and [second] of types [L] and [R]
class Pair<L, R> {
  /// Construct a pair of [first] and [second] value
  const Pair(this.first, this.second);

  final L first;
  final R second;

  @override
  String toString() => 'Pair[$first, $second]';
}

/// Event consisting of [event] and [value] received by monitored sockets
class SocketEvent extends Pair<ZEvent, int> {
  const SocketEvent(super.first, super.second);

  /// Received event
  ZEvent get event => first;

  /// Received event value
  int get value => second;
}

/// Events generated by sockets
enum ZEvent {
  /// An unknown event was received
  UNKNOWN,

  /// An error occured while processing the event
  ERROR,

  /// The socket has successfully connected to a remote peer.
  /// The event value is the file descriptor (FD) of the underlying network socket.
  /// Warning: there is no guarantee that the FD is still valid by the time your code receives this event.
  CONNECTED,

  /// A connect request on the socket is pending.
  /// The event value is unspecified.
  CONNECT_DELAYED,

  /// A connect request failed, and is now being retried.
  /// The event value is the reconnect interval in milliseconds.
  /// Note that the reconnect interval is recalculated at each retry.
  CONNECT_RETRIED,

  /// The socket was successfully bound to a network interface.
  /// The event value is the FD of the underlying network socket.
  /// Warning: there is no guarantee that the FD is still valid by the time your code receives this event.
  LISTENING,

  /// The socket could not bind to a given interface.
  /// The event value is the errno generated by the system bind call.
  BIND_FAILED,

  /// The socket has accepted a connection from a remote peer.
  /// The event value is the FD of the underlying network socket.
  /// Warning: there is no guarantee that the FD is still valid by the time your code receives this event.
  ACCEPTED,

  /// The socket has rejected a connection from a remote peer.
  /// The event value is the errno generated by the accept call.
  ACCEPT_FAILED,

  /// The socket was closed.
  /// The event value is the FD of the (now closed) network socket.
  CLOSED,

  /// The socket close failed.
  /// The event value is the errno returned by the system call.
  /// Note that this event occurs only on IPC transports.
  CLOSE_FAILED,

  /// The socket was disconnected unexpectedly.
  /// The event value is the FD of the underlying network socket.
  /// Warning: this socket will be closed.
  DISCONNECTED,

  /// Monitoring on this socket ended.
  MONITOR_STOPPED,

  /// Unspecified error during handshake.
  /// The event value is an errno.
  HANDSHAKE_FAILED_NO_DETAIL,

  /// The ZMTP security mechanism handshake succeeded.
  /// The event value is unspecified.
  HANDSHAKE_SUCCEEDED,

  /// The ZMTP security mechanism handshake failed due to some mechanism protocol error,
  /// either between the ZMTP mechanism peers, or between the mechanism server and the ZAP handler.
  /// This indicates a configuration or implementation error in either peer resp. the ZAP handler.
  /// The event value is one of the ZMQ_PROTOCOL_ERROR_* values:
  /// ZMQ_PROTOCOL_ERROR_ZMTP_UNSPECIFIED
  /// ZMQ_PROTOCOL_ERROR_ZMTP_UNEXPECTED_COMMAND
  /// ZMQ_PROTOCOL_ERROR_ZMTP_INVALID_SEQUENCE
  /// ZMQ_PROTOCOL_ERROR_ZMTP_KEY_EXCHANGE
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_UNSPECIFIED
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_MESSAGE
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_HELLO
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_INITIATE
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_ERROR
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_READY
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_WELCOME
  /// ZMQ_PROTOCOL_ERROR_ZMTP_INVALID_METADATA
  /// ZMQ_PROTOCOL_ERROR_ZMTP_CRYPTOGRAPHIC
  /// ZMQ_PROTOCOL_ERROR_ZMTP_MECHANISM_MISMATCH
  /// ZMQ_PROTOCOL_ERROR_ZAP_UNSPECIFIED
  /// ZMQ_PROTOCOL_ERROR_ZAP_MALFORMED_REPLY
  /// ZMQ_PROTOCOL_ERROR_ZAP_BAD_REQUEST_ID
  /// ZMQ_PROTOCOL_ERROR_ZAP_BAD_VERSION
  /// ZMQ_PROTOCOL_ERROR_ZAP_INVALID_STATUS_CODE
  /// ZMQ_PROTOCOL_ERROR_ZAP_INVALID_METADATA
  HANDSHAKE_FAILED_PROTOCOL,

  /// The ZMTP security mechanism handshake failed due to an authentication failure.
  /// The event value is the status code returned by the ZAP handler (i.e. 300, 400 or 500).
  HANDSHAKE_FAILED_AUTH
}

/// Extension on [ZEvent] to add some convenience functions
extension ZEventConversion on ZEvent {
  /// Convert the given [value] to a [ZEvent]
  static ZEvent fromValue(final int value) {
    switch (value) {
      case ZMQ_EVENT_CONNECTED:
        return ZEvent.CONNECTED;
      case ZMQ_EVENT_CONNECT_DELAYED:
        return ZEvent.CONNECT_DELAYED;
      case ZMQ_EVENT_CONNECT_RETRIED:
        return ZEvent.CONNECT_RETRIED;
      case ZMQ_EVENT_LISTENING:
        return ZEvent.LISTENING;
      case ZMQ_EVENT_BIND_FAILED:
        return ZEvent.BIND_FAILED;
      case ZMQ_EVENT_ACCEPTED:
        return ZEvent.ACCEPTED;
      case ZMQ_EVENT_ACCEPT_FAILED:
        return ZEvent.ACCEPT_FAILED;
      case ZMQ_EVENT_CLOSED:
        return ZEvent.CLOSED;
      case ZMQ_EVENT_CLOSE_FAILED:
        return ZEvent.CLOSE_FAILED;
      case ZMQ_EVENT_DISCONNECTED:
        return ZEvent.DISCONNECTED;
      case ZMQ_EVENT_MONITOR_STOPPED:
        return ZEvent.MONITOR_STOPPED;
      case ZMQ_EVENT_HANDSHAKE_FAILED_NO_DETAIL:
        return ZEvent.HANDSHAKE_FAILED_NO_DETAIL;
      case ZMQ_EVENT_HANDSHAKE_SUCCEEDED:
        return ZEvent.HANDSHAKE_SUCCEEDED;
      case ZMQ_EVENT_HANDSHAKE_FAILED_PROTOCOL:
        return ZEvent.HANDSHAKE_FAILED_PROTOCOL;
      case ZMQ_EVENT_HANDSHAKE_FAILED_AUTH:
        return ZEvent.HANDSHAKE_FAILED_AUTH;

      default:
        log('Received unknown socket event $value, if this issue persists please open an issue on the dartzmq github',
            name: 'dartzmq');
        return ZEvent.UNKNOWN;
    }
  }
}

/// Monitors socket state
class ZMonitor {
  /// Socket monitoring this socket
  late final ZSocket _monitor;

  /// Stream of received [ZEvent]s
  late final Stream<SocketEvent> events;

  /// Construct a new [ZMonitor] with a given underlying ZMQSocket [socket],
  /// the global ZContext [context] and the given [event]s to monitor
  ///
  /// Events that can be monitored include:
  /// * [ZMQ_EVENT_CONNECTED]
  /// * [ZMQ_EVENT_CONNECT_DELAYED]
  /// * [ZMQ_EVENT_CONNECT_RETRIED]
  /// * [ZMQ_EVENT_LISTENING]
  /// * [ZMQ_EVENT_BIND_FAILED]
  /// * [ZMQ_EVENT_ACCEPTED]
  /// * [ZMQ_EVENT_ACCEPT_FAILED]
  /// * [ZMQ_EVENT_CLOSED]
  /// * [ZMQ_EVENT_CLOSE_FAILED]
  /// * [ZMQ_EVENT_DISCONNECTED]
  /// * [ZMQ_EVENT_MONITOR_STOPPED]
  ///
  /// To monitor specific events:
  /// ```dart
  /// final ZMonitor monitor = ZMonitor(
  ///  context: context,
  ///  socket: socket,
  ///  event: ZMQ_EVENT_CONNECTED | ZMQ_EVENT_CLOSED, // Only listen for connected and closed events
  /// );
  /// ```
  ///
  /// To monitor all events:
  /// ```dart
  /// final ZMonitor monitor = ZMonitor(
  ///  context: context,
  ///  socket: socket,
  /// );
  /// ```
  ZMonitor(
      {required final ZContext context,
      required final ZSocket socket,
      final int event = ZMQ_EVENT_ALL}) {
    final address = 'inproc://monitor${socket.hashCode}';

    final endpointPointer = address.toNativeUtf8();
    final code =
        _bindings.zmq_socket_monitor(socket._socket, endpointPointer, event);
    malloc.free(endpointPointer);
    _checkReturnCode(code);

    _monitor = context.createSocket(SocketType.pair);
    _monitor.connect(address);

    events = _monitor.messages.map((messages) {
      if (messages.length != 2) {
        return SocketEvent(ZEvent.ERROR, 0);
      }

      final ZEvent event = ZEventConversion.fromValue(
          messages.first.payload[0] | messages.first.payload[1] << 8);
      final int value = messages.first.payload[2] |
          messages.first.payload[3] << 8 |
          messages.first.payload[4] << 16 |
          messages.first.payload[5] << 24;
      return SocketEvent(event, value);
    });
  }

  /// Close the monitor and free resources
  void close() {
    _monitor.close();
  }
}
