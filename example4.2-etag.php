<?php
$ttl  = 10;
$etag = '"'.md5(time() - time() % $ttl).'"';
$requestHeaders  = apache_request_headers();
if ( false === empty($requestHeaders['If-None-Match']) &&
     $etag === $requestHeaders['If-None-Match'] )
{
    header('HTTP/1.1 304 Not Modified', 304);
    exit();
}
/* Do your heavy lifting now */
header("Etag: $etag");
header("Cache-Control: max-age=$ttl, must-revalidate");
$responseHeaders = apache_response_headers();
?>
<h2>Max-Age set Boyah!</h2>
<pre>
Request Headers: <?php print_r($requestHeaders); ?>
Response Headers: <?php print_r($responseHeaders); ?>
</pre>