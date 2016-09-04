<?php
$CONFIG = array(
  'datadirectory' => '/data/data',
  'tempdirectory' => '/data/tmp',
  'supportedDatabases' => array(
    'sqlite',
    'mysql',
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
