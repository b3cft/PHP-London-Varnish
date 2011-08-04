<?php
$requestHeaders  = print_r(apache_request_headers(), true);
$responseHeaders = print_r(apache_response_headers(), true);
?>
<pre>
Request Headers: <?php echo $requestHeaders; ?>
Response Headers: <?php echo $responseHeaders; ?>
</pre>