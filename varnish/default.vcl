vcl 4.0;

import std;
import directors;

# Default backend definition. Set this to point to your content server.
backend b1 {
  .host = "127.0.0.1";
  .port = "8080";
  .first_byte_timeout = 200s;
  .probe = {
         .url = "/health.json";
         .interval = 5s;
         .timeout = 1 s;
         .window = 5;
         .threshold = 3;
         .initial = 1;
  }
}

acl purge_ip {
    "localhost";
    "127.0.0.1";
}

sub vcl_init{
    new be = directors.round_robin();
    be.add_backend(b1);
}

sub vcl_recv {
    if (req.restarts == 0) {
      if (req.http.x-forwarded-for) {
          set req.http.X-Forwarded-For =
          req.http.X-Forwarded-For + ", " + client.ip;
      } else {
          set req.http.X-Forwarded-For = client.ip;
      }
    }

    set req.backend_hint = be.backend();

    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PURGE" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    if (req.method == "PURGE") {
         if (!client.ip ~ purge_ip) {
             return(synth(403, "Not allowed"));
         }
         return (purge);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }

    # Normalize the query arguments
    set req.url = std.querysort(req.url);

    # Don't unset cookies if it's this page.
    if (req.url ~ "^/pages/test/$") {
      return (hash);
    }

    # Images
    if (req.url ~ "\.(jpe?g|png|gif|ico|tif?f|svg|pdf)$") {
        unset req.http.Cookie;
    }

    # Archives
    if (req.url ~ "\.(tar|tgz|zip|bz2)$") {
        unset req.http.Cookie;
    }

    # CSS and JS
    if (req.url ~ "\.(css|js)$") {
        unset req.http.Cookie;
    }

    return (hash);
}

sub vcl_hit {
}

sub vcl_backend_response {
    if (beresp.ttl < 120s) {
      set beresp.ttl = 120s;
      unset beresp.http.Cache-Control;
    }
}

sub vcl_deliver {
    if (req.url ~ "^/pages") {
      set resp.http.X-Debug = "Pages Content";
    }

    if (obj.hits > 0) {
      set resp.http.X-Cache = "HIT";
    } else {
      set resp.http.X-Cache = "MISS";
    }

    set resp.http.X-Cache-Hits = obj.hits;
    return (deliver);
}

sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    synthetic ("Error");
    return (deliver);
}
