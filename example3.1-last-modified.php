<?php
$lastModified = gmdate('D, j M Y H:i:00 T');
$requestHeaders  = apache_request_headers();
if ( false === empty($requestHeaders['If-Modified-Since']) &&
     $lastModified === $requestHeaders['If-Modified-Since'] )
{
    header('HTTP/1.1 304 Not Modified');
    exit();
}
/* Do your heavy lifting now */
header("Last-Modified: $lastModified");
$responseHeaders = apache_response_headers();
?>
<h2>No Max-Age set, so Varnish uses default</h2>
<pre>
Request Headers: <?php print_r($requestHeaders); ?>
Response Headers: <?php print_r($responseHeaders); ?>
</pre>