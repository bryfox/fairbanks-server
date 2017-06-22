#!/usr/bin/env python

import SimpleHTTPServer
import SocketServer
import logging

PORT = 8000

class UserAgentHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    def log_request(self, code='-', size='-'):
         self.log_message('"%s" <%s> %s %s', self.requestline, self.headers['User-Agent'], str(code), str(size))

Handler = UserAgentHandler
httpd = SocketServer.TCPServer(("", PORT), Handler)

httpd.serve_forever()
