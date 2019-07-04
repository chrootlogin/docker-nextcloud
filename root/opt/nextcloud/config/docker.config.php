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
);
