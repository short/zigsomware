# This web server is used for checking how Zigware works.

import argparse
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
import uvicorn

key = ""

app = FastAPI()

@app.get('/', response_class=PlainTextResponse)
async def root(id: int = 0):
    _ = id
    return key

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Start a simple web server to download an encryption key.')
    parser.add_argument('--port', type=int, default=8000, help='Port to listen on. (default: 8000)')
    parser.add_argument('--key', type=str,  required=True, help='Set a Base64-encoded encryption key to download.')
    args = parser.parse_args()

    key = args.key

    uvicorn.run(app, host="0.0.0.0", port=args.port)



# class MyHandler(http.server.SimpleHTTPRequestHandler):
#     def __init__(self, *args, key=None, **kwargs):
#         self.key = key
#         super().__init__(*args, **kwargs)

#     def do_GET(self):
#         if self.path == '/':
#             self.send_response(200)
#             self.send_header('Content-type', 'text/plain')
#             self.end_headers()

#             self.wfile.write(self.key.encode('utf-8'))
#         else:
#             super().do_GET()


# if __name__ == '__main__':
#     parser = argparse.ArgumentParser(description='Start a simple web server to download an encryption key.')
#     parser.add_argument('--port', type=int, default=8000, help='Port to listen on. (default: 8000)')
#     parser.add_argument('--key', type=str,  required=True, help='Set a Base64-encoded encryption key to download.')
#     args = parser.parse_args()

#     server_address = ('', args.port)
#     server = http.server.HTTPServer(server_address, lambda *a, **kw: MyHandler(*a, key=args.key, **kw))

#     # For HTTPS
#     # ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
#     # ctx.load_cert_chain('server.crt', keyfile='server.key')
#     # # ctx.options |= ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1
#     # server.socket = ctx.wrap_socket(server.socket)

#     print(f"Serving on https://0.0.0.0:{args.port}/")
#     try:
#         server.serve_forever()
#     except:
#         pass
#     server.server_close()
