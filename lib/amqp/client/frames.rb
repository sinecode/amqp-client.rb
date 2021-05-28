# frozen_string_literal: true

module AMQP
  # Generate binary data for different frames
  # Each frame type implemented as a method
  # Having a class for each frame type is more expensive in terms of CPU and memory
  module FrameBytes
    module_function

    def connection_start_ok(response)
      [
        1, # type: method
        0, # channel id
        4 + 4 + 6 + 4 + response.bytesize + 1, # frame size
        10, # class id
        11, # method id
        0, # client props
        5, "PLAIN", # mechanism
        response.bytesize, response,
        0, "", # locale
        206 # frame end
      ].pack("C S> L> S> S> L> Ca* L>a* Ca* C")
    end

    def connection_tune_ok(channel_max, frame_max, heartbeat)
      [
        1, # type: method
        0, # channel id
        12, # frame size
        10, # class: connection
        31, # method: tune-ok
        channel_max,
        frame_max,
        heartbeat,
        206 # frame end
      ].pack("CS>L>S>S>S>L>S>C")
    end

    def connection_open(vhost)
      [
        1, # type: method
        0, # channel id
        2 + 2 + 1 + vhost.bytesize + 1 + 1, # frame_size
        10, # class: connection
        40, # method: open
        vhost.bytesize, vhost,
        0, # reserved1
        0, # reserved2
        206 # frame end
      ].pack("C S> L> S> S> Ca* CCC")
    end

    def connection_close(code, reason)
      frame_size = 2 + 2 + 2 + 1 + reason.bytesize + 2 + 2
      [
        1, # type: method
        0, # channel id
        frame_size, # frame size
        10, # class: connection
        50, # method: close
        code,
        reason.bytesize, reason,
        0, # error class id
        0, # error method id
        206 # frame end
      ].pack("C S> L> S> S> S> Ca* S> S> C")
    end

    def connection_close_ok
      [
        1, # type: method
        0, # channel id
        4, # frame size
        10, # class: connection
        51, # method: close-ok
        206 # frame end
      ].pack("C S> L> S> S> C")
    end

    def channel_open(id)
      [
        1, # type: method
        id, # channel id
        5, # frame size
        20, # class: channel
        10, # method: open
        0, # reserved1
        206 # frame end
      ].pack("C S> L> S> S> C C")
    end

    def channel_close(id, reason, code)
      frame_size = 2 + 2 + 2 + 1 + reason.bytesize + 2 + 2
      [
        1, # type: method
        id, # channel id
        frame_size, # frame size
        20, # class: channel
        40, # method: close
        code,
        reason.bytesize, reason,
        0, # error class id
        0, # error method id
        206 # frame end
      ].pack("C S> L> S> S> S> Ca* S> S> C")
    end

    def queue_declare(id, name, passive, durable, exclusive, auto_delete)
      no_wait = false
      bits = 0
      bits |= (1 << 0) if passive
      bits |= (1 << 1) if durable
      bits |= (1 << 2) if exclusive
      bits |= (1 << 3) if auto_delete
      bits |= (1 << 4) if no_wait
      frame_size = 2 + 2 + 2 + 1 + name.bytesize + 1 + 4
      [
        1, # type: method
        id, # channel id
        frame_size, # frame size
        50, # class: queue
        10, # method: declare
        0, # reserved1
        name.bytesize, name,
        bits,
        0, # arguments
        206 # frame end
      ].pack("C S> L> S> S> S> Ca* C L> C")
    end

    def basic_get(id, queue_name, no_ack)
      frame_size = 2 + 2 + 2 + 1 + queue_name.bytesize + 2 + 2
      [
        1, # type: method
        id, # channel id
        frame_size, # frame size
        60, # class: basic
        70, # method: get
        0, # reserved1
        queue_name.bytesize, queue_name,
        no_ack ? 1 : 0,
        206 # frame end
      ].pack("C S> L> S> S> S> Ca* C C")
    end

    def basic_publish(id, exchange, routing_key)
      frame_size = 2 + 2 + 2 + 1 + exchange.bytesize + 1 + routing_key.bytesize + 1
      [
        1, # type: method
        id, # channel id
        frame_size, # frame size
        60, # class: basic
        40, # method: publish
        0, # reserved1
        exchange.bytesize, exchange,
        routing_key.bytesize, routing_key,
        0, # bits, mandatory/immediate
        206 # frame end
      ].pack("C S> L> S> S> S> Ca* Ca* C C")
    end

    def header(id, body_size, properties)
      frame_size = 2 + 2 + 8 + 2
      [
        2, # type: header
        id, # channel id
        frame_size, # frame size
        60, # class: basic
        0, # weight
        body_size,
        0, # properties
        206 # frame end
      ].pack("C S> L> S> S> Q> S> C")
    end

    def body(id, body_part)
      [
        3, # type: body
        id, # channel id
        body_part.bytesize, # frame size
        body_part,
        206 # frame end
      ].pack("C S> L> a* C")
    end
  end
end