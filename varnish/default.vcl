import std; // Import to get access to Varnish's std library to include error file later.

probe healthcheck {
  .url = "/health.json";
  .interval = 5s;
  .timeout = 10s;
  .window = 5;
  .threshold = 3;
}

// IPs authorized to ban/purge pages
acl purge_acl {
  "localhost";
}

  backend d1 {
    .host = "localhost";
    .port = "80";
    .probe = healthcheck;
  }

  director default round-robin {
    { .backend = d1; }
  }

sub vcl_recv {
  if (req.http.Host ~ "^www\.foo\.com") {
    set req.backend = default;
  }

  set req.backend = default;

  // Pass health checks to app when given a Host header.
  // Terminate health checks in Varnish when given an IP address or no header.
  // (IPv4 addresses contain no letters. IPv6 addresses start with "[".)
  // Without this, the upstream will find Varnish unhealhty if default backend dies.
  // Error code caught and handled in vcl_error sub.
  if (req.url == "/health.json" && !(req.http.host ~ "(?i)^[a-z0-9].*?[a-z]")) {
    error 760 "OK";
  }

  // Deny purge requests if IP isn't on whitelist
  if (req.request == "PURGE") {
    if (client.ip !~ purge_acl) {
      error 405 "Not allowed.";
      return(lookup);
    } else {
      if (req.http.X-Purge-Fmt) {
        ban("req.http.host == " + req.http.host + " && req.url ~ " + req.http.X-Purge-Fmt);
        error 200 "Ban added.";
      }
    }
  }

  // Handle stale content based on backend health
  if (req.backend.healthy) {
    // Serve slightly-stale content while updating.
    set req.grace = 30m;
  } else {
    // Allow stale content if backend server is slow or down.
    set req.grace = 6h;
  }

  // Handle compression correctly to get more cache hits.
  if (req.http.Accept-Encoding) {
    if (req.http.Accept-Encoding ~ "gzip") {
      // If the browser supports it, we'll use gzip.
      set req.http.Accept-Encoding = "gzip";
    } else {
      // Unknown algorithm. Remove it and send unencoded.
      unset req.http.Accept-Encoding;
    }
  }

  // URL Routing

  // Deny requests for /_raindrops
  if (req.url ~ "^/_raindrops$") {
    error 404 "Not found";
  }

  // Host Routing

  if (req.http.host ~ "(?:^|\.)foo\.com(?:$|:|\.)") {
      set req.backend = default;
  }
}

sub vcl_hash {
}

sub vcl_hit {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

sub vcl_miss {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

sub vcl_error {
  unset obj.http.Server;

  // Catch 760 error code thrown by vcl_recv when healthcheck is requestsed without a host header
  if (obj.status == 760) {
    set obj.status = 200;
    synthetic {"{"alive":true}"};
    return (deliver);
  }

  // Serve a custom error page from varnish if the backend is throwing 500 errors
  if (obj.status >= 500 && obj.status <= 505) {
    if (!(req.http.host ~ "(?:^|\.)starwars\.com(?:$|:|\.)")) {
      set obj.http.Content-Type = "text/html; charset=utf-8";
      synthetic std.fileread("/etc/varnish/500.html");
      return(deliver);
    }
  }
}

sub vcl_fetch {
  // Keep stale response for six hours in case backend fails.
  set beresp.grace = 6h;

  // If something is wrong, ease off backend on this URL.
  if (beresp.status >= 500) {
    set beresp.ttl = 1m;
  }

  if (beresp.http.content-type ~ "text/javascript|text/css") {
    set beresp.ttl = 10s;
  }

  // Remember the name of the backend that handled the request.
  set beresp.http.X-Backend = beresp.backend.name;
}

sub vcl_deliver {
  // Return the name of the backend and varnish node that handled the request.
  set resp.http.X-Served-By = server.hostname;
  set resp.http.X-Director = req.backend;

  // Return HIT or MISS for varnish cache key
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
    set resp.http.X-Cache-Hits = obj.hits;
  } else {
    set resp.http.X-Cache = "MISS";
  }

  return (deliver);
}
