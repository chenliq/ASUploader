/**
 * ASUploader: http://ASUploader.googlecode.com
 * 
 * @copyright (c) 2011 
 * @author Joseph Chen
 * @release MIT License:
 * @link http://www.opensource.org/licenses/mit-license.php
 */
function ASUploader(setting) {
	this.setting	= setting;
	this.movieId	= 0;
	this.swfObject	= false;
	
	//init setting
	this.init = function() {
		// flash settings
		this.movieName			= 'ASUploader_' + this.movieId;
		this.placeHolderId		= 'ASUploaderPlaceHolder';
		this.flashUrl			= 'ASUploader.swf';
		this.swfVersionStr		= '10.0.0';
		//this.xiSwfUrlStr		= 'playerProductInstall.swf';
		// flash display
		this.lableText			= 'Please Select Files';
		this.buttonTextStyle	= 'display:block;text-align:left;color: #000000;font-size: 20px;';
		this.width				= 100;
		this.height				= 30;
		this.textTopPadding		= 0;
		this.textLeftPadding	= 0;
		// upload server settings
		this.uploadUrl			= 'upload.php';
		this.queryString		= '';
		this.postParams			= '';
		// file settings
		this.fileTypesDesc		= 'All Files';//Image
		this.fileTypes			= '*.*';//*.png;*.jpg;*.gif
		this.fileSizeLimit		= 0;// zero means 'unlimited'
		this.fileUploadLimit	= 0;
		this.fileQueueLimit		= 0;
		this.multiFiles			= true;
		this.autoUpload			= true;
		
		//Event Handlers
		this.fileSelectStartHandler = null;
		this.fileSelectCompleteHandler = null;
		this.uploadCompleteHandler = 'completeCallback';
		
		for (var name in setting) {
			if (this.setting[name] != undefined) {
				this[name] = this.setting[name];
			} else if (this[name] == undefined) {
				continue;
			}
		}
		
		// 要在setting初始化后设置下面的参
		this.postParams	= this.buildParams(setting.postParams);
		this.flashParams = {
			quality	: 'high',
			bgcolor	: '#ffffff',
			allowscriptaccess	: 'always',
			allowfullscreen		: 'true'
		};
		this.flashAttributes = {
			id		: this.movieName,
			name	: this.movieName,
			align	: 'middle'
		}
		return this;
	};
	// 获取传递给swf的参数
	this.getFlashVars = function() {
		return flashvars = {
			movieName		: this.movieName,
			swfVersionStr	: this.swfVersionStr,
			lableText		: this.lableText,
			width			: this.width,
			height			: this.height,
			textTopPadding	: this.textTopPadding,
			textLeftPadding	: this.textLeftPadding,
			buttonTextStyle	: this.buttonTextStyle,
			uploadUrl		: this.uploadUrl,
			queryString		: this.queryString,
			postParams		: this.postParams,
			fileTypesDesc	: this.fileTypesDesc,
			fileTypes		: this.fileTypes,
			fileSizeLimit	: this.fileSizeLimit,
			fileUploadLimit	: this.fileUploadLimit,
			fileSizeLimit	: this.fileSizeLimit,
			fileQueueLimit	: this.fileQueueLimit,
			multiFiles		: this.multiFiles,
			autoUpload		: this.autoUpload,
			
			uploadCompleteHandler	: this.uploadCompleteHandler
		};
	};
	
	this.getFlashVarsString = function() {
		flashvars = this.getFlashVars();
		var string = '';
		for (var key in flashvars) {
			if (string == '') {
				string += key+'='+encodeURIComponent(flashvars[key].toString());
			} else {
				string += '&amp;' +key+ '=' + encodeURIComponent(flashvars[key].toString());
			}
		}
		return string;
	};
	
	// 创建FLASH
	this.create = function (movieName) {
		if (movieName) {
			this.movieName = movieName;
		}
		var flashHtml = '<object align="'+this.flashAttributes.align+'" width="'+this.width+'" height="'+this.height+'"'
				+ ' id="'+this.flashAttributes.id+'" name="'+this.flashAttributes.name+'"'
				+ '  classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000">'
				+ '<param name="movie" value="'+this.flashUrl+'" />'
				+ '<param name="quality" value="'+this.flashParams.quality+'">'
				+ '<param name="bgcolor" value="'+this.flashParams.bgcolor+'">'
				+ '<param name="allowfullscreen" value="'+this.flashParams.allowfullscreen+'">'
				+ '<param name="allowscriptaccess" value="'+this.flashParams.allowscriptaccess+'">'
				+ '<param name="flashvars" value="'+this.getFlashVarsString()+'">'
				+ '	<!--[if !IE]>-->'
				+ '	<object type="application/x-shockwave-flash" data="'+this.flashUrl+'"'
				+ '	 width="'+this.width+'" height="'+this.height+'"'
				+ '	 id="'+this.flashAttributes.id+'" name="'+this.flashAttributes.name+'"'
				+ '	 style="visibility: visible;">'
				+ '	<param name="quality" value="'+this.flashParams.quality+'">'
				+ '	<param name="bgcolor" value="'+this.flashParams.bgcolor+'">'
				+ '	<param name="menu" value="false" />'
				+ '	<param name="allowfullscreen" value="'+this.flashParams.allowfullscreen+'">'
				+ '	<param name="allowscriptaccess" value="'+this.flashParams.allowscriptaccess+'">'
				+ '	<param name="flashvars" value="'+this.getFlashVarsString()+'">'
				+ '	<!--<![endif]-->\n'
				+ '	<!--[if gte IE 6]>-->\n'
				+ '	<p>Either scripts and active content are not permitted to run or Adobe Flash Player version'
				+ '	'+this.swfVersionStr+' or greater is not installed.'
				+ '	</p>\n'
				+ '	<!--<![endif]-->\n'
				+ '	<a href="http://www.adobe.com/go/getflashplayer">'
				+ '	<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif"'
				+ ' alt="Get Adobe Flash Player" /></a>\n'
				+ '	<!--[if gte IE 6]>-->\n'
				+ '	</object>\n'
				+ '	<!--<![endif]-->\n'
				+ '</object>';
		
		var targetElement, tempParent;
	
		// Make sure an element with the ID we are going to use doesn't already exist
		if (document.getElementById(this.movieName) !== null) {
			throw "ID " + this.movieName + " is already in use. The Flash Object could not be added";
		}
	
		// Get the element where we will be placing the flash movie
		targetElement = document.getElementById(this.placeHolderId);
	
		if (targetElement == undefined) {
			throw "Could not find the placeholder element: " + this.placeHolderId;
		}
	
		// Append the container and embed the flash
		tempParent = document.createElement("div");
		// Using innerHTML is non-standard but the only sensible way to dynamically add Flash in IE (and maybe other browsers)
		tempParent.innerHTML = flashHtml;
		//targetElement.parentNode.replaceChild(tempParent.firstChild, targetElement);
		targetElement.parentNode.appendChild(tempParent.firstChild);
	
		// Fix IE Flash/Form bug
		if (window[this.movieName] == undefined) {
			window[this.movieName] = this.getMovieElement();
		}
		return this;
	};
	// 组装传递给swf的额外参数(用来swf向服务器程序提交的参数
	this.buildParams = function (params) {
		var paramPairs = [];

		if (typeof(params) === 'object') {
			for (var key in params) {
				paramPairs.push(key.toString() + '=' + params[key].toString());
			}
		}

		return paramPairs.join('&'); 
	};
	// 开始上传
	this.upload = function() {
		if (!this.flash) {
			this.flash = this.getObjectById(this.movieName);
		}
		if (this.flash && this.flash.upload != undefined) {
			this.flash.upload();
		}
		return this;
	};
	// 向swf发送要提交的参数数据 
	this.sendPostDataToAs = function(data) {
		if (!this.flash) {
			this.flash = this.getObjectById(this.movieName);
		}
		if (this.flash && this.flash.sendPostDataToAs != undefined) {
			this.flash.sendPostDataToAs();
		}
		return this;
	};
	
	this.getObjectById = function(id) {
		var r = null;
		var o = document.getElementById(id);
		if (o && o.nodeName == "OBJECT") {
			if (typeof o.SetVariable != 'undefined') {
				r = o;
			}
			else {
				var n = o.getElementsByTagName('OBJECT')[0];
				if (n) {
					r = n;
				}
			}
		}
		return r;
	};
	
	this.getMovieElement = function() {
		if (this.movieElement == undefined) {
			this.movieElement = document.getElementById(this.movieName);
		}
	
		if (this.movieElement === null) {
			throw "Could not find Flash element";
		}
		
		return this.movieElement;
	};
	
	
	// init
	this.init();
};