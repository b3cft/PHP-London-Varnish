<?php
$ttl = 60;
$expires = gmdate('D, j M Y H:i:s T', time() + $ttl);
header("Expires: $expires");
header("Cache-Control: max-age=$ttl, must-revalidate");
$requestHeaders  = print_r(apache_request_headers(), true);
$responseHeaders = print_r(apache_response_headers(), true);
?>
<pre>
Request Headers: <?php echo $requestHeaders; ?>
Response Headers: <?php echo $responseHeaders; ?>
</pre>