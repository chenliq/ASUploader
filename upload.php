<?php
//header('content-type:text/html;charset=utf-8');
//echo '<pre>';
header('content-type:text/plain;charset=utf-8');

// var_export($_FILES);
// echo "\n";
// $destFile = dirname(__FILE__).'/'.$_FILES[0]['name'];
// echo $destFile;
// move_uploaded_file($_FILES[0]['tmp_name'], $destFile);
file_put_contents('t.txt', var_export($_FILES,true));
exit;


if (empty($_POST['multi_merge'])) {
	
}
$maxWidth  = 0;
$maxHeight = 0;
foreach ($_FILES as $file) {
	$type = exif_imagetype($file['tmp_name']);
	if ($type == IMG_PNG) {
		$p = imagecreatefrompng($file['tmp_name']);
	} elseif ($type == IMG_GIF) {
		$p = imagecreatefromgif($file['tmp_name']);
	} elseif ($type == IMG_JPG) {
		$p = imagecreatefromjpeg($file['tmp_name']);
	}
	$maxWidth  = max(imagesx($p), $maxWidth);
	$maxHeight += imagesy($p) + 5;
}
$pic = imagecreatetruecolor($maxWidth, $maxHeight);

$startX = 0;
$startY = 0;
foreach ($_FILES as $file) {
	$type = exif_imagetype($file['tmp_name']);
	if ($type == IMG_PNG) {
		$p = imagecreatefrompng($file['tmp_name']);
	} elseif ($type == IMG_GIF) {
		$p = imagecreatefromgif($file['tmp_name']);
	} elseif ($type == IMG_JPG) {
		$p = imagecreatefromjpeg($file['tmp_name']);
	}
	$w = imagesx($p);
	$h = imagesy($p);
	$startX = floor(($maxWidth-$w)/2);
	imagecopymerge($pic, $p, $startX, $startY, 0, 0, $w, $h, 100);
	$startY += $h + 5;
}
$filename = dirname(__FILE__).'/test.jpg';
imagejpeg($pic, $filename);


//echo 'ok!!!';