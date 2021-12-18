module smallredis

import net

pub struct Redis {
mut:
	socket net.TcpConn
}


pub fn (mut r Redis) cmd(message string) ?[]string {
	if message.contains('\r\n') {
		return error('command rejected: contains newline')
	}
	r.socket.write_string(message + '\r\n') ?
	return r.read_response()
}
pub fn (mut r Redis) typed_cmd<T>(message string) ?T {
	res := r.cmd(message) ?
	$if T is string {
		return res[0]
	} $else $if T is []string {
		return res
	} $else $if T is byte {
		return res[0].byte()
	} $else $if T is []byte {
		return res.map(it.byte())
	} $else $if T is u16 {
		return res[0].u16()
	} $else $if T is []u16 {
		return res.map(it.u16())
	} $else $if T is u32 {
		return res[0].u32()
	} $else $if T is []u32 {
		return res.map(it.u32())
	} $else $if T is u64 {
		return res[0].u64()
	} $else $if T is []u64 {
		return res.map(it.u64())
	} $else $if T is i8 {
		return res[0].i8()
	} $else $if T is []i8 {
		return res.map(it.i8())
	} $else $if T is i16 {
		return res[0].i16()
	} $else $if T is []i16 {
		return res.map(it.i16())
	} $else $if T is int {
		return res[0].int()
	} $else $if T is []int {
		return res.map(it.int())
	} $else $if T is i64 {
		return res[0].i64()
	} $else $if T is []i64 {
		return res.map(it.i64())
	} $else $if T is f32 {
		return res[0].f32()
	} $else $if T is []f32 {
		return res.map(it.f32())
	} $else $if T is f64 {
		return res[0].f64()
	} $else $if T is []f64 {
		return res.map(it.f64())
	}
	return error('unable to decode type')
}

fn (mut r Redis) read_response() ?[]string {
	line := r.socket.read_line()
	res := line[1..line.len - 2]
	match line[0] {
		`-` { // error
			return error(res)
		}
		`+`, `:` { // single line or int
			return [res]
		}
		`$` { // bulk response
			length := res.int()
			if length == -1 {
				return error('no results')
			}
			mut buffer := []byte{len: length + 2}
			r.socket.read(mut buffer) ?
			return [buffer[..length].bytestr()]
		}
		`*` { // multi bulk response
			length := res.int()
			if length == -1 {
				return error('no results')
			}
			mut items := []string{cap: length}
			for _ in 0 .. length {
				items << r.read_response() ?
			}
			return items
		}
		else {
			return error('redis protocol error, unexpected byte: ${line[0]}')
		}
	}
}

pub fn (mut r Redis) disconnect() {
	r.socket.close() or {}
}

[params]
pub struct ConnectSet {
	port int    = 6379
	host string = '127.0.0.1'
}

pub fn connect(settings ConnectSet) ?Redis {
	mut socket := net.dial_tcp('$settings.host:$settings.port') ?
	return Redis{socket}
}
