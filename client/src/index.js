const socks = require('socksv5');
const { Client } = require('ssh2');
const http = require('http');
const fs = require('fs');
const net = require('net');
const { spawn } = require('child_process');
const path = require('path');

const sshConfig = {
  host: '172.207.80.203',
  port: 22,
  username: 'hp',
  // privateKey: fs.readFileSync('./.ssh/id_ed25519'),
  privateKey: Buffer.from('-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCZreORME\nWq8QQkgw+tam6fAAAAGAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAILnDzDUraB7RNvSn\n8e7ZXjiJeBBMZZvxcCGv6jIU46q+AAAAsIfJ4suKl5pUPNlwVVqaBxhofzVcvnTgPhPUvl\nJOi3xnCppSYoslnhP4rbTUlRRi0CPaS2bCnYvwu2X68fRJ9t/msNzee4em+5jg52IT5WIP\nHguB6QZxbpyVG3Do+EVD3Gix+O2cUEZe1jkyRdQNgs8O+CkZYIzDEDogbLRpgmZXPgn5gA\nBR0TS2gHdJWyWCMrJ3s4UJpOgJfnjIGBRPaxR24ube+EIv4IhiqUq5270L\n-----END OPENSSH PRIVATE KEY-----\n'),
  privateKeyString: '"-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCZreORME\nWq8QQkgw+tam6fAAAAGAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAILnDzDUraB7RNvSn\n8e7ZXjiJeBBMZZvxcCGv6jIU46q+AAAAsIfJ4suKl5pUPNlwVVqaBxhofzVcvnTgPhPUvl\nJOi3xnCppSYoslnhP4rbTUlRRi0CPaS2bCnYvwu2X68fRJ9t/msNzee4em+5jg52IT5WIP\nHguB6QZxbpyVG3Do+EVD3Gix+O2cUEZe1jkyRdQNgs8O+CkZYIzDEDogbLRpgmZXPgn5gA\nBR0TS2gHdJWyWCMrJ3s4UJpOgJfnjIGBRPaxR24ube+EIv4IhiqUq5270L\n-----END OPENSSH PRIVATE KEY-----\n"',
  passphrase: "do-johodaido-johodai",
};

const main = () => {
  child = spawn('ssh', ['-fND', 1080, '-i', path.join(__dirname, '.ssh', 'id_ed25519'), sshConfig.username + "@" + sshConfig.host]);
  setTimeout(function() {
    console.log('****secret****');
    child.stdin.write(sshConfig.passphrase);
    child.stdin.write('\n');
    child.stdin.end();
    console.log('ssh dynamic forwarding server started on port 1080');
  }, 2000);

  // pacファイル配信用サーバ
  http.createServer(async (req, res) => {
    // 設定ファイルの場所
    if(req.url === "/proxy.pac") {
      res.writeHead(200, {
        'Content-Type': 'application/x-ns-proxy-autoconfig',
        "Content-Disposition": "attachment;filename=\"abe.pac\""
      });
      res.end(`
        function FindProxyForURL(url, host)
          {
            if (dnsDomainIs(host, "` + proxyTargetDomain + `")){
              return "PROXY localhost:3003";
            } else {
              return "DIRECT";
            }
          }
      `);
      return;
    }
    res.writeHead(404, {});
    res.end('file not found');
  }).listen(3002);
  console.log('pac config server is started on port 3002')
}

main();
// test with cURL:
//   curl -i --socks5 localhost:1080 google.com
