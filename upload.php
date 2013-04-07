<?php
//header('content-type:text/html;charset=utf-8');
//echo '<pre>';
header('content-type:text/plain;charset=utf-8');

// if (empty($_POST['_PostFromASUploader_'])) {
	var_export($_FILES);
	//file_put_contents('tt.txt', var_export($_FILES,true));
	// var_export($_POST);
	echo "\n";
	$destFile = dirname(__FILE__).'/'.$_FILES[0]['name'];
	echo $destFile;
	move_uploaded_file($_FILES[0]['tmp_name'], $destFile);
	exit;
// }


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

//echo 'FILEID:';
//var_export($_FILES);
//echo "\n";
//var_export($_POST);
//echo "\n";
//
echo 'ok!!!';
//file_put_contents(dirname(__FILE__).'/tt.txt', var_export($_FILES,true)."\n".var_export($_POST,true));