<?php

header('Service-Worker-Allowed: /');
header('Content-Security-Policy: default-src * data: blob:; script-src * data: blob:; style-src * data: blob:; img-src * data: blob:; connect-src * data: blob: ws: wss:;');
header('Access-Control-Allow-Origin: *');

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';

$app->handleRequest(Request::capture());
