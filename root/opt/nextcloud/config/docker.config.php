<?php
$CONFIG = array(
  'log_type' => 'errorlog',
  'datadirectory' => '/data/data',
  'tempdirectory' => '/data/tmp',
  'supportedDatabases' => array(
    'sqlite',
    'mysql',
    'pgsql'
  ),
  'memcache.local' => '\OC\Memcache\APCu',
  'apps_paths' => array(
    array(
      'path'=> '/opt/nextcloud/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    array(
      'path'=> '/data/userapps',
      'url' => '/userapps',
      'writable' => true,
    ),
  ),
  'trusted_proxies' => array(
    '172.16.0.0/12', // Docker container normally use this IP-Block
  ),
);
