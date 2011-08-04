/**
 *
 *
 *
 */
backend server1 {
    .host = "127.0.0.1";
    .port = "80";
    .probe = {
        .url = "/";
        .interval = 5s;
        .timeout = 1s;
        .window = 3;
        .threshold = 2;
    }
}
backend server2 {
    .host = "127.0.0.1";
    .port = "80";
    .probe = {
        .url = "/";
        .interval = 5s;
        .timeout = 1s;
        .window = 3;
        .threshold = 2;
    }
}

backend api_server {
    .host = "127.0.0.1";
    .port = "8080";
}

director server_vip random {
    .retries = 2;
    { .backend = server1; .weight = 1; }
    { .backend = server2; .weight = 1; }
}

acl purge {
    "localhost";
    "192.168.192.0"/24;
}

sub vcl_recv {
    set req.backend = server_vip;

    if (req.http.host ~ "api.domain.com") {
        set req.backend = api_server;
    }
    
    if (req.http.host ~ "^(www.)?(my|your)?domain.com") {
        set req.http.host = "domain.com";
    }

    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
           error 405 "Not allowed.";
        }
        return (lookup);
    }
    
    if (req.url == "/__healthcheck.html") {
        error 200 "OK";
    }
    
    if (!req.backend.healthy) {
       set req.grace = 30s;
    } else {
       set req.grace = 5s;
    }
}

sub vcl_pipe {
    set bereq.http.Connection = "Close";
}

sub vcl_fetch {
    if (beresp.status == 500) {
        set beresp.saintmode = 10s;
        restart;
    }
    set beresp.grace = 30m;
    
    if (req.url ~ "\.(css|js|png|gif|jpg|jpeg)$") {
        unset beresp.http.set-cookie;
        set beresp.ttl = 3600s;
    }
    
    esi;
}

sub vcl_hit {
    if (req.request == "PURGE") {
        # Note that setting ttl to 0 is magical.
        # the object is zapped from cache.
        set obj.ttl = 0s;
        error 200 "Purged.";
    }
}

sub vcl_miss {
    if (req.request == "PURGE") {
        error 404 "Not in cache.";
    }
}

sub vcl_hash {
    if (req.http.cookie ~ "PAGE_LAYOUT") {
        set req.hash += regsub(req.http.cookie, ".*PAGE_LAYOUT=([^;]+).*", "\1");
    }
}

sub vcl_deliver {
    /* override server string */
    set resp.http.Server = "Apache/Mind your own business about versions";

    if (obj.hits > 0) {
        set resp.http.X-Cache-Action = "HIT";
        set resp.http.X-Cache-Hits   = obj.hits;
    } else {
        set resp.http.X-Cache-Action = "MISS";
    }
    /* 
     * Rename the Age header to X-Cache-Age to avoid
     * the age to invalidating downsteam caches 
     */
    set resp.http.X-Cache-Age = resp.http.Age;
    unset resp.http.Age;
    
    /* remove some outgoing headers */
    unset resp.http.Via;
    unset resp.http.X-Varnish;

    return (deliver);
}

sub vcl_error {
    
    if (obj.status == 200) {
        set obj.http.Content-Type  = "text/html";
        set obj.http.Cache-Control = "max-age=0";
        synthetic obj.status " " obj.response;
        return (deliver);
    }

    if (req.restarts < 2 && obj.status >= 500 && obj.status <= 599) {
        return (restart);
    } else {
        set obj.http.Cache-Control = "private, max-age=0";
        set obj.http.Content-Type  = "text/html; charset=utf-8";
        synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} obj.status " " obj.response {"</title>
  </head>
  <body>
    <h1>Error "} obj.status " " obj.response {"</h1>
    <p>"} obj.response {"</p>
  </body>
</html>
"};
        return (deliver);
    }
}
