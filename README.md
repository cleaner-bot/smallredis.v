
# Small Redis

Very basic V library for sending raw redis commands.


```v
import smallredis

fn main() {
    mut r := smallredis.connect() ? // connects to localhost by default
    res := r.typed_cmd<string>('GET "my key"') ?
    println(res)
}
```
