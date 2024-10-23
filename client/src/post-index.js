import SOCKS5OverHTTP from "./post-tunnel";
// Example usage:
async function main() {
  try {
    // Create and start SOCKS5 server that tunnels through HTTP
    const proxy = new SOCKS5OverHTTP('http://proxy-server:8080', {
      proxyHost: '127.0.0.1',
      proxyPort: 1080
    });
    
    await proxy.start();

    // Create SOCKS5 client connection
    const socket = await SOCKS5OverHTTP.createClient({
      targetHost: '172.207.80.203',
      targetPort: 80,
      socksHost: '127.0.0.1',
      socksPort: 1080
    });

    // Use the socket
    socket.write('GET / HTTP/1.1\r\nHost: example.com\r\n\r\n');
    
    socket.on('data', (data) => {
      console.log('Received:', data.toString());
    });

    socket.on('error', (err) => {
      console.error('Socket error:', err);
    });

  } catch (err) {
    console.error('Error:', err);
  }
}

await main();