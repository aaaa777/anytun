const socksv5 = require('socksv5');
const http = require('http');
const { Transform } = require('stream');

class SOCKS5OverHTTP {
  constructor(httpProxyUrl, options = {}) {
    this.httpProxyUrl = new URL(httpProxyUrl);
    this.socksOptions = {
      proxy: {
        ipaddress: options.proxyHost || '127.0.0.1',
        port: options.proxyPort || 1080,
        type: 5
      },
      authentication: options.auth ? {
        username: options.auth.username,
        password: options.auth.password
      } : null
    };
  }

  createServer() {
    return new Promise((resolve, reject) => {
      const server = socksv5.createServer((info, accept, deny) => {
        const httpOptions = {
          method: 'POST',
          hostname: this.httpProxyUrl.hostname,
          port: this.httpProxyUrl.port,
          path: this.httpProxyUrl.pathname,
          headers: {
            'Content-Type': 'application/octet-stream',
            'Connection': 'keep-alive',
            'Transfer-Encoding': 'chunked',
            'X-Target-Host': info.dstAddr,
            'X-Target-Port': info.dstPort.toString()
          }
        };

        const req = http.request(httpOptions, (res) => {
          if (res.statusCode !== 200) {
            deny();
            return;
          }

          const stream = accept(true);
          if (stream) {
            // Transform stream for data handling
            const transform = new Transform({
              transform(chunk, encoding, callback) {
                this.push(chunk);
                callback();
              }
            });

            res.pipe(transform).pipe(stream);
            stream.pipe(req);
          }
        });

        req.on('error', (err) => {
          console.error('HTTP Proxy Error:', err);
          deny();
        });
      });

      server.useAuth(socksv5.auth.None());

      server.listen(this.socksOptions.proxy.port, this.socksOptions.proxy.ipaddress, () => {
        console.log(`SOCKS5 server listening on ${this.socksOptions.proxy.ipaddress}:${this.socksOptions.proxy.port}`);
        resolve(server);
      });

      server.on('error', (err) => {
        reject(err);
      });
    });
  }

  async start() {
    try {
      const server = await this.createServer();
      return server;
    } catch (err) {
      console.error('Failed to start SOCKS5 server:', err);
      throw err;
    }
  }

  static createClient(options) {
    return new Promise((resolve, reject) => {
      const client = socksv5.connect({
        host: options.targetHost,
        port: options.targetPort,
        proxy: {
          ipaddress: options.socksHost || '127.0.0.1',
          port: options.socksPort || 1080,
          type: 5
        }
      }, (socket) => {
        resolve(socket);
      });

      client.on('error', (err) => {
        reject(err);
      });
    });
  }
}

// Example usage:
async function main() {
  try {
    // Create and start SOCKS5 server that tunnels through HTTP
    const proxy = new SOCKS5OverHTTP('http://127.0.0.1:8080', {
      proxyHost: '127.0.0.1',
      proxyPort: 1080
    });
    
    await proxy.start();

    // Create SOCKS5 client connection
    const socket = await SOCKS5OverHTTP.createClient({
      // targetHost: '172.207.80.203',
      targetHost: '127.0.0.1',
      targetPort: 8080,
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

module.exports = SOCKS5OverHTTP;

main();